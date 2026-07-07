import 'dart:ui';

import 'package:app/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../data/models/session.dart';
import '../../../../data/notifiers/session_notifier.dart';
import '../../../../data/notifiers/settings_notifier.dart';
import '../../../../core/localization/app_translations.dart';
import '../../../../data/repositories/session_repository.dart';
import '../../../../shared/widgets/ivy_visuals.dart';

class HistoryEntryViewData {
  final double moodScore;
  final String analysisText;
  final String patternText;
  final String patternFrequency;
  final List<EmotionalLayerViewData> emotionalLayers;
  final String? transcript;

  const HistoryEntryViewData({
    required this.moodScore,
    required this.analysisText,
    required this.patternText,
    required this.patternFrequency,
    required this.emotionalLayers,
    this.transcript,
  });

  factory HistoryEntryViewData.fromSession(Session session, String lang) {
    final evaluation = session.evaluation;
    final moodScore = (evaluation?['mood'] as num?)?.toDouble() ?? 0.24;
    final emotions = evaluation?['emotions'];
    final emotionalLayers = emotions is Map
        ? emotions.entries
              .where((entry) => entry.value is num)
              .map(
                (entry) => EmotionalLayerViewData.fromScore(
                  label: _titleCase(entry.key.toString()),
                  score: (entry.value as num).toDouble(),
                ),
              )
              .toList()
        : <EmotionalLayerViewData>[];

    final pattern = _patternFor(moodScore, lang);

    return HistoryEntryViewData(
      moodScore: moodScore.clamp(-1.0, 1.0),
      analysisText: _analysisTextFor(moodScore, lang),
      patternText: pattern.key,
      patternFrequency: pattern.value,
      emotionalLayers: emotionalLayers.isEmpty
          ? HistoryEntryViewData.fallback(lang).emotionalLayers
          : emotionalLayers,
      transcript: session.transcript,
    );
  }

  factory HistoryEntryViewData.fallback(String lang) {
    return HistoryEntryViewData(
      moodScore: 0.24,
      analysisText: AppTranslations.get('analysis_tired', lang),
      patternText: lang == 'de'
          ? "Gesteigerte Gefühle der Dankbarkeit nach sozialen Interaktionen."
          : "Increased feelings of gratitude after social interactions.",
      patternFrequency: lang == 'de' ? '2x diese Woche' : '2x this week',
      emotionalLayers: [
        EmotionalLayerViewData(
          label: 'Calm',
          value: 63,
          color: Color(0xFF8DA6AE),
        ),
        EmotionalLayerViewData(
          label: 'Joy',
          value: 42,
          color: Color(0xFFD7DED4),
        ),
        EmotionalLayerViewData(
          label: 'Stress',
          value: 42,
          color: Color(0xFFEABDB5),
        ),
        EmotionalLayerViewData(
          label: 'Joy',
          value: 42,
          color: Color(0xFFD7DED4),
        ),
        EmotionalLayerViewData(
          label: 'Joy',
          value: 42,
          color: Color(0xFFD7DED4),
        ),
        EmotionalLayerViewData(
          label: 'Joy',
          value: 42,
          color: Color(0xFFD7DED4),
        ),
        EmotionalLayerViewData(
          label: 'Joy',
          value: 42,
          color: Color(0xFFD7DED4),
        ),
        EmotionalLayerViewData(
          label: 'Joy',
          value: 42,
          color: Color(0xFFD7DED4),
        ),
      ],
    );
  }

  static MapEntry<String, String> _patternFor(double moodScore, String lang) {
    int count = 0;
    String text = "";
    String frequency = "";

    try {
      final allSessions = SessionRepository().getAll();
      final now = DateTime.now();
      final startOf7DaysAgo = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6));

      final recentSessions = allSessions.where((s) {
        if (s.evaluation == null || s.evaluation!['mood'] is! num) return false;
        DateTime sessionDate;
        try {
          sessionDate = DateTime.parse(s.id);
        } catch (_) {
          sessionDate = s.createdAt;
        }
        final dateOnly = DateTime(
          sessionDate.year,
          sessionDate.month,
          sessionDate.day,
        );
        return !dateOnly.isBefore(startOf7DaysAgo);
      }).toList();

