import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme.dart';
import '../../data/models/session.dart';
import '../../features/score_reminder/score_reminder_settings_screen.dart';
import '../../features/overview/longterm_screen.dart';
import '../../data/notifiers/settings_notifier.dart';
import '../../core/localization/app_translations.dart';

class IvyHeader extends StatelessWidget {
  final Widget trailing;
  final bool showSettings;
  const IvyHeader({required this.trailing, this.showSettings = true, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'IvyMental',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w200,
            letterSpacing: 0.1,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSettings)
              IconButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ScoreReminderSettingsScreen()));
                },
                splashRadius: 22,
                icon: Icon(Icons.settings, size: 20, color: colors.textMuted),
              ),
            trailing,
          ],
        ),
      ],
    );
  }
}

class PrivacyHint extends StatelessWidget {
  const PrivacyHint({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = context.watch<SettingsNotifier>();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 13, color: colors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Text(
          AppTranslations.get('on_device_analysis', settings.appLanguage),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w300,
          ),
        ),
      ],
    );
  }
}

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int count;

  const PageIndicator({required this.currentIndex, this.count = 2, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final active = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          width: active ? 43 : 10,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? colors.accentMint : colors.textMuted,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        );
      }),
    );
  }
}

class MoodOrb extends StatelessWidget {
  final double size;
  final MoodOrbVariant variant;

  const MoodOrb({this.size = 190, this.variant = MoodOrbVariant.deep, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.82,
            height: size * 0.82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: colors.shadowSoft, blurRadius: size * 0.24, offset: Offset(0, size * 0.14)),
                BoxShadow(color: colors.glowLight, blurRadius: size * 0.18, offset: Offset(0, -size * 0.08)),
              ],
            ),
          ),
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: CustomPaint(
                size: Size.square(size),
                painter: MoodOrbPainter(colors: colors, variant: variant),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmotionBubble extends StatelessWidget {
  final String emotion;
  final double size;

  const EmotionBubble({required this.emotion, this.size = 42, super.key});

  String get _assetPath => 'assets/media/bubbles/${_bubbleAssetName(emotion)}';

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(child: Image.asset(_assetPath, fit: BoxFit.cover)),
    );
  }
}

enum MoodOrbVariant { deep, mint, peach }

class MoodOrbPainter extends CustomPainter {
  final AppThemeColors colors;
  final MoodOrbVariant variant;

  MoodOrbPainter({required this.colors, required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.42;
    final base = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.9,
        colors: _gradientColors(),
        stops: const [0, 0.42, 0.72, 1],
      ).createShader(rect);

    canvas.drawCircle(center, radius, base);

    final haze = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.45, -0.25),
        radius: 0.65,
        colors: [colors.glowLight.withValues(alpha: 0.76), colors.glowLight.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawCircle(center, radius, haze);

    final peachPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.62, 0.18),
        radius: 0.55,
        colors: [colors.accentPeach.withValues(alpha: 0.52), colors.accentPeach.withValues(alpha: 0)],
      ).createShader(rect);
    canvas.drawCircle(center, radius * 0.95, peachPaint);

    final highlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.018
      ..strokeCap = StrokeCap.round
      ..color = colors.glowLight.withValues(alpha: 0.78);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.88),
      math.pi * 0.1,
      math.pi * 0.7,
      false,
      highlight,
    );

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.glowLight.withValues(alpha: 0.55);
    canvas.drawCircle(center, radius, rim);

    final dotPaint = Paint()..color = colors.glowLight.withValues(alpha: 0.62);
    for (final offset in const [Offset(-0.18, -0.22), Offset(0.18, -0.1), Offset(-0.02, 0.16), Offset(0.28, 0.28)]) {
      canvas.drawCircle(
        Offset(center.dx + offset.dx * size.width, center.dy + offset.dy * size.height),
        size.shortestSide * 0.006,
        dotPaint,
      );
    }
  }

  List<Color> _gradientColors() {
    switch (variant) {
      case MoodOrbVariant.mint:
        return [
          colors.glowLight.withValues(alpha: 0.92),
          colors.accentMint.withValues(alpha: 0.62),
          colors.accentDeep.withValues(alpha: 0.35),
          colors.accentPeach.withValues(alpha: 0.48),
        ];
      case MoodOrbVariant.peach:
        return [
          colors.glowLight.withValues(alpha: 0.92),
          colors.accentPeach.withValues(alpha: 0.68),
          colors.accentMint.withValues(alpha: 0.36),
          colors.accentDeep.withValues(alpha: 0.2),
        ];
      case MoodOrbVariant.deep:
        return [
          colors.glowLight.withValues(alpha: 0.86),
          colors.accentDeep.withValues(alpha: 0.78),
          colors.accentMint.withValues(alpha: 0.56),
          colors.accentPeach.withValues(alpha: 0.42),
        ];
    }
  }

  @override
  bool shouldRepaint(covariant MoodOrbPainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.variant != variant;
  }
}

