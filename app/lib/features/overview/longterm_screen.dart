import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

import '../../data/models/session.dart';
import '../../data/notifiers/session_notifier.dart';
import '../../shared/widgets/ivy_visuals.dart';
import '../../theme.dart';

class LongtermScreen extends StatefulWidget {
  const LongtermScreen({super.key});

  @override
  State<LongtermScreen> createState() => _LongtermScreenState();
}

class _LongtermScreenState extends State<LongtermScreen> {
  bool _isScrubbing = false;
  Session? _selectedSession;
  DateTime? _latestDate;
  List<Session> _evaluationSessions = [];

  String _formatDate(DateTime date) {
    const months = [
      'Jan.',
      'Feb.',
      'Mar.',
      'Apr.',
      'May',
      'June',
      'July',
      'Aug.',
      'Sep.',
      'Oct.',
      'Nov.',
      'Dec.',
    ];
    return '${date.day.toString().padLeft(2, '0')}. ${months[date.month - 1]}';
  }

  void _updateScrubbingPosition(
    double dy,
    double topPadding,
    double weekHeight,
  ) {
    if (_evaluationSessions.isEmpty || _latestDate == null) return;

    final dayHeight = weekHeight / 7.0;

    Session? closest;
    double minDistance = double.infinity;

    for (final session in _evaluationSessions) {
      final sessionDate = _sessionDate(session);
      if (sessionDate == null) continue;

      final d = DateTime(sessionDate.year, sessionDate.month, sessionDate.day);
      final daysAgo = _latestDate!.difference(d).inDays;
      final y = topPadding + daysAgo * dayHeight;

      final distance = (y - dy).abs();
      if (distance < minDistance) {
        minDistance = distance;
        closest = session;
      }
    }

    setState(() {
      _selectedSession = closest;
    });
  }

  DateTime? _sessionDate(Session session) {
    try {
      final parsed = DateTime.parse(session.id);
      return parsed.toLocal();
    } catch (_) {
      return session.createdAt.toLocal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final allSessions = context.watch<SessionNotifier>().sessions;
    _evaluationSessions =
        allSessions.where((s) => s.evaluation != null).toList()..sort((a, b) {
          final dateA = _sessionDate(a) ?? a.createdAt;
          final dateB = _sessionDate(b) ?? b.createdAt;
          return dateB.compareTo(dateA);
        });

    if (_evaluationSessions.isNotEmpty) {
      final rawLatest = _sessionDate(_evaluationSessions.first);
      if (rawLatest != null) {
        _latestDate = DateTime(rawLatest.year, rawLatest.month, rawLatest.day);
      }
    }

    int maxDaysAgo = 0;
    if (_evaluationSessions.isNotEmpty && _latestDate != null) {
      final oldestDate = _sessionDate(_evaluationSessions.last);
      if (oldestDate != null) {
        maxDaysAgo = _latestDate!
            .difference(
              DateTime(oldestDate.year, oldestDate.month, oldestDate.day),
            )
            .inDays;
      }
    }

    final int totalWeeks = (maxDaysAgo / 7.0).ceil();
    final int weeksToDraw = math.max(totalWeeks, 4);

    const double weekHeight = 100.0;
    const double topPadding = 12.0;
    const double bottomPadding = 40.0;
    final double chartHeight =
        topPadding + weeksToDraw * weekHeight + bottomPadding;

    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 10),
              child: IvyHeader(
                showSettings: false,
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward, color: colors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ),
            SizedBox(height: 4),
            SizedBox(height: 20, child: _buildHeaderLabels(context)),

            Expanded(
              child: _evaluationSessions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 48,
                              color: colors.textMuted.withOpacity(0.5),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'No trends available yet',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: colors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              'Record your mental state regularly to see your long-term mood and emotion analysis charts here.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colors.textSecondary,
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: _isScrubbing
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onLongPressStart: (details) {
                          setState(() => _isScrubbing = true);
                          _updateScrubbingPosition(
                            details.localPosition.dy,
                            topPadding,
                            weekHeight,
                          );
                        },
                        onLongPressMoveUpdate: (details) {
                          _updateScrubbingPosition(
                            details.localPosition.dy,
                            topPadding,
                            weekHeight,
                          );
                        },
                        onLongPressEnd: (_) => setState(() => _isScrubbing = false),
                        onTapDown: (details) {
                          _updateScrubbingPosition(
                            details.localPosition.dy,
                            topPadding,
                            weekHeight,
                          );
                        },
                        child: CustomPaint(
                          size: Size(double.infinity, chartHeight),
                          painter: LongtermChartPainter(
                            colors: colors,
                            sessions: _evaluationSessions,
                            latestDate: _latestDate,
                            weekHeight: weekHeight,
                            topPadding: topPadding,
                            selectedSession: _selectedSession,
                            formatDate: _formatDate,
                          ),
                        ),
                      ),
                    ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: PrivacyHint(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderLabels(BuildContext context) {
    if (_evaluationSessions.isEmpty) return const SizedBox();

    final colors = context.appColors;
    final latest = _evaluationSessions.first;

    final calmScore =
        (latest.evaluation?['emotions']?['satisfied'] ?? 0.72) * 100;
    final overallScore = (((latest.evaluation?['mood'] ?? 0.0) + 1) / 2) * 100;
    final stressScore =
        (latest.evaluation?['emotions']?['anxious'] ?? 0.34) * 100;
    final energyScore =
        (latest.evaluation?['emotions']?['happy'] ?? 0.61) * 100;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        const chartLeft = 90.0;
        final chartRight = w - 20.0;
        final chartWidth = chartRight - chartLeft;

        double toX(double score) => chartLeft + (score / 100.0) * chartWidth;

        List<double> idealX = [
          toX(calmScore),
          toX(overallScore),
          toX(stressScore),
          toX(energyScore),
        ];

        const minGap = 55.0;
        List<MapEntry<int, double>> items = idealX.asMap().entries.toList();
        items.sort((a, b) => a.value.compareTo(b.value));

        List<double> adjusted = items.map((e) => e.value).toList();
        for (int iter = 0; iter < 10; iter++) {
          for (int i = 0; i < 3; i++) {
            if (adjusted[i + 1] - adjusted[i] < minGap) {
              double overlap = minGap - (adjusted[i + 1] - adjusted[i]);
              adjusted[i] -= overlap / 2;
              adjusted[i + 1] += overlap / 2;
            }
          }
          if (adjusted[0] < chartLeft - 10) {
            double shift = (chartLeft - 10) - adjusted[0];
            for (int i = 0; i < 4; i++) adjusted[i] += shift;
          }
          if (adjusted[3] > chartRight + 10) {
            double shift = adjusted[3] - (chartRight + 10);
            for (int i = 0; i < 4; i++) adjusted[i] -= shift;
          }
        }

        List<double> finalX = List.filled(4, 0.0);
        for (int i = 0; i < 4; i++) {
          finalX[items[i].key] = adjusted[i];
        }

        return Stack(
          children: [
            _LabelWidget(text: 'Calm', x: finalX[0], color: colors.accentDeep),
            _LabelWidget(
              text: 'overall',
              x: finalX[1],
              color: colors.textPrimary,
              isBold: true,
            ),
            _LabelWidget(
              text: 'Stress',
              x: finalX[2],
              color: colors.accentPeach,
            ),
            _LabelWidget(
              text: 'Energy',
              x: finalX[3],
              color: colors.accentMint,
            ),
          ],
        );
      },
    );
  }
}

