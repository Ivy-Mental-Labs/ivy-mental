import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../features/score_reminder/score_reminder_settings_screen.dart';

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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_outline, size: 13, color: colors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'On-device analysis',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textMuted, fontSize: 12, fontWeight: FontWeight.w300),
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

class ScoreOrb extends StatelessWidget {
  final int score;

  const ScoreOrb({required this.score, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                  'Overall',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary, fontSize: 11),
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
  final int value;
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
          '$value',
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

class MoodTrendCard extends StatelessWidget {
  const MoodTrendCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
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
                      'Mood trend',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '+8% steadier',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
              Icon(Icons.info_outline, size: 15, color: colors.textMuted),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 104,
            child: CustomPaint(
              painter: MoodTrendPainter(colors: colors),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodTrendPainter extends CustomPainter {
  final AppThemeColors colors;

  MoodTrendPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[
      Offset(size.width * 0.02, size.height * 0.50),
      Offset(size.width * 0.18, size.height * 0.28),
      Offset(size.width * 0.34, size.height * 0.40),
      Offset(size.width * 0.50, size.height * 0.72),
      Offset(size.width * 0.66, size.height * 0.45),
      Offset(size.width * 0.82, size.height * 0.22),
      Offset(size.width * 0.98, size.height * 0.38),
    ];

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final control = Offset((current.dx + next.dx) / 2, current.dy);
      final control2 = Offset((current.dx + next.dx) / 2, next.dy);
      path.cubicTo(control.dx, control.dy, control2.dx, control2.dy, next.dx, next.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.accentDeep.withValues(alpha: 0.18),
            colors.accentMint.withValues(alpha: 0.06),
            colors.backgroundPrimary.withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round
        ..color = colors.accentDeep.withValues(alpha: 0.42),
    );

    final pointColors = [
      colors.accentDeep,
      colors.accentDeep,
      colors.accentMint,
      colors.accentPeach,
      colors.accentMint,
      colors.accentDeep,
      colors.accentMint,
    ];
    for (var i = 0; i < points.length; i++) {
      canvas.drawCircle(points[i], 4.5, Paint()..color = colors.backgroundCard);
      canvas.drawCircle(points[i], 3.2, Paint()..color = pointColors[i]);
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
    return oldDelegate.colors != colors;
  }
}