      if (moodScore <= -0.7) {
        text = AppTranslations.get('pattern_very_low', lang);
        count = recentSessions
            .where((s) => (s.evaluation!['mood'] as num).toDouble() <= -0.7)
            .length;
        if (count == 1) {
          frequency = AppTranslations.get('freq_checkin_singular', lang);
        } else {
          frequency = AppTranslations.get('freq_checkin_plural', lang, arguments: {'count': '$count'});
        }
      } else if (moodScore <= -0.2) {
        text = AppTranslations.get('pattern_low', lang);
        count = recentSessions.where((s) {
          final m = (s.evaluation!['mood'] as num).toDouble();
          return m > -0.7 && m <= -0.2;
        }).length;
        if (count == 1) {
          frequency = AppTranslations.get('freq_checkin_singular', lang);
        } else {
          frequency = AppTranslations.get('freq_checkin_plural', lang, arguments: {'count': '$count'});
        }
      } else if (moodScore < 0.2) {
        text = AppTranslations.get('pattern_balanced', lang);
        count = recentSessions.where((s) {
          final m = (s.evaluation!['mood'] as num).toDouble();
          return m > -0.2 && m < 0.2;
        }).length;
        if (count == 1) {
          frequency = AppTranslations.get('freq_balanced_singular', lang);
        } else {
          frequency = AppTranslations.get('freq_balanced_plural', lang, arguments: {'count': '$count'});
        }
      } else if (moodScore < 0.7) {
        text = AppTranslations.get('pattern_positive', lang);
        count = recentSessions.where((s) {
          final m = (s.evaluation!['mood'] as num).toDouble();
          return m >= 0.2 && m < 0.7;
        }).length;
        if (count == 1) {
          frequency = AppTranslations.get('freq_positive_singular', lang);
        } else {
          frequency = AppTranslations.get('freq_positive_plural', lang, arguments: {'count': '$count'});
        }
      } else {
        text = AppTranslations.get('pattern_super', lang);
        count = recentSessions
            .where((s) => (s.evaluation!['mood'] as num).toDouble() >= 0.7)
            .length;
        if (count == 1) {
          frequency = AppTranslations.get('freq_checkin_singular', lang);
        } else {
          frequency = AppTranslations.get('freq_checkin_plural', lang, arguments: {'count': '$count'});
        }
      }
    } catch (e) {
      if (moodScore <= -0.7) {
        text = AppTranslations.get('pattern_very_low', lang);
        frequency = AppTranslations.get('freq_checkin_singular', lang);
      } else if (moodScore <= -0.2) {
        text = AppTranslations.get('pattern_low', lang);
        frequency = AppTranslations.get('freq_checkin_singular', lang);
      } else if (moodScore < 0.2) {
        text = AppTranslations.get('pattern_balanced', lang);
        frequency = AppTranslations.get('freq_balanced_singular', lang);
      } else if (moodScore < 0.7) {
        text = AppTranslations.get('pattern_positive', lang);
        frequency = AppTranslations.get('freq_positive_singular', lang);
      } else {
        text = AppTranslations.get('pattern_super', lang);
        frequency = AppTranslations.get('freq_checkin_singular', lang);
      }
    }

    return MapEntry(text, frequency);
  }

  static String _analysisTextFor(double moodScore, String lang) {
    if (moodScore <= -0.2) {
      return AppTranslations.get('analysis_tired', lang);
    }
    if (moodScore >= 0.35) {
      return AppTranslations.get('analysis_steady', lang);
    }
    return AppTranslations.get('analysis_tired', lang);
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
  }
}

String _relativeDate(DateTime date, String lang) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return AppTranslations.get('today', lang);
  if (diff == 1) return AppTranslations.get('yesterday', lang);
  return '${date.day}.${date.month}.${date.year}';
}

class EmotionalLayerViewData {
  final String label;
  final int value;
  final Color color;

  const EmotionalLayerViewData({
    required this.label,
    required this.value,
    required this.color,
  });

  factory EmotionalLayerViewData.fromScore({
    required String label,
    required double score,
  }) {
    return EmotionalLayerViewData(
      label: label,
      value: (score.clamp(0.0, 1.0) * 100).round(),
      color: _colorFor(label),
    );
  }

  static Color _colorFor(String label) {
    switch (label.toLowerCase()) {
      case 'stress':
      case 'anxious':
      case 'angry':
      case 'anger':
      case 'sad':
      case 'sadness':
      case 'afraid':
      case 'jealous':
        return const Color(0xFFEABDB5);

      case 'joy':
      case 'happy':
      case 'hope':
      case 'proud':
        return const Color(0xFFD7DED4);

      case 'satisfied':
      case 'calm':
        return const Color(0xFF8DA6AE);

      default:
        return const Color(0xFF8DA6AE);
    }
  }
}

class HistoryEntryScreen extends StatefulWidget {
  final Session? session;
  final HistoryEntryViewData? data;

  const HistoryEntryScreen({super.key, this.session, this.data});

  @override
  State<HistoryEntryScreen> createState() => _HistoryEntryScreenState();
}

