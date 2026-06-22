import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../data/models/session.dart';
import '../../data/notifiers/session_notifier.dart';
import '../../shared/widgets/ivy_visuals.dart';
import '../../theme.dart';

class EvaluationScreen extends StatefulWidget {
  const EvaluationScreen({super.key});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/media/sentiment_animation.mp4')
          ..setLooping(true)
          ..initialize().then((_) {
            if (mounted) {
              setState(() {});
              _videoController.play();
            }
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sessions = context.watch<SessionNotifier>().sessions;
    final score = _overallScore(sessions);
    final calm = _emotionScore(sessions, 'satisfied');
    final energy = _emotionScore(sessions, 'happy');
    final stress = _emotionScore(sessions, 'anxious');

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 690;
        return Padding(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
          child: Column(
            children: [
              IvyHeader(
                trailing: _OverviewOrbButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
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
              SizedBox(
                width: 214,
                height: 214,
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.7, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ClipOval(
                        child: SizedBox(
                          width: 214,
                          height: 200,
                          child: _videoController.value.isInitialized
                              ? FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width: _videoController.value.size.width,
                                    height: _videoController.value.size.height,
                                    child: VideoPlayer(_videoController),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ),

                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const RadialGradient(
                          center: Alignment.center,
                          radius: 0.5,
                          colors: [Colors.white, Colors.transparent],
                          stops: [0.6, 1.0],
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.dstIn,
                      child: ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 10),
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.backgroundPrimary.withOpacity(0.75),
                            ),
                          ),
                        ),
                      ),
                    ),

                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (score == null)
                          Text(
                            '--',
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: colors.textPrimary,
                                  fontSize: 38,
                                  fontWeight: FontWeight.w300,
                                  height: 1,
                                ),
                          )
                        else
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 5000),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(
                              begin: 0.0,
                              end: score.toDouble(),
                            ),
                            builder: (context, value, child) {
                              return Text(
                                '${value.round()}',
                                style: Theme.of(context).textTheme.displaySmall
                                    ?.copyWith(
                                      color: colors.textPrimary,
                                      fontSize: 38,
                                      fontWeight: FontWeight.w300,
                                      height: 1,
                                    ),
                              );
                            },
                          ),
                        const SizedBox(height: 7),
                        Text(
                          'Overall',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MetricItem(
                    label: 'Calm',
                    value: calm != null ? '$calm' : '--',
                    color: colors.accentDeep,
                  ),
                  MetricItem(
                    label: 'Energy',
                    value: energy != null ? '$energy' : '--',
                    color: colors.accentMint,
                  ),
                  MetricItem(
                    label: 'Stress',
                    value: stress != null ? '$stress' : '--',
                    color: colors.accentPeach,
                  ),
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

  int? _overallScore(List<Session> sessions) {
    final moods = sessions
        .map((session) => session.evaluation?['mood'])
        .whereType<num>()
        .map((value) => value.toDouble())
        .toList();
    if (moods.isEmpty) return null;
    final average = moods.reduce((a, b) => a + b) / moods.length;
    return (((average + 1) / 2) * 100).clamp(0, 100).round();
  }

  int? _emotionScore(
    List<Session> sessions,
    String key,
  ) {
    final values = <double>[];
    for (final session in sessions) {
      final emotions = session.evaluation?['emotions'];
      if (emotions is Map && emotions[key] is num) {
        values.add((emotions[key] as num).toDouble());
      }
    }
    if (values.isEmpty) return null;
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
