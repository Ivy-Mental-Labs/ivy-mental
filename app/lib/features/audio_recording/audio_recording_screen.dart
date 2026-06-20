import 'package:flutter/material.dart';

class AudioRecordingScreen extends StatelessWidget {
  const AudioRecordingScreen({super.key});

  static const String routeName = '/audio-recording';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('AudioRecordingScreen'),
      ),
    );
  }
}
