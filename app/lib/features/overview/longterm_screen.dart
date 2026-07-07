import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/session.dart';
import '../../data/notifiers/session_notifier.dart';
import '../../data/notifiers/settings_notifier.dart';
import '../../core/localization/app_translations.dart';
import '../../shared/widgets/ivy_visuals.dart';
import '../../theme.dart';

class LongtermScreen extends StatefulWidget {
  const LongtermScreen({super.key});

  @override
  State<LongtermScreen> createState() => _LongtermScreenState();
}

class _LongtermScreenState extends State<LongtermScreen> {
  TimeRange _selectedRange = TimeRange.sixMonths;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sessions = context.watch<SessionNotifier>().sessions;
    final analysis = LongtermAnalysis.fromSessions(sessions, _selectedRange);

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
              child: IvyHeader(showSettings: false, trailing: const SizedBox(width: 48, height: 48)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 0, 22, 18),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    splashRadius: 22,
                    icon: Icon(Icons.arrow_back, color: colors.textSecondary, size: 21),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: TimeRangeSelector(
                        selectedRange: _selectedRange,
                        onChanged: (range) {
                          setState(() => _selectedRange = range);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LongtermTrendCard(analysis: analysis),
                    SizedBox(height: AppSpacing.xxl),
                    EmotionAverageCard(analysis: analysis),
                    SizedBox(height: AppSpacing.xxl),
                    const PrivacyHint(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum TimeRange {
  threeMonths('3M', 3),
  sixMonths('6M', 6),
  oneYear('1Y', 12);

  final String label;
  final int months;

  const TimeRange(this.label, this.months);
}

class TimeRangeSelector extends StatelessWidget {
  final TimeRange selectedRange;
  final ValueChanged<TimeRange> onChanged;

  const TimeRangeSelector({required this.selectedRange, required this.onChanged, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.backgroundCard.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: TimeRange.values.map((range) {
          final selected = selectedRange == range;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(range),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              width: 48,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.accentDeep : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                range.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: selected ? Colors.white : colors.textPrimary,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LongtermTrendCard extends StatelessWidget {
  final LongtermAnalysis analysis;

  const LongtermTrendCard({required this.analysis, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = context.watch<SettingsNotifier>();
    final trend = analysis.stabilityTrendPercent;
    final hasTrend = trend != null;
    final trendColor = !hasTrend || trend >= 0 ? colors.accentDeep : colors.accentPeach;

    return Container(
      constraints: const BoxConstraints(minHeight: 405),
      padding: const EdgeInsets.fromLTRB(20, 22, 18, 16),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(color: colors.shadowSoft.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.md),
          Text(
            AppTranslations.get('overall_trend', settings.appLanguage),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textMuted, fontSize: 11, fontWeight: FontWeight.w400),
          ),
          const SizedBox(height: 4),
          Text(
            hasTrend ? _formatTrend(trend) : '--',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.displaySmall?.copyWith(color: trendColor, fontSize: 40, fontWeight: FontWeight.w300, height: 1),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            analysis.trendTitle(settings.appLanguage),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: trendColor, fontSize: 15, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              analysis.trendDescription(settings.appLanguage),
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary, fontSize: 12, height: 1.35),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          LongtermChart(analysis: analysis),
          const SizedBox(height: AppSpacing.md),
          const LongtermLegend(),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  String _formatTrend(double value) {
    final rounded = value.round();
    if (rounded > 0) return '+$rounded%';
    return '$rounded%';
  }
}

class LongtermChart extends StatelessWidget {
  final LongtermAnalysis analysis;

  const LongtermChart({required this.analysis, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = context.watch<SettingsNotifier>();

    return SizedBox(
      height: 190,
      width: double.infinity,
      child: CustomPaint(
        painter: LongtermChartPainter(colors: colors, points: analysis.points),
        child: analysis.hasChartData
            ? const SizedBox.expand()
            : Center(
                child: Text(
                  AppTranslations.get('no_entries_yet', settings.appLanguage),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted, fontSize: 12),
                ),
              ),
      ),
    );
  }
}

class LongtermChartPainter extends CustomPainter {
  final AppThemeColors colors;
  final List<LongtermMonthPoint> points;

  LongtermChartPainter({required this.colors, required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final chartTop = size.height * 0.08;
    final chartBottom = size.height * 0.76;
    final left = 2.0;
    final right = size.width - 54.0;
    final width = right - left;

    final gridPaint = Paint()
      ..color = colors.textMuted.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (var i = 0; i < points.length; i++) {
      final x = _xForIndex(i, width, left);
      canvas.drawLine(Offset(x, chartTop), Offset(x, chartBottom + 8), gridPaint);
    }

    drawSeries(
      canvas,
      size,
      values: points.map((p) => p.calm).toList(),
      color: colors.accentDeep,
      label: 'Calm',
      left: left,
      width: width,
      top: chartTop,
      bottom: chartBottom,
    );
    drawSeries(
      canvas,
      size,
      values: points.map((p) => p.energy).toList(),
      color: colors.accentMint,
      label: 'Energy',
      left: left,
      width: width,
      top: chartTop,
      bottom: chartBottom,
    );
    drawSeries(
      canvas,
      size,
      values: points.map((p) => p.stress).toList(),
      color: colors.accentPeach,
      label: 'Stress',
      left: left,
      width: width,
      top: chartTop,
      bottom: chartBottom,
    );

    for (var i = 0; i < points.length; i++) {
      final x = _xForIndex(i, width, left);
      _paintText(canvas, points[i].label, Offset(x - 11, size.height - 19), colors.textMuted, 10, FontWeight.w500);
    }
  }

  void drawSeries(
    Canvas canvas,
    Size size, {
    required List<double?> values,
    required Color color,
    required String label,
    required double left,
    required double width,
    required double top,
    required double bottom,
  }) {
    final offsets = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final value = values[i];
      if (value == null) continue;
      offsets.add(Offset(_xForIndex(i, width, left), bottom - value * (bottom - top)));
    }
    if (offsets.isEmpty) return;

    final path = _smoothPath(offsets);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color.withValues(alpha: 0.78),
    );

    final end = offsets.last;
    canvas.drawCircle(end, 4.2, Paint()..color = colors.backgroundCard);
    canvas.drawCircle(end, 3.2, Paint()..color = color);
    _paintText(canvas, label, Offset(end.dx + 9, end.dy - 7), color, 11, FontWeight.w500);
  }

  double _xForIndex(int index, double width, double left) {
    if (points.length <= 1) return left + width;
    return left + width * (index / (points.length - 1));
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlDistance = (current.dx - previous.dx) * 0.45;
      path.cubicTo(
        previous.dx + controlDistance,
        previous.dy,
        current.dx - controlDistance,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    return path;
  }

  void _paintText(Canvas canvas, String text, Offset offset, Color color, double fontSize, FontWeight fontWeight) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: fontWeight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant LongtermChartPainter oldDelegate) {
    return oldDelegate.colors != colors || oldDelegate.points != points;
  }
}

class LongtermLegend extends StatelessWidget {
  const LongtermLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = context.watch<SettingsNotifier>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendItem(label: AppTranslations.get('calm', settings.appLanguage), color: colors.accentDeep),
        const SizedBox(width: AppSpacing.xl),
        _LegendItem(label: AppTranslations.get('energy', settings.appLanguage), color: colors.accentMint),
        const SizedBox(width: AppSpacing.xl),
        _LegendItem(label: AppTranslations.get('stress', settings.appLanguage), color: colors.accentPeach),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.textSecondary, fontSize: 10, fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}

class EmotionAverageCard extends StatelessWidget {
  final LongtermAnalysis analysis;

  const EmotionAverageCard({required this.analysis, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = context.watch<SettingsNotifier>();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: colors.backgroundCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.borderSubtle),
        boxShadow: [
          BoxShadow(color: colors.shadowSoft.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),
          RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w400),
              children: [
                TextSpan(
                  text: AppTranslations.get('emotional_balance', settings.appLanguage),
                  style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: '  •  ${analysis.range.label} ${AppTranslations.get('average', settings.appLanguage)}'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final emotion in LongtermAnalysis.emotions) ...[
            EmotionAverageRow(emotion: emotion, value: analysis.emotionAverages[emotion.key]),
            if (emotion != LongtermAnalysis.emotions.last) const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class EmotionAverageRow extends StatelessWidget {
  final EmotionDefinition emotion;
  final double? value;

  const EmotionAverageRow({required this.emotion, required this.value, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final settings = context.watch<SettingsNotifier>();
    final score = ((value ?? 0) * 100).round();
    final color = emotion.isPositive ? colors.accentMint : colors.accentPeach;
    final dotColor = emotion.key == 'satisfied' || emotion.key == 'calm' ? colors.accentDeep : color;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 72,
          child: Text(
            AppTranslations.get('emotion_${emotion.key}', settings.appLanguage),
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.textSecondary, fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: [
                Container(height: 5, color: colors.textMuted.withValues(alpha: 0.14)),
                FractionallySizedBox(
                  widthFactor: (value ?? 0).clamp(0.0, 1.0),
                  alignment: Alignment.centerLeft,
                  child: Container(height: 5, color: dotColor),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 52,
          child: RichText(
            textAlign: TextAlign.right,
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.textMuted, fontSize: 10, fontWeight: FontWeight.w400),
              children: [
                TextSpan(
                  text: value == null ? '--' : '$score',
                  style: TextStyle(color: colors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const TextSpan(text: ' /100'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

@immutable
class LongtermAnalysis {
  final TimeRange range;
  final List<LongtermMonthPoint> points;
  final Map<String, double?> emotionAverages;
  final double? stabilityTrendPercent;
  final int sessionCount;
  final bool isEstimatedTrend;

  const LongtermAnalysis({
    required this.range,
    required this.points,
    required this.emotionAverages,
    required this.stabilityTrendPercent,
    required this.sessionCount,
    required this.isEstimatedTrend,
  });

  static const emotions = [
    EmotionDefinition('happy', 'Happy', true),
    EmotionDefinition('sad', 'Sad', false),
    EmotionDefinition('satisfied', 'Satisfied', true),
    EmotionDefinition('proud', 'Proud', true),
    EmotionDefinition('anxious', 'Anxious', false),
    EmotionDefinition('angry', 'Angry', false),
    EmotionDefinition('afraid', 'Afraid', false),
    EmotionDefinition('jealous', 'Jealous', false),
  ];

  bool get hasChartData => points.any((point) => point.sessionCount > 0);

  String trendTitle(String lang) {
    final trend = stabilityTrendPercent;
    if (trend == null) return AppTranslations.get('start_baseline', lang);
    if (trend > 3) return AppTranslations.get('stability_improving', lang);
    if (trend < -3) return AppTranslations.get('stability_softening', lang);
    return AppTranslations.get('stability_steady', lang);
  }

  String trendDescription(String lang) {
    final label = range.label;
    final trend = stabilityTrendPercent;
    if (sessionCount == 0) {
      return AppTranslations.get('longterm_desc_empty', lang, arguments: {'label': label});
    }
    if (isEstimatedTrend) {
      return AppTranslations.get('longterm_desc_early', lang, arguments: {'label': label});
    }
    if (trend == null) {
      return AppTranslations.get('longterm_desc_baseline', lang, arguments: {'label': label});
    }
    if (trend > 3) {
      return AppTranslations.get('longterm_desc_improving', lang, arguments: {'label': label});
    }
    if (trend < -3) {
      return AppTranslations.get('longterm_desc_softening', lang, arguments: {'label': label});
    }
    return AppTranslations.get('longterm_desc_steady', lang, arguments: {'label': label});
  }

  factory LongtermAnalysis.fromSessions(List<Session> sessions, TimeRange range) {
    final now = DateTime.now();
    final bucketStarts = List.generate(range.months, (index) {
      return DateTime(now.year, now.month - range.months + 1 + index);
    });
    final rangeStart = bucketStarts.first;
    final rangeEnd = DateTime(now.year, now.month + 1);

    final completeSessions = sessions.where((session) {
      if (session.evaluation == null) return false;
      final date = _sessionDate(session);
      return !date.isBefore(rangeStart) && date.isBefore(rangeEnd);
    }).toList()..sort((a, b) => _sessionDate(a).compareTo(_sessionDate(b)));

    final byMonth = <DateTime, List<Session>>{for (final start in bucketStarts) start: <Session>[]};
    for (final session in completeSessions) {
      final date = _sessionDate(session);
      final key = DateTime(date.year, date.month);
      byMonth[key]?.add(session);
    }

    final fallbackCalm = _average(completeSessions, _calmScoreFraction);
    final fallbackEnergy = _average(completeSessions, _energyScoreFraction);
    final fallbackStress = _average(completeSessions, _stressScoreFraction);
    final fallbackStability = _average(completeSessions, _stabilityScoreFraction);

    final points = bucketStarts.map((start) {
      final monthSessions = byMonth[start] ?? const <Session>[];
      final hasMonthData = monthSessions.isNotEmpty;
      return LongtermMonthPoint(
        label: _monthLabel(start),
        calm: _average(monthSessions, _calmScoreFraction) ?? fallbackCalm,
        energy: _average(monthSessions, _energyScoreFraction) ?? fallbackEnergy,
        stress: _average(monthSessions, _stressScoreFraction) ?? fallbackStress,
        stability: _average(monthSessions, _stabilityScoreFraction) ?? fallbackStability,
        sessionCount: monthSessions.length,
        isEstimated: !hasMonthData && completeSessions.isNotEmpty,
      );
    }).toList();

    final emotionAverages = <String, double?>{
      for (final emotion in emotions)
        emotion.key: _average(completeSessions, (session) => _emotionValue(session, emotion.key)),
    };

    final monthlyTrend = _trendPercent(points.where((p) => !p.isEstimated).toList());
    final sessionTrend = _sessionTrendPercent(completeSessions);
    final trend = monthlyTrend ?? sessionTrend ?? _baselineTrendPercent(fallbackStability);

    return LongtermAnalysis(
      range: range,
      points: points,
      emotionAverages: emotionAverages,
      stabilityTrendPercent: trend,
      sessionCount: completeSessions.length,
      isEstimatedTrend: monthlyTrend == null && trend != null,
    );
  }

  static DateTime _sessionDate(Session session) {
    try {
      return DateTime.parse(session.id).toLocal();
    } catch (_) {
      return session.createdAt.toLocal();
    }
  }

  static double? _average(List<Session> sessions, double? Function(Session) valueFor) {
    final values = sessions.map(valueFor).whereType<double>().toList();
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }

  static double? _emotionValue(Session session, String key) {
    final emotions = session.evaluation?['emotions'];
    if (emotions is! Map || emotions[key] is! num) return null;
    return ((emotions[key] as num).toDouble()).clamp(0.0, 1.0);
  }

  static double? _calmScoreFraction(Session session) {
    final anxious = _emotionValue(session, 'anxious');
    final angry = _emotionValue(session, 'angry');
    final afraid = _emotionValue(session, 'afraid');
    final satisfied = _emotionValue(session, 'satisfied');
    final negativeValues = [anxious, angry, afraid].whereType<double>().toList();
    if (negativeValues.isEmpty && satisfied == null) return null;
    final negative = negativeValues.isEmpty ? 0.0 : negativeValues.reduce((a, b) => a + b) / negativeValues.length;
    return (((1 - negative) + (satisfied ?? (1 - negative))) / 2).clamp(0.0, 1.0);
  }

  static double? _energyScoreFraction(Session session) {
    final values = [
      _emotionValue(session, 'happy'),
      _emotionValue(session, 'proud'),
      _emotionValue(session, 'satisfied'),
    ].whereType<double>().toList();
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).clamp(0.0, 1.0);
  }

  static double? _stressScoreFraction(Session session) {
    final values = [
      _emotionValue(session, 'anxious'),
      _emotionValue(session, 'angry'),
      _emotionValue(session, 'afraid'),
    ].whereType<double>().toList();
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).clamp(0.0, 1.0);
  }

  static double? _stabilityScoreFraction(Session session) {
    final calm = _calmScoreFraction(session);
    final energy = _energyScoreFraction(session);
    final stress = _stressScoreFraction(session);
    final values = [calm, energy, if (stress != null) 1 - stress].whereType<double>().toList();
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).clamp(0.0, 1.0);
  }

  static double? _trendPercent(List<LongtermMonthPoint> points) {
    if (points.length < 2) return null;
    final split = (points.length / 2).floor();
    final first = points.take(split).map((p) => p.stability).whereType<double>().toList();
    final second = points.skip(split).map((p) => p.stability).whereType<double>().toList();
    if (first.isEmpty || second.isEmpty) return null;
    final firstAverage = first.reduce((a, b) => a + b) / first.length;
    final secondAverage = second.reduce((a, b) => a + b) / second.length;
    if (firstAverage == 0) return null;
    return ((secondAverage - firstAverage) / firstAverage) * 100;
  }

  static double? _sessionTrendPercent(List<Session> sessions) {
    final values = sessions.map(_stabilityScoreFraction).whereType<double>().toList();
    if (values.length < 2) return null;
    final split = (values.length / 2).floor();
    final first = values.take(split).toList();
    final second = values.skip(split).toList();
    if (first.isEmpty || second.isEmpty) return null;
    final firstAverage = first.reduce((a, b) => a + b) / first.length;
    final secondAverage = second.reduce((a, b) => a + b) / second.length;
    if (firstAverage == 0) return null;
    return ((secondAverage - firstAverage) / firstAverage) * 100;
  }

  static double? _baselineTrendPercent(double? stability) {
    if (stability == null) return null;
    return (stability - 0.5) * 100;
  }

  static String _monthLabel(DateTime date) {
    const labels = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return labels[date.month - 1];
  }
}

@immutable
class LongtermMonthPoint {
  final String label;
  final double? calm;
  final double? energy;
  final double? stress;
  final double? stability;
  final int sessionCount;
  final bool isEstimated;

  const LongtermMonthPoint({
    required this.label,
    required this.calm,
    required this.energy,
    required this.stress,
    required this.stability,
    required this.sessionCount,
    required this.isEstimated,
  });
}

@immutable
class EmotionDefinition {
  final String key;
  final String label;
  final bool isPositive;

  const EmotionDefinition(this.key, this.label, this.isPositive);
}