String _bubbleAssetName(String emotion) {
  const mapping = {
    'happy': 'bubble_02.png',
    'sad': 'bubble_08.png',
    'satisfied': 'bubble_07.png',
    'proud': 'bubble_01.png',
    'anxious': 'bubble_05.png',
    'angry': 'bubble_03.png',
    'afraid': 'bubble_05.png',
    'jealous': 'bubble_06.png',
  };

  final key = emotion.trim().toLowerCase();
  return mapping[key] ?? 'bubble_04.png';
}

class ScoreOrb extends StatelessWidget {
  final int score;

  const ScoreOrb({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = context.watch<SettingsNotifier>();
    return SizedBox(
      width: 214,
      height: 214,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size.square(214),
            painter: ScoreOrbPainter(colors: colors),
          ),
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.backgroundGlass,
              boxShadow: [BoxShadow(color: colors.glowLight.withValues(alpha: 0.78), blurRadius: 28, spreadRadius: 4)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: colors.accentDeep,
                    fontSize: 38,
                    fontWeight: FontWeight.w300,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  AppTranslations.get('overall', settings.appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ScoreOrbPainter extends CustomPainter {
  final AppThemeColors colors;

  ScoreOrbPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final rect = Offset.zero & size;
    final fill = Paint()
      ..shader = RadialGradient(
        colors: [
          colors.glowLight.withValues(alpha: 0.8),
          colors.accentMint.withValues(alpha: 0.28),
          colors.accentPeach.withValues(alpha: 0.24),
          colors.backgroundPrimary.withValues(alpha: 0),
        ],
        stops: const [0, 0.42, 0.72, 1],
      ).createShader(rect);
    canvas.drawCircle(center, size.shortestSide * 0.47, fill);

    for (var i = 0; i < 5; i++) {
      final path = Path();
      const points = 96;
      final baseRadius = size.shortestSide * (0.32 + i * 0.025);
      for (var p = 0; p <= points; p++) {
        final angle = (p / points) * math.pi * 2;
        final wobble = math.sin(angle * 5 + i) * 5 + math.cos(angle * 3 - i) * 3;
        final r = baseRadius + wobble;
        final point = Offset(center.dx + math.cos(angle) * r, center.dy + math.sin(angle) * r);
        if (p == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = (i.isEven ? colors.accentMint : colors.accentPeach).withValues(alpha: 0.28);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ScoreOrbPainter oldDelegate) {
    return oldDelegate.colors != colors;
  }
}

class MetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MetricItem({required this.label, required this.value, required this.color, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textPrimary, fontSize: 12, fontWeight: FontWeight.w400),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: colors.accentDeep, fontSize: 18, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
      ],
    );
  }
}

class MoodTrendCard extends StatefulWidget {
  final List<Session> sessions;

  const MoodTrendCard({required this.sessions, super.key});

  @override
  State<MoodTrendCard> createState() => _MoodTrendCardState();
}

class _MoodTrendCardState extends State<MoodTrendCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 1400), vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant MoodTrendCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessions != oldWidget.sessions) {
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = context.watch<SettingsNotifier>();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LongtermScreen()));
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
        decoration: BoxDecoration(
          color: colors.backgroundGlass,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.borderSubtle),
          boxShadow: [BoxShadow(color: colors.shadowSoft, blurRadius: 28, offset: const Offset(0, 16))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppTranslations.get('mood_trend', settings.appLanguage),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _steadinessLabel(widget.sessions, settings.appLanguage),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 22, color: colors.textMuted),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 104,
              child: AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return CustomPaint(
                    painter: MoodTrendPainter(
                      colors: colors,
                      values: _weekMoodValues(widget.sessions, _currentWeekStart()),
                      progress: _animation.value,
                    ),
                    child: child,
                  );
                },
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<double?> _weekMoodValues(List<Session> sessions, DateTime start) {
  final latestByDay = <int, Session>{};

  for (final session in sessions) {
    if (session.evaluation == null || session.evaluation!['mood'] is! num) {
      continue;
    }
    final sessionDate = _sessionDate(session);
    if (sessionDate == null) continue;

    final date = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
    final difference = date.difference(start).inDays;
    if (difference < 0 || difference >= 7) continue;

    final existing = latestByDay[difference];
    if (existing == null || sessionDate.isAfter(_sessionDate(existing)!)) {
      latestByDay[difference] = session;
    }
  }

  return List.generate(7, (index) {
    final session = latestByDay[index];
    if (session == null) return 0.0;
    return (session.evaluation!['mood'] as num).toDouble();
  });
}