class _HistoryEntryScreenState extends State<HistoryEntryScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _orbScale;
  late Animation<double> _scoreCounter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _orbScale = Tween<double>(
      begin: 1.0,
      end: 1.08,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scoreCounter = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final navigator = Navigator.of(context);
    final sessionNotifier = context.read<SessionNotifier>();
    final sessionId = widget.session!.id;
    final colors = context.appColors;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 48),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFEFC),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0x16D7D0C8)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0F776F66),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppTranslations.get('delete_entry', context.read<SettingsNotifier>().appLanguage),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  AppTranslations.get('delete_entry_confirm', context.read<SettingsNotifier>().appLanguage),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(false),

                      child: Text(
                        AppTranslations.get('cancel', context.read<SettingsNotifier>().appLanguage),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),

                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(true),

                      child: Text(
                        AppTranslations.get('delete', context.read<SettingsNotifier>().appLanguage),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF8A3033),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed == true && mounted) {
      navigator.pop();
      await sessionNotifier.delete(sessionId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<SettingsNotifier>().appLanguage;
    final isPending = widget.session?.status == SessionStatus.transcribing;
    final viewData = isPending
        ? null
        : widget.data ??
              (widget.session == null
                  ? HistoryEntryViewData.fallback(lang)
                  : HistoryEntryViewData.fromSession(widget.session!, lang));
    final headerLabel = _relativeDate(
      widget.session?.createdAt ?? DateTime.now(),
      lang,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F1EC),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(22, 27, 22, 30),
          children: [
            Text(
              'IvyMental',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF9B9D9A),
                fontSize: 16,
                fontWeight: FontWeight.w200,
              ),
            ),
            const SizedBox(height: 21),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                color: const Color(0xFFA7AAA7),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 32,
                  height: 32,
                ),
                tooltip: 'Back',
              ),
            ),
            const SizedBox(height: 3),
            Text(
              AppTranslations.get('header_analysis', lang, arguments: {
                'date': headerLabel,
              }),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFFB4B6B4),
                fontSize: 18,
                fontWeight: FontWeight.w200,
              ),
            ),
            const SizedBox(height: 55),
            if (isPending) ...[
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    color: const Color(0xFF6EA4A0),
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                AppTranslations.get('transcribing', context.read<SettingsNotifier>().appLanguage),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF5F665F),
                  fontSize: 18,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(height: 16),
              _SoftCard(
                padding: const EdgeInsets.all(18),
                child: Text(
                  AppTranslations.get('transcribing_desc', context.read<SettingsNotifier>().appLanguage),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF737A76),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 39),
              const PrivacyHint(),
            ] else ...[
              Center(
                child: AnimatedBuilder(
                  animation: _orbScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _orbScale.value,
                      child: child,
                    );
                  },
                  child: _MoodOrb(score: viewData!.moodScore),
                ),
              ),
              const SizedBox(height: 56),
              _SectionLabel(AppTranslations.get('mood', lang)),
              const SizedBox(height: 11),
              _MoodCard(
                score: viewData.moodScore,
                animationValue: _scoreCounter,
              ),
              const SizedBox(height: 14),
              FadeTransition(
                opacity: _scoreCounter,
                child: _AnalysisCard(text: viewData.analysisText),
              ),
              const SizedBox(height: 25),
              _SectionLabel(AppTranslations.get('pattern_recognition', lang)),
              const SizedBox(height: 11),
              _PatternCard(
                text: viewData.patternText,
                frequency: viewData.patternFrequency,
              ),
              const SizedBox(height: 24),
              _SectionLabel(AppTranslations.get('emotional_layers', lang)),
              const SizedBox(height: 11),
              ...viewData.emotionalLayers.map(
                (layer) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _EmotionalLayerTile(layer: layer),
                ),
              ),
              if (viewData.transcript?.trim().isNotEmpty ?? false) ...[
                const SizedBox(height: 11),
                _SectionLabel(AppTranslations.get('transcript', lang)),
                const SizedBox(height: 11),
                _TranscriptCard(text: viewData.transcript!.trim()),
              ],
              if (widget.session != null) ...[
                const SizedBox(height: 24),
                Center(
                  child: InkWell(
                    onTap: () => _showDeleteConfirmation(context),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        AppTranslations.get('delete_entry_btn', context.read<SettingsNotifier>().appLanguage),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Color(0xFF8A3033),
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 39),
              const PrivacyHint(),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color(0xFF838784),
        fontSize: 12,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFEFC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0x16D7D0C8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F776F66),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _MoodOrb extends StatelessWidget {
  final double score;

  const _MoodOrb({required this.score});

  @override
  Widget build(BuildContext context) {
    final intensity = score.abs().clamp(0.18, 1.0);
    final baseColor = score < 0
        ? const Color(0xFFDDA89C)
        : const Color(0xFF6EA4A0);

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.24 + intensity * 0.1),
            blurRadius: 21,
            spreadRadius: 1,
          ),
          const BoxShadow(
            color: Color(0x26000000),
            blurRadius: 13,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: const Alignment(-0.32, -0.34),
                radius: 0.98,
                colors: [
                  Colors.white.withValues(alpha: 0.86),
                  baseColor.withValues(alpha: 0.37 + intensity * 0.28),
                  const Color(0xFF2F756F).withValues(alpha: 0.44),
                  const Color(0xFFE6DED3).withValues(alpha: 0.7),
                ],
                stops: const [0, 0.43, 0.76, 1],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.66),
                width: 1.2,
              ),
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.48),
                    Colors.transparent,
                    const Color(0xFF124B5F).withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final double score;
  final Animation<double> animationValue;

  const _MoodCard({required this.score, required this.animationValue});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: animationValue,
      builder: (context, child) {
        final progress = animationValue.value;
        final animatedScore = score * progress;
        final sliderValue = Tween<double>(
          begin: -1.0,
          end: score,
        ).transform(progress);
        return _SoftCard(
          padding: const EdgeInsets.fromLTRB(28, 30, 28, 23),
          child: Column(
            children: [
              Text(
                animatedScore.toStringAsFixed(2),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: const Color(0xFF124B5F),
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  height: 1,
                ),
              ),
              const SizedBox(height: 23),
              _MoodScale(value: sliderValue),
            ],
          ),
        );
      },
    );
  }
}