class _LabelWidget extends StatelessWidget {
  final String text;
  final double x;
  final Color color;
  final bool isBold;

  const _LabelWidget({
    required this.text,
    required this.x,
    required this.color,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - 30,
      top: 0,
      width: 60,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

class LongtermChartPainter extends CustomPainter {
  final AppThemeColors colors;
  final List<Session> sessions;
  final DateTime? latestDate;
  final double weekHeight;
  final double topPadding;
  final Session? selectedSession;
  final String Function(DateTime) formatDate;

  LongtermChartPainter({
    required this.colors,
    required this.sessions,
    required this.latestDate,
    required this.weekHeight,
    required this.topPadding,
    required this.selectedSession,
    required this.formatDate,
  });

  DateTime? _sessionDate(Session session) {
    try {
      final parsed = DateTime.parse(session.id);
      return parsed.toLocal();
    } catch (_) {
      return session.createdAt.toLocal();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (sessions.isEmpty || latestDate == null) return;

    final chartLeft = 90.0;
    final chartRight = size.width - 20.0;
    final chartWidth = chartRight - chartLeft;
    final dayHeight = weekHeight / 7.0;

    double toX(double score) => chartLeft + (score / 100.0) * chartWidth;
    double toY(DateTime date) {
      final d = DateTime(date.year, date.month, date.day);
      final daysAgo = latestDate!.difference(d).inDays;
      return topPadding + daysAgo * dayHeight;
    }

    final gridLinePaint = Paint()
      ..color = colors.textMuted.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final maxDaysAgo = latestDate!
        .difference(
          DateTime(
            _sessionDate(sessions.last)!.year,
            _sessionDate(sessions.last)!.month,
            _sessionDate(sessions.last)!.day,
          ),
        )
        .inDays;

    final weeksToDraw = math.max((maxDaysAgo / 7.0).ceil(), 4);

    for (int w = 1; w <= weeksToDraw; w++) {
      final y = topPadding + w * 7 * dayHeight;
      canvas.drawLine(Offset(75, y), Offset(size.width - 15, y), gridLinePaint);

      String label;
      if (w == 1) {
        label = '1 Week ago';
      } else if (w == 2) {
        label = '2 Weeks ago';
      } else {
        final date = latestDate!.subtract(Duration(days: w * 7));
        label = formatDate(date);
      }

      final textSpan = TextSpan(
        text: label,
        style: TextStyle(
          color: colors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
      );
      final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(canvas, Offset(70 - tp.width, y - tp.height / 2));
    }

    final calmPoints = <Offset>[];
    final overallPoints = <Offset>[];
    final stressPoints = <Offset>[];
    final energyPoints = <Offset>[];

    for (final session in sessions) {
      final rawDate = _sessionDate(session);
      if (rawDate == null) continue;
      final date = DateTime(rawDate.year, rawDate.month, rawDate.day);
      final y = toY(date);

      final calmScore =
          (session.evaluation?['emotions']?['satisfied'] ?? 0.72) * 100;
      final overallScore =
          (((session.evaluation?['mood'] ?? 0.0) + 1) / 2) * 100;
      final stressScore =
          (session.evaluation?['emotions']?['anxious'] ?? 0.34) * 100;
      final energyScore =
          (session.evaluation?['emotions']?['happy'] ?? 0.61) * 100;

      calmPoints.add(Offset(toX(calmScore), y));
      overallPoints.add(Offset(toX(overallScore), y));
      stressPoints.add(Offset(toX(stressScore), y));
      energyPoints.add(Offset(toX(energyScore), y));
    }

    Path buildSmoothPath(List<Offset> points) {
      final path = Path();
      if (points.isEmpty) return path;
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final current = points[i - 1];
        final next = points[i];
        final dy = next.dy - current.dy;
        final ctrl1 = Offset(current.dx, current.dy + dy * 0.4);
        final ctrl2 = Offset(next.dx, next.dy - dy * 0.4);
        path.cubicTo(ctrl1.dx, ctrl1.dy, ctrl2.dx, ctrl2.dy, next.dx, next.dy);
      }
      return path;
    }

    void drawPath(Path path, Color color, double width) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }

    drawPath(
      buildSmoothPath(calmPoints),
      colors.accentDeep.withOpacity(0.8),
      2.0,
    );
    drawPath(
      buildSmoothPath(stressPoints),
      colors.accentPeach.withOpacity(0.8),
      2.0,
    );
    drawPath(
      buildSmoothPath(energyPoints),
      colors.accentMint.withOpacity(0.8),
      2.0,
    );
    drawPath(buildSmoothPath(overallPoints), colors.textPrimary, 3.2);

    if (selectedSession != null) {
      final rawSDate = _sessionDate(selectedSession!);
      if (rawSDate != null) {
        final sDate = DateTime(rawSDate.year, rawSDate.month, rawSDate.day);
        final overallScore =
            (((selectedSession!.evaluation?['mood'] ?? 0.0) + 1) / 2) * 100;
        final x = toX(overallScore);
        final y = toY(sDate);

        final dotPaint = Paint()..color = colors.textPrimary;
        canvas.drawCircle(Offset(x, y), 6.5, dotPaint);

        final innerPaint = Paint()..color = colors.backgroundCard;
        canvas.drawCircle(Offset(x, y), 2.0, innerPaint);

        final textSpan = TextSpan(
          text: '${formatDate(sDate)}: ${overallScore.round()}',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        );
        final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)
          ..layout();

        final bubbleWidth = tp.width + 20.0;
        final bubbleHeight = tp.height + 12.0;

        double bubbleLeft = x - bubbleWidth - 12.0;
        if (bubbleLeft < 10.0) {
          bubbleLeft = x + 12.0;
        }
        final bubbleTop = y - bubbleHeight / 2;

        final bubbleRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(bubbleLeft, bubbleTop, bubbleWidth, bubbleHeight),
          const Radius.circular(8.0),
        );

        final shadowPaint = Paint()
          ..color = Colors.black.withOpacity(0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
        canvas.drawRRect(bubbleRect.shift(const Offset(0, 3)), shadowPaint);

        final bgPaint = Paint()..color = colors.backgroundCard;
        canvas.drawRRect(bubbleRect, bgPaint);

        final borderPaint = Paint()
          ..color = colors.borderSubtle
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawRRect(bubbleRect, borderPaint);

        tp.paint(canvas, Offset(bubbleLeft + 10.0, bubbleTop + 6.0));
      }
    }
  }

  @override
  bool shouldRepaint(covariant LongtermChartPainter oldDelegate) {
    return oldDelegate.colors != colors ||
        oldDelegate.sessions != sessions ||
        oldDelegate.latestDate != latestDate ||
        oldDelegate.selectedSession != selectedSession;
  }
}
