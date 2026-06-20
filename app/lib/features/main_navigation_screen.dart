import 'package:app/recording/audio_recording_screen.dart';
import 'package:flutter/material.dart';
import 'history/history_screen.dart';
import 'plan/plan_screen.dart';
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
          const HistoryScreen(),
          const PlanScreen(),
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
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.card_membership_outlined),
            selectedIcon: Icon(Icons.card_membership),
            label: 'Plan',
          ),
        ],
      ),
    );
  }
}