class _MoodScale extends StatelessWidget {
  final double value;

  const _MoodScale({required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 27,
          child: Text(
            '-1',
            style: TextStyle(
              color: Color(0xFFE6A99E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: 18,
            child: CustomPaint(
              painter: _MoodScalePainter(value: value.clamp(-1.0, 1.0)),
            ),
          ),
        ),
        const SizedBox(
          width: 27,
          child: Text(
            '1',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: Color(0xFF8FAFA9),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MoodScalePainter extends CustomPainter {
  final double value;

  const _MoodScalePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    final centerX = size.width / 2;
    final leftPaint = Paint()
      ..color = const Color(0xFFE7A89C)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rightPaint = Paint()
      ..color = const Color(0xFF92B5AD)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final dashPaint = Paint()
      ..color = const Color(0xFFD9D7D2)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(0, y), Offset(centerX - 9, y), leftPaint);
    canvas.drawLine(Offset(centerX + 9, y), Offset(size.width, y), rightPaint);

    for (var x = centerX - 8; x < centerX + 18; x += 6) {
      canvas.drawLine(Offset(x, y), Offset(x + 1.5, y), dashPaint);
    }

    final markerX = ((value + 1) / 2) * size.width;
    canvas.drawCircle(
      Offset(markerX, y),
      6,
      Paint()..color = const Color(0xFFFFFEFC),
    );
    canvas.drawCircle(
      Offset(markerX, y),
      4.4,
      Paint()..color = const Color(0xFF2E6770),
    );
  }

  @override
  bool shouldRepaint(covariant _MoodScalePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

class _AnalysisCard extends StatelessWidget {
  final String text;

  const _AnalysisCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(34, 23, 34, 22),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF7A8589),
          fontSize: 14,
          fontWeight: FontWeight.w300,
          height: 1.18,
        ),
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  final String text;
  final String frequency;

  const _PatternCard({required this.text, required this.frequency});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(35, 28, 35, 23),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF124B5F),
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.17,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            frequency,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB1B4B2),
              fontSize: 12,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmotionalLayerTile extends StatelessWidget {
  final EmotionalLayerViewData layer;

  const _EmotionalLayerTile({required this.layer});

  @override
  Widget build(BuildContext context) {
    final progress = layer.value.clamp(0, 100) / 100;
    Color colorForLabel() {
      final colors = Theme.of(context).extension<AppThemeColors>()!;
      switch (layer.label.toLowerCase()) {
        case 'happy':
        case 'proud':
          return colors.accentMint;
        case 'satisfied':
        case 'calm':
          return colors.accentDeep;
        case 'anxious':
        case 'angry':
        case 'sad':
        case 'afraid':
        case 'jealous':
        case 'stress':
        default:
          return colors.accentPeach;
      }
    }

    final color = colorForLabel();

    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(15, 13, 15, 13),
      child: Row(
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 13),
          SizedBox(
            width: 68,
            child: Text(
              AppTranslations.get('emotion_${layer.label.toLowerCase()}', context.read<SettingsNotifier>().appLanguage),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF596164),
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Container(
                      height: 2.4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EEEA),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Container(
                      width: constraints.maxWidth * progress,
                      height: 2.4,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 15),
          SizedBox(
            width: 25,
            child: Text(
              '${layer.value}',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF3F474A),
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final String text;

  const _TranscriptCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return _SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFF7A8589),
          fontSize: 12,
          fontWeight: FontWeight.w300,
          height: 1.35,
        ),
      ),
    );
  }
}
