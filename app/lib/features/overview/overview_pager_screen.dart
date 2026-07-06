import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/ivy_visuals.dart';
import '../../theme.dart';
import '../../data/notifiers/session_notifier.dart';
import '../../data/models/session.dart';
import '../history/history_screen.dart';
import 'evaluation_screen.dart';

class OverviewPagerScreen extends StatefulWidget {
  final int initialPage;

  const OverviewPagerScreen({this.initialPage = 0, super.key});

  @override
  State<OverviewPagerScreen> createState() => _OverviewPagerScreenState();
}

class _OverviewPagerScreenState extends State<OverviewPagerScreen> {
  late final PageController _pageController;
  late int _currentPage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sessions = context.watch<SessionNotifier>().sessions;
    // compute dominant emotion across sessions (average per emotion)
    const emotionKeys = ['happy', 'sad', 'satisfied', 'proud', 'anxious', 'angry', 'afraid', 'jealous'];
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (final k in emotionKeys) {
      sums[k] = 0.0;
      counts[k] = 0;
    }
    for (final s in sessions) {
      final emotions = s.evaluation?['emotions'];
      if (emotions is Map) {
        for (final k in emotionKeys) {
          final v = emotions[k];
          if (v is num) {
            sums[k] = (sums[k] ?? 0) + v.toDouble();
            counts[k] = (counts[k] ?? 0) + 1;
          }
        }
      }
    }
    String? dominantEmotion;
    double best = -1.0;
    for (final k in emotionKeys) {
      final c = counts[k] ?? 0;
      if (c == 0) continue;
      final avg = (sums[k] ?? 0) / c;
      if (avg > best) {
        best = avg;
        dominantEmotion = k;
      }
    }
    final isPending = sessions.any((s) => s.status == SessionStatus.transcribing);
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Column(
            children: [
              IvyHeader(
                trailing: _OverviewOrbButton(
                  onTap: () => Navigator.of(context).pop(),
                  emotion: dominantEmotion,
                  isPending: isPending,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (page) => setState(() => _currentPage = page),
                        children: const [EvaluationScreen(), HistoryScreen()],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Column(
                        children: [
                          PageIndicator(currentIndex: _currentPage),
                          const SizedBox(height: AppSpacing.lg),
                          const PrivacyHint(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverviewOrbButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? emotion;
  final bool isPending;

  const _OverviewOrbButton({required this.onTap, this.emotion, this.isPending = false});

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isPending) {
      // show default proud bubble (bubble_04.png) with lower opacity while transcribing
      child = Opacity(opacity: 0.6, child: EmotionBubble(emotion: 'proud', size: 45));
    } else if (emotion != null) {
      child = EmotionBubble(emotion: emotion!, size: 45);
    } else {
      child = Opacity(opacity: 0.6, child: EmotionBubble(emotion: 'proud', size: 45));
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(width: 48, height: 48, child: Center(child: child)),
    );
  }
}
