import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/session.dart';
import '../../data/notifiers/session_notifier.dart';
import '../../shared/widgets/ivy_visuals.dart';
import '../../theme.dart';

class EvaluationScreen extends StatelessWidget {
  const EvaluationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sessions = context.watch<SessionNotifier>().sessions;
    final score = _overallScore(sessions);
    final calm = _emotionScore(sessions, 'satisfied', fallback: 72);
    final energy = _emotionScore(sessions, 'happy', fallback: 61);
    final stress = _emotionScore(sessions, 'anxious', fallback: 34);

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MetricItem(label: 'Calm', value: calm, color: colors.accentDeep),
                  MetricItem(label: 'Energy', value: energy, color: colors.accentMint),
                  MetricItem(label: 'Stress', value: stress, color: colors.accentPeach),
                ],
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

  int _emotionScore(List<Session> sessions, String key, {required int fallback}) {
    final values = <double>[];
    for (final session in sessions) {
      final emotions = session.evaluation?['emotions'];
      if (emotions is Map && emotions[key] is num) {
        values.add((emotions[key] as num).toDouble());
      }
    }
    if (values.isEmpty) return fallback;
    final average = values.reduce((a, b) => a + b) / math.max(values.length, 1);
    return (average * 100).clamp(0, 100).round();
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
