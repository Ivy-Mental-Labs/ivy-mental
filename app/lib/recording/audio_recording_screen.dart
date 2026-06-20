import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
import '../core/ml/services/text_analyzer.dart';
import '../data/models/session.dart';
import '../data/notifiers/score_reminder_notifier.dart';
import '../data/notifiers/session_notifier.dart';
import '../features/score_reminder/score_reminder_settings_screen.dart';

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
          debugPrint('Audio file exists, size: ${audioFile.lengthSync()} bytes');
          
          try {
            final result = await _whisperController.transcribe(
              model: WhisperModel.tiny,
              audioPath: path,
              lang: 'de', // Explicit language prevents auto-detect crashes
              // threads: 4, // Maximize CPU usage for faster transcription
            );

            if (mounted) {
              setState(() {
                _isTranscribing = false;
                if (result?.transcription.text != null && result!.transcription.text.trim().isNotEmpty) {
                  _transcriptionText = result.transcription.text;
                } else {
                  _transcriptionText = 'No speech detected.';
                }
              });
              if (result?.transcription.text != null && result!.transcription.text.trim().isNotEmpty) {
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
            // Delete the temporary file safely
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
    final reminderNotifier = context.read<ScoreReminderNotifier>();
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
        messenger.showSnackBar(
          const SnackBar(content: Text('Entry saved')),
        );

        final overallScore = ((analysisResult.mood + 1) / 2 * 100).clamp(0.0, 100.0);
        if (reminderNotifier.isActive && overallScore < reminderNotifier.threshold) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Your score (${overallScore.round()}) dropped below ${reminderNotifier.threshold} — check your evaluation.',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Analysis error: $e');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'IvyMental',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w200,
                      color: colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ScoreReminderSettingsScreen(),
                      ),
                    ),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary,
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  _transcriptionText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w200,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // Magic Sphere Placeholder
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.surface,
                      colorScheme.secondary,
                      colorScheme.primary,
                    ],
                    stops: const [0.1, 0.6, 1.0],
                    center: const Alignment(-0.2, -0.3),
                    radius: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.9),
                      blurRadius: 40,
                      offset: const Offset(0, -20),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Subtle inner glow
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.6),
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                    ),
                    // Adding a few placeholder stars/dots like in the design
                    Positioned(top: 40, left: 60, child: _buildStar(3)),
                    Positioned(top: 80, right: 50, child: _buildStar(2)),
                    Positioned(bottom: 60, left: 80, child: _buildStar(4)),
                    Positioned(bottom: 90, right: 70, child: _buildStar(2)),
                  ],
                ),
              ),

              Spacer(flex: 3),

              // Record Button
              GestureDetector(
                onTap: _toggleRecording,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 3,
                        spreadRadius: 1,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return ScaleTransition(
                              scale: animation,
                              child: child,
                            );
                          },
                      child: _isTranscribing
                          ? SizedBox(
                              key: const ValueKey('loading'),
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                color: colorScheme.primary,
                                strokeWidth: 2,
                              ),
                            )
                          : _isRecording
                              ? Container(
                                  key: const ValueKey('stop'),
                                  width: 21,
                                  height: 21,
                                  decoration: BoxDecoration(
                                    color: colorScheme.error,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                )
                              : Icon(
                                  Icons.mic_none,
                                  key: const ValueKey('mic'),
                                  color: colorScheme.onSurface.withOpacity(0.4),
                                  size: 30,
                                ),
                    ),
                  ),
                ),
              ),

              Spacer(flex: 1),

              // Bottom text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.3),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Processed locally on your Phone',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.3),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.white,
            blurRadius: size * 2,
            spreadRadius: size,
          ),
        ],
      ),
    );
  }
}