String _steadinessLabel(List<Session> sessions, String lang) {
  final currentStart = _currentWeekStart();
  final previousStart = currentStart.subtract(const Duration(days: 7));

  final currentValues = _weekMoodValues(sessions, currentStart);
  final previousValues = _weekMoodValues(sessions, previousStart);
  final currentVolatility = _weekVolatility(currentValues);
  final previousVolatility = _weekVolatility(previousValues);

  if (previousVolatility == 0 || previousVolatility.isNaN) {
    if (currentVolatility == 0) return AppTranslations.get('no_changes_yet', lang);
    return currentVolatility < 0.15 
        ? AppTranslations.get('steadier', lang, arguments: {'rounded': '0'})
        : AppTranslations.get('less_steady', lang, arguments: {'rounded': '0'});
  }

  final improvement =
      ((previousVolatility - currentVolatility) / previousVolatility) * 100;
  final rounded = improvement.abs().round().toString();
  if (improvement > 0) {
    return AppTranslations.get('steadier', lang, arguments: {'rounded': rounded});
  }
  if (improvement < 0) {
    return AppTranslations.get('less_steady', lang, arguments: {'rounded': rounded});
  }
  return AppTranslations.get('as_steady', lang);
}

double _weekVolatility(List<double?> values) {
  final deltas = <double>[];
  for (var i = 1; i < values.length; i++) {
    final previous = values[i - 1];
    final current = values[i];
    if (previous != null && current != null) {
      deltas.add((current - previous).abs());
    }
  }
  if (deltas.isEmpty) return 0.0;
  return deltas.reduce((a, b) => a + b) / deltas.length;
}

DateTime _currentWeekStart() {
  final today = DateTime.now();
  return DateTime(today.year, today.month, today.day).subtract(const Duration(days: 6));
}

DateTime? _sessionDate(Session session) {
  try {
    final parsed = DateTime.parse(session.id);
    return parsed.toLocal();
  } catch (_) {
    return session.createdAt.toLocal();
  }
}

class MoodTrendPainter extends CustomPainter {
  final AppThemeColors colors;
  final List<double?> values;
  final double progress;

  MoodTrendPainter({required this.colors, required this.values, this.progress = 1.0})
    : assert(values.length == 7, 'values must have length 7'),
      assert(progress >= 0 && progress <= 1);

  @override
  void paint(Canvas canvas, Size size) {
    final xFractions = [0.02, 0.18, 0.34, 0.50, 0.66, 0.82, 0.98];
    final top = size.height * 0.12;
    final bottom = size.height * 0.82;

    final points = <Offset>[];
    for (var i = 0; i < 7; i++) {
      final x = size.width * xFractions[i];
      final mood = values[i];
      final y = mood == null ? size.height * 0.50 : ((1 - mood) / 2) * (bottom - top) + top;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final current = points[i - 1];
      final next = points[i];
      final control = Offset((current.dx + next.dx) / 2, current.dy);
      final control2 = Offset((current.dx + next.dx) / 2, next.dy);
      path.cubicTo(control.dx, control.dy, control2.dx, control2.dy, next.dx, next.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width * progress, size.height));
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.accentDeep.withValues(alpha: 0.28),
            colors.accentMint.withValues(alpha: 0.16),
            colors.backgroundPrimary.withValues(alpha: 0),
          ],
          stops: const [0, 0.28, 1],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..color = colors.accentDeep.withValues(alpha: 0.65),
    );
    canvas.restore();

    for (var i = 0; i < points.length; i++) {
      final mood = values[i];
      final base = Paint()..color = colors.backgroundCard;
      canvas.drawCircle(points[i], 4.5, base);
      final inner = Paint();
      if (mood == null) {
        inner.color = colors.textMuted.withAlpha(120);
      } else if (mood >= 0.15) {
        inner.color = colors.accentMint;
      } else if (mood <= -0.15) {
        inner.color = colors.accentPeach;
      } else {
        inner.color = colors.accentDeep;
      }
      canvas.drawCircle(points[i], 3.2, inner);
    }

    final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < labels.length; i++) {
      textPainter.text = TextSpan(
        text: labels[i],
        style: TextStyle(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w300),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(covariant MoodTrendPainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.values != values || oldDelegate.progress != progress;
  }
}
