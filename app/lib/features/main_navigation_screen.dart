import 'package:app/recording/audio_recording_screen.dart';
import 'package:flutter/material.dart';
import 'evaluation/evaluation_screen.dart';
import 'history/history_screen.dart';
import '../core/ml/services/text_analyzer.dart';

class MainNavigationScreen extends StatefulWidget {
  final TextAnalyzer analyzer;

  const MainNavigationScreen({required this.analyzer, super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AudioRecordingScreen(analyzer: widget.analyzer),
          EvaluationScreen(analyzer: widget.analyzer),
          const HistoryScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.mic),
            selectedIcon: Icon(Icons.mic),
            label: 'Record',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: 'Evaluation',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
