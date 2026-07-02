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

class _AudioRecordingScreenState extends State<AudioRecordingScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  final WhisperController _whisperController = WhisperController();

  bool _isTranscribing = false;
  bool _isModelLoaded = false;
  String _transcriptionText = 'Tell me about your day';
  bool _showTranscriptionText = true;

  late VideoPlayerController _videoController;
  StreamSubscription<Amplitude>? _amplitudeSub;
  double _audioScale = 1.0;

  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  late Stopwatch _recordingStopwatch;
  Timer? _recordingTimer;
  String _recordingDuration = '0:00';

  @override
  void initState() {
    super.initState();
    _initModel();
    _recordingStopwatch = Stopwatch();

    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
    _breathingController.repeat(reverse: true);

    _videoController =
        VideoPlayerController.asset('assets/media/magic_bubble_v1.mp4')
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
      final assetBundle = DefaultAssetBundle.of(context);
      final modelPath = await _whisperController.getPath(WhisperModel.tiny);
      final file = File(modelPath);

      if (!file.existsSync() || file.lengthSync() < 50000000) {
        debugPrint('Model not found natively, copying from assets...');
        final byteData = await assetBundle.load('assets/models/ggml-tiny.bin');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
          flush: true,
        );
        debugPrint('Model successfully copied to $modelPath');
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
    _recordingTimer?.cancel();
    _recordingStopwatch.stop();
    _videoController.dispose();
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

        _recordingStopwatch.start();
        _recordingTimer = Timer.periodic(const Duration(milliseconds: 100), (
          timer,
        ) {
          if (mounted) {
            final seconds = _recordingStopwatch.elapsed.inSeconds;
            final minutes = seconds ~/ 60;
            final secs = seconds % 60;
            setState(() {
              _recordingDuration =
                  '$minutes:${secs.toString().padLeft(2, '0')}';
            });
          }
        });

        _amplitudeSub = _audioRecorder
            .onAmplitudeChanged(const Duration(milliseconds: 100))
            .listen((amp) {
              if (mounted) {
                final double normalized =
                    (amp.current.clamp(-40.0, 0.0) + 40.0) / 40.0;
                setState(() {
                  _audioScale = 1.0 + (normalized * 0.4);
                });
              }
            });

        setState(() {
          _isRecording = true;
          _showTranscriptionText = true;
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
    final notifier = context.read<SessionNotifier>();

    try {
      final path = await _audioRecorder.stop();
      _amplitudeSub?.cancel();
      _recordingTimer?.cancel();
      _recordingStopwatch.stop();
      _recordingStopwatch.reset();

      setState(() {
        _isRecording = false;
        _isTranscribing = true;
        _showTranscriptionText = true;
        _transcriptionText = 'Saving your check-in...';
        _audioScale = 1.0;
        _recordingDuration = '0:00';
      });

      if (path != null) {
        final audioFile = File(path);
        if (audioFile.existsSync() && audioFile.lengthSync() > 0) {
          debugPrint(
            'Audio file exists, size: ${audioFile.lengthSync()} bytes',
          );

          final placeholderSession = Session(
            id: DateTime.now().toIso8601String(),
            createdAt: DateTime.now(),
          );
          await notifier.upsert(placeholderSession);

          if (mounted) {
            await Future.delayed(const Duration(milliseconds: 1000));
            _openOverview(initialPage: 0);
            setState(() {
              _isTranscribing = false;
              _showTranscriptionText = false;
            });
          }

          _processRecordingInBackground(path, placeholderSession);
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

  Future<bool> _analyzeAndSave(String sessionId, String text) async {
    final notifier = context.read<SessionNotifier>();
    try {
      final analysisResult = await widget.analyzer.analyze(text);
      await notifier.updateEvaluation(sessionId, {
        'mood': analysisResult.mood,
        'emotions': analysisResult.emotions,
      });
      return true;
    } catch (e) {
      debugPrint('Analysis error: $e');
      return false;
    }
  }

  Future<void> _processRecordingInBackground(
    String path,
    Session session,
  ) async {
    final audioFile = File(path);
    final notifier = context.read<SessionNotifier>();

    try {
      final result = await _whisperController.transcribe(
        model: WhisperModel.tiny,
        audioPath: path,
        lang: 'en',
      );

      final transcriptText = result?.transcription.text.trim();
      if (transcriptText != null && transcriptText.isNotEmpty) {
        await notifier.updateTranscript(session.id, transcriptText);
        await _analyzeAndSave(session.id, transcriptText);
      } else {
        await notifier.updateTranscript(session.id, 'No speech detected.');
      }
    } catch (e) {
      debugPrint('Background transcribe error: $e');
    } finally {
      try {
        if (audioFile.existsSync()) {
          audioFile.deleteSync();
        }
      } catch (_) {}
    }
  }

  void _toggleRecording() {
    if (_isRecording) {
      _stopRecording();
    } else {
      _startRecording();
    }
  }

  void _openOverview({int initialPage = 0}) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 450),
        reverseTransitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) {
          return OverviewPagerScreen(initialPage: initialPage);
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
            return Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
              child: Column(
                children: [
                  IvyHeader(
                    showSettings: false,
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

                  const Spacer(flex: 3),

                  if (_showTranscriptionText)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _transcriptionText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w200,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),

                  const Spacer(flex: 2),

                  GestureDetector(
                    onTap: _toggleRecording,
                    child: AnimatedBuilder(
                      animation: _breathingAnimation,
                      builder: (context, child) {
                        final currentScale = _isRecording
                            ? _audioScale
                            : _breathingAnimation.value;
                        return AnimatedScale(
                          scale: currentScale,
                          duration: _isRecording
                              ? const Duration(milliseconds: 150)
                              : Duration.zero,
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: _videoController.value.isInitialized
                                  ? SizedBox.expand(
                                      child: FittedBox(
                                        fit: BoxFit.cover,
                                        child: SizedBox(
                                          width:
                                              _videoController.value.size.width,
                                          height: _videoController
                                              .value
                                              .size
                                              .height,
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
                                      Colors.red.withValues(alpha: 0.6),
                                      Colors.red.withValues(alpha: 0.2),
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
                  ),

                  Spacer(flex: 3),

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
                            color: Colors.grey.withValues(alpha: 0.2),
                            blurRadius: 3,
                            spreadRadius: 1,
                            offset: const Offset(0, 1.5),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.1),
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
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.4),
                                  size: 30,
                                ),
                        ),
                      ),
                    ),
                  ),

                  if (_isRecording)
                    Padding(
                      padding: const EdgeInsets.only(top: 25.0),
                      child: Text(
                        _recordingDuration,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: colors.textMuted,
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 20),
                  Spacer(flex: 1),

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
