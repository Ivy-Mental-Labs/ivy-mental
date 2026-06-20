import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'core/ml/services/text_analyzer.dart';
import 'core/ml/services/onnx_text_analyzer.dart';
import 'features/audio_recording/audio_recording_screen.dart';
import 'features/evaluation/evaluation_screen.dart';
import 'features/history/history_screen.dart';
import 'data/repositories/session_repository.dart';
import 'data/notifiers/session_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SessionRepository.init();
  final analyzer = OnnxTextAnalyzer();
  await analyzer.load();
  runApp(MainApp(analyzer: analyzer));
}

class MainApp extends StatelessWidget {
  final TextAnalyzer analyzer;

  const MainApp({required this.analyzer, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionNotifier(SessionRepository()),
      child: MaterialApp(
        theme: appTheme,
        initialRoute: AudioRecordingScreen.routeName,
        routes: {
          AudioRecordingScreen.routeName: (_) => const AudioRecordingScreen(),
          EvaluationScreen.routeName: (_) =>
              EvaluationScreen(analyzer: analyzer),
          HistoryScreen.routeName: (_) => const HistoryScreen(),
        },
      ),
    );
  }
}
