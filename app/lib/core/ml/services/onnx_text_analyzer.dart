import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:path_provider/path_provider.dart';

import '../../ml/models/analysis_result.dart';
import '../services/text_analyzer.dart';
import '../services/tokenizer.dart';

class OnnxTextAnalyzer implements TextAnalyzer {
  static const String _modelAssetPath = 'assets/ml/model.onnx';
  static const String _modelDataAssetPath = 'assets/ml/model.onnx.data';
  static const String _vocabAssetPath = 'assets/ml/vocab.txt';

  static const List<String> _emotionLabels = [
    'happy',
    'sad',
    'satisfied',
    'proud',
    'anxious',
    'angry',
    'afraid',
    'jealous',
  ];

  static const int _seqLength = 128;
  static const int _numEmotions = 8;

  late final OrtSession _session;
  late final BertTokenizer _tokenizer;

  @override
  Future<void> load() async {
    final modelFile = await _copyModelAssetsToFileSystem();
    final options = OrtSessionOptions()..appendCPUProvider(CPUFlags.useNone);
    _session = OrtSession.fromFile(modelFile, options);

    final vocabContent = await rootBundle.loadString(_vocabAssetPath);
    _tokenizer = BertTokenizer(maxLength: _seqLength);
    _tokenizer.loadFromString(vocabContent);
  }

  Future<File> _copyModelAssetsToFileSystem() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final modelDir = Directory(
      '${appSupportDir.path}${Platform.pathSeparator}ml',
    );
    if (!await modelDir.exists()) {
      await modelDir.create(recursive: true);
    }

    final modelFile = File(
      '${modelDir.path}${Platform.pathSeparator}model.onnx',
    );
    final modelDataFile = File(
      '${modelDir.path}${Platform.pathSeparator}model.onnx.data',
    );

    await _copyAssetIfNeeded(_modelAssetPath, modelFile);
    await _copyAssetIfNeeded(_modelDataAssetPath, modelDataFile);

    return modelFile;
  }

  Future<void> _copyAssetIfNeeded(String assetPath, File outputFile) async {
    final assetData = await rootBundle.load(assetPath);
    if (await outputFile.exists() &&
        await outputFile.length() == assetData.lengthInBytes) {
      return;
    }

    final bytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );
    await outputFile.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<AnalysisResult> analyze(String text) async {
    final tokenized = _tokenizer.tokenize(text);

    final inputIds = OrtValueTensor.createTensorWithDataList(
      [tokenized.inputIds],
      [1, _seqLength],
    );
    final attentionMask = OrtValueTensor.createTensorWithDataList(
      [tokenized.attentionMask],
      [1, _seqLength],
    );

    final inputs = <String, OrtValue>{
      'input_ids': inputIds,
      'attention_mask': attentionMask,
    };

    final outputs = _session.run(OrtRunOptions(), inputs, ['mood', 'emotions']);

    final moodTensor = outputs[0] as OrtValueTensor;
    final emotionsTensor = outputs[1] as OrtValueTensor;

    final moodData = moodTensor.value as List;
    final mood = (moodData[0] as List)[0] as num;

    final emotionData = emotionsTensor.value as List;
    final rawEmotions = (emotionData[0] as List).cast<num>();

    final emotions = <String, double>{};
    for (var i = 0; i < _numEmotions; i++) {
      emotions[_emotionLabels[i]] = _sigmoid(rawEmotions[i].toDouble());
    }

    return AnalysisResult(mood: mood.toDouble(), emotions: emotions);
  }

  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x));

  @override
  void dispose() {
    _session.release();
  }
}
