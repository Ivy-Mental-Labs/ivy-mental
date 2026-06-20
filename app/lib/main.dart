import 'package:flutter/material.dart';
import 'theme.dart';
import 'features/audio_recording/audio_recording_screen.dart';
import 'features/evaluation/evaluation_screen.dart';
import 'features/history/history_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      initialRoute: AudioRecordingScreen.routeName,
      routes: {
        AudioRecordingScreen.routeName: (_) => const AudioRecordingScreen(),
        EvaluationScreen.routeName: (_) => const EvaluationScreen(),
        HistoryScreen.routeName: (_) => const HistoryScreen(),
      },
    );
  }
}
