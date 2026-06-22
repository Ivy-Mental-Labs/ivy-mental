import 'package:app/recording/audio_recording_screen.dart';
import 'package:flutter/material.dart';
import 'history/history_screen.dart';
import '../core/ml/services/text_analyzer.dart';

class MainNavigationScreen extends StatelessWidget {
  final TextAnalyzer analyzer;

  const MainNavigationScreen({required this.analyzer, super.key});

  @override
  Widget build(BuildContext context) {
    return AudioRecordingScreen(analyzer: analyzer);
  }
}
