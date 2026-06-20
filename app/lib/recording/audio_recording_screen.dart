import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:whisper_ggml_plus/whisper_ggml_plus.dart';
import 'package:video_player/video_player.dart';
import '../core/ml/services/text_analyzer.dart';
import '../data/models/session.dart';
import '../data/notifiers/score_reminder_notifier.dart';
import '../data/notifiers/session_notifier.dart';
import '../features/score_reminder/score_reminder_settings_screen.dart';
import '../features/overview/overview_pager_screen.dart';
import '../shared/widgets/ivy_visuals.dart';
import '../theme.dart';

class AudioRecordingScreen extends StatefulWidget {
  final TextAnalyzer analyzer;

  const AudioRecordingScreen({required this.analyzer, super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WhisperController _whisperController = WhisperController();

  bool _isTranscribing = false;
  bool _isModelLoaded = false;
  String _transcriptionText = 'Tell me about your day';

  late VideoPlayerController _videoController;
  StreamSubscription<Amplitude>? _amplitudeSub;
  double _audioScale = 1.0;

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _initModel();

    _breathingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _breathingAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut));
    _breathingController.repeat(reverse: true);

    _videoController = VideoPlayerController.asset('assets/media/magic_bubble_v1.mp4')
      ..setLooping(true)
      ..initialize().then((_) {
        if (mounted) {
          setState(() {});
          _videoController.play();
        }
      });
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
    _breathingController.dispose();
    _amplitudeSub?.cancel();
    _videoController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (!_isModelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Model is still loading...')));
      return;
    }

    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/temp_record.wav';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
          path: path,
        );

        _amplitudeSub = _audioRecorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
          if (mounted) {
            // Map amplitude from -40..0 to scale 1.0..1.4
            final double normalized = (amp.current.clamp(-40.0, 0.0) + 40.0) / 40.0;
            setState(() {
              _audioScale = 1.0 + (normalized * 0.4);
            });
          }
        });

        setState(() {
          _isRecording = true;
          _transcriptionText = 'Listening...';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission denied')));
        }
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _amplitudeSub?.cancel();

      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _transcriptionText = 'Transcribing...';
        _audioScale = 1.0;
      });

      if (path != null) {
        final audioFile = File(path);
        if (audioFile.existsSync() && audioFile.lengthSync() > 0) {
          debugPrint('Audio file exists, size: ${audioFile.lengthSync()} bytes');

          try {
            final result = await _whisperController.transcribe(
              model: WhisperModel.tiny,
              audioPath: path,
              lang: 'en', // Explicit language prevents auto-detect crashes
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
              _videoController.play();
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
        evaluation: {'mood': analysisResult.mood, 'emotions': analysisResult.emotions},
      );
      if (mounted) {
        await notifier.upsert(session);
        messenger.showSnackBar(const SnackBar(content: Text('Entry saved')));

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
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(curved),
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
                      icon: Icon(Icons.arrow_forward, size: 20, color: colors.accentDeep),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const ScoreReminderSettingsScreen())),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Theme.of(context).primaryColor),
                      child: const Icon(Icons.settings, color: Colors.white, size: 18),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Subtitle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _transcriptionText,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 23, fontWeight: FontWeight.w200, color: colors.textPrimary),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Magic Sphere Video with Audio-Reactive and Breathing Scale
                  AnimatedBuilder(
                    animation: _breathingAnimation,
                    builder: (context, child) {
                      final currentScale = _isRecording ? _audioScale : _breathingAnimation.value;
                      return AnimatedScale(
                        scale: currentScale,
                        duration: _isRecording ? const Duration(milliseconds: 150) : Duration.zero,
                        curve: Curves.easeOutQuad,
                        child: child,
                      );
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: ClipOval(
                            child: _videoController.value.isInitialized
                                ? SizedBox.expand(
                                    child: FittedBox(
                                      fit: BoxFit.cover,
                                      child: SizedBox(
                                        width: _videoController.value.size.width,
                                        height: _videoController.value.size.height,
                                        child: VideoPlayer(_videoController),
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ),
                        AnimatedOpacity(
                          opacity: _isTranscribing ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 5000),
                          child: IgnorePointer(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.red.withOpacity(0.6),
                                    Colors.red.withOpacity(0.2),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.2, 0.6, 0.9],
                                ),
                              ),
                            ),
                          ),
                        ),
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
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 3,
                            spreadRadius: 1,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) {
                            return ScaleTransition(scale: animation, child: child);
                          },
                          child: _isTranscribing
                              ? SizedBox(
                                  key: const ValueKey('loading'),
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator(
                                    color: Theme.of(context).colorScheme.primary,
                                    strokeWidth: 2,
                                  ),
                                )
                              : _isRecording
                              ? Container(
                                  key: const ValueKey('stop'),
                                  width: 21,
                                  height: 21,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                )
                              : Icon(
                                  Icons.mic_none,
                                  key: const ValueKey('mic'),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
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
                      const PrivacyHint(),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                  ),
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

  const _RecordButton({required this.isRecording, required this.isTranscribing, required this.onPressed});

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
            BoxShadow(color: colors.shadowSoft, blurRadius: isRecording ? 30 : 18, offset: const Offset(0, 10)),
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
                    child: CircularProgressIndicator(color: colors.accentMint, strokeWidth: 2),
                  )
                : isRecording
                ? Container(
                    key: const ValueKey('stop'),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(color: colors.accentPeach, borderRadius: BorderRadius.circular(5)),
                  )
                : Icon(Icons.mic_none, key: const ValueKey('mic'), color: colors.textSecondary, size: 28),
          ),
        ),
      ),
    );
  }
}
