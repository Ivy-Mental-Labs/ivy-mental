import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
// ignore: unused_import
import 'package:flutter_sound/flutter_sound.dart';

class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  bool _isRecording = false;
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await Permission.microphone.request().isGranted) {
        final directory = await getApplicationDocumentsDirectory();
        final path =
            '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() {
          _isRecording = true;
          _recordedFilePath = null;
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
        _recordedFilePath = path;
      });
      debugPrint('Recording saved to: $path');
    } catch (e) {
      debugPrint('Error stopping record: $e');
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
                  Icon(
                    Icons.arrow_forward,
                    color: colorScheme.onSurface,
                    size: 22,
                  ),
                ],
              ),

              const Spacer(flex: 3),

              // Subtitle
              Text(
                'Tell me about your day',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w200,
                  color: colorScheme.onSurface.withOpacity(0.8),
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
                      child: _isRecording
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
