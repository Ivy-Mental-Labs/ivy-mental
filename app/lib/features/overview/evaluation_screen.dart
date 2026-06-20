import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/session.dart';
import '../../data/notifiers/session_notifier.dart';
import '../../shared/widgets/ivy_visuals.dart';
import '../../theme.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  List<Session>? _lastSessions;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _restartAnimationIfNeeded(List<Session> sessions) {
    if (!identical(_lastSessions, sessions)) {
      _lastSessions = sessions;
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sessions = context.watch<SessionNotifier>().sessions;
    _restartAnimationIfNeeded(sessions);
    final score = _overallScore(sessions);
    final topEmotions = _topEmotionScores(sessions);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 690;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Column(
            children: [
              IvyHeader(trailing: _OverviewOrbButton(onTap: () => Navigator.of(context).pop())),
              SizedBox(height: compact ? 38 : 60),
              Text(
                "Your week's evaluation",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w200,
                ),
              ),
              SizedBox(height: compact ? 18 : 28),
              ScoreOrb(score: score),
              const SizedBox(height: AppSpacing.md),
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (index) {
                      final emotion = topEmotions[index];
                      final animatedValue = (emotion.value * _animation.value).round();
                      final color = [colors.accentDeep, colors.accentMint, colors.accentPeach][index];
                      return MetricItem(label: emotion.key, value: animatedValue, color: color);
                    }),
                  );
                },
              ),
              SizedBox(height: compact ? 24 : 50),
              MoodTrendCard(sessions: sessions),
            ],
          ),
        );
      },
    );
  }

  int _overallScore(List<Session> sessions) {
    final moods = sessions
        .map((session) => session.evaluation?['mood'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();
    if (moods.isEmpty) return 58;
    final average = moods.reduce((a, b) => a + b) / moods.length;
    return (((average + 1) / 2) * 100).clamp(0, 100).round();
  }

  List<MapEntry<String, int>> _topEmotionScores(List<Session> sessions) {
    final totals = <String, double>{};
    final counts = <String, int>{};

    for (final session in sessions) {
      final emotions = session.evaluation?['emotions'];
      if (emotions is Map) {
        for (final entry in emotions.entries) {
          final label = entry.key.toString();
          final value = entry.value;
          if (value is num) {
            totals[label] = (totals[label] ?? 0.0) + value.toDouble();
            counts[label] = (counts[label] ?? 0) + 1;
          }
        }
      }
    }

    final averages = totals.entries.map((entry) {
      final count = counts[entry.key] ?? 1;
      return MapEntry(entry.key, (entry.value / count).clamp(0.0, 1.0));
    }).toList();

    if (averages.isEmpty) {
      return const [MapEntry('Satisfied', 72), MapEntry('Happy', 61), MapEntry('Anxious', 34)];
    }

    averages.sort((a, b) => b.value.compareTo(a.value));
    final top = averages.take(3).map((entry) {
      return MapEntry(_titleCase(entry.key), (entry.value * 100).round());
    }).toList();

    while (top.length < 3) {
      final fallback = ['Satisfied', 'Happy', 'Anxious'][top.length];
      final values = {'Satisfied': 72, 'Happy': 61, 'Anxious': 34};
      top.add(MapEntry(fallback, values[fallback]!));
    }

    return top;
  }

  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}

class _OverviewOrbButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OverviewOrbButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Center(child: MoodOrb(size: 45, variant: MoodOrbVariant.deep)),
      ),
    );
  }
}
