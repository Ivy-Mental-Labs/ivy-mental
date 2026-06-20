import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';

import '../core/ml/services/text_analyzer.dart';
import '../data/models/session.dart';
import '../data/notifiers/session_notifier.dart';
import '../features/overview/overview_pager_screen.dart';
import '../shared/widgets/ivy_visuals.dart';
import '../theme.dart';

class AudioRecordingScreen extends StatefulWidget {
  final TextAnalyzer analyzer;

  const AudioRecordingScreen({required this.analyzer, super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WhisperController _whisperController = WhisperController();

  bool _isTranscribing = false;
  bool _isModelLoaded = false;
  String _transcriptionText = 'Tell me about your day';

  @override
  void initState() {
    super.initState();
    _initModel();
  }

  Future<void> _initModel() async {
    try {
      final modelPath = await _whisperController.getPath(WhisperModel.tiny);
      final file = File(modelPath);

      if (!file.existsSync() || file.lengthSync() < 1000000) {
        debugPrint('Model not found natively, downloading...');
        await _whisperController.downloadModel(WhisperModel.tiny);
      } else {
        debugPrint('Model already exists at: $modelPath');
      }

      if (mounted) {
        setState(() {
          _isModelLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading model: $e');
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Model is still loading...')),
      );
      return;
    }

    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/temp_record.wav';

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );
        setState(() {
          _isRecording = true;
          _transcriptionText = 'Listening...';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _transcriptionText = 'Transcribing...';
      });

      if (path != null) {
        final audioFile = File(path);
        if (audioFile.existsSync() && audioFile.lengthSync() > 0) {
          debugPrint(
            'Audio file exists, size: ${audioFile.lengthSync()} bytes',
          );

          try {
            final result = await _whisperController.transcribe(
              model: WhisperModel.tiny,
              audioPath: path,
              lang: 'de',
            );

            if (mounted) {
              setState(() {
                _isTranscribing = false;
                if (result?.transcription.text != null &&
                    result!.transcription.text.trim().isNotEmpty) {
                  _transcriptionText = result.transcription.text;
                } else {
                  _transcriptionText = 'No speech detected.';
                }
              });
              if (result?.transcription.text != null &&
                  result!.transcription.text.trim().isNotEmpty) {
                await _analyzeAndSave(result.transcription.text);
              }
            }
          } catch (e) {
            debugPrint('Transcribe error: $e');
            if (mounted) {
              setState(() {
                _isTranscribing = false;
                _transcriptionText = 'Error during transcription.';
              });
            }
          } finally {
            try {
              if (audioFile.existsSync()) {
                audioFile.deleteSync();
              }
            } catch (_) {}
          }
        } else {
          if (mounted) {
            setState(() {
              _isTranscribing = false;
              _transcriptionText = 'Error: Audio file is empty.';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping record: $e');
      setState(() {
        _isTranscribing = false;
      });
    }
  }

  Future<void> _analyzeAndSave(String text) async {
    final notifier = context.read<SessionNotifier>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final analysisResult = await widget.analyzer.analyze(text);
      final session = Session(
        id: DateTime.now().toIso8601String(),
        createdAt: DateTime.now(),
        transcript: text,
        evaluation: {
          'mood': analysisResult.mood,
          'emotions': analysisResult.emotions,
        },
      );
      if (mounted) {
        await notifier.upsert(session);
        messenger.showSnackBar(const SnackBar(content: Text('Entry saved')));
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Analysis failed: $e')));
      }
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _openOverview() {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const OverviewPagerScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeOutCubic,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 690;
            final orbSize = compact ? 188.0 : 218.0;
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                children: [
                  IvyHeader(
                    trailing: IconButton(
                      onPressed: _openOverview,
                      splashRadius: 22,
                      icon: Icon(
                        Icons.arrow_forward,
                        size: 20,
                        color: colors.accentDeep,
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      _transcriptionText,
                      key: ValueKey(_transcriptionText),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 18,
                        fontWeight: FontWeight.w200,
                        height: 1.35,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 34 : 58),
                  MoodOrb(size: orbSize),
                  const Spacer(flex: 3),
                  _RecordButton(
                    isRecording: _isRecording,
                    isTranscribing: _isTranscribing,
                    onPressed: _toggleRecording,
                  ),
                  const Spacer(),
                  const PrivacyHint(),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RecordButton extends StatelessWidget {
  final bool isRecording;
  final bool isTranscribing;
  final VoidCallback onPressed;

  const _RecordButton({
    required this.isRecording,
    required this.isTranscribing,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: colors.backgroundGlass,
          shape: BoxShape.circle,
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: colors.shadowSoft,
              blurRadius: isRecording ? 30 : 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: isTranscribing
                ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: colors.accentMint,
                      strokeWidth: 2,
                    ),
                  )
                : isRecording
                ? Container(
                    key: const ValueKey('stop'),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colors.accentPeach,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  )
                : Icon(
                    Icons.mic_none,
                    key: const ValueKey('mic'),
                    color: colors.textSecondary,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}
