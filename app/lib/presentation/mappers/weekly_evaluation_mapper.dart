import '../../data/models/session.dart';
import '../models/weekly_evaluation.dart';

class WeeklyEvaluationMapper {
  const WeeklyEvaluationMapper();

  WeeklyEvaluation mapWeek(List<Session> sessions, DateTime weekStart) {
    final complete = sessions
        .where((s) => s.status == SessionStatus.complete)
        .toList();
    return WeeklyEvaluation(
      weekStart: weekStart,
      overallScore: _avg(complete, _overallScore),
      calmScore: _avg(complete, _calmScore),
      energyScore: _avg(complete, _energyScore),
      stressScore: _avg(complete, _stressScore),
      sessionCount: complete.length,
    );
  }

  List<WeeklyEvaluation> mapAllWeeks(List<Session> allSessions) {
    final byWeek = <DateTime, List<Session>>{};
    for (final s in allSessions) {
      final ws = weekStart(s.createdAt);
      byWeek.putIfAbsent(ws, () => []).add(s);
    }
    return byWeek.entries
        .map((e) => mapWeek(e.value, e.key))
        .toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
  }

  /// Gibt den Montag der Woche zurück, zu der [date] gehört (ISO).
  DateTime weekStart(DateTime date) =>
      DateTime(date.year, date.month, date.day - (date.weekday - 1));

  double _e(Map<String, dynamic>? eval, String key) =>
      ((eval?['emotions'] as Map?)?[key] as num?)?.toDouble() ?? 0.0;

  double _overallScore(Map<String, dynamic>? eval) {
    final mood = (eval?['mood'] as num?)?.toDouble() ?? 0.0;
    return ((mood + 1) / 2 * 100).clamp(0.0, 100.0);
  }

  double _calmScore(Map<String, dynamic>? eval) =>
      ((1 - (_e(eval, 'anxious') + _e(eval, 'angry') + _e(eval, 'afraid')) / 3) * 100)
          .clamp(0.0, 100.0);

  double _energyScore(Map<String, dynamic>? eval) =>
      ((_e(eval, 'happy') + _e(eval, 'proud') + _e(eval, 'satisfied')) / 3 * 100)
          .clamp(0.0, 100.0);

  double _stressScore(Map<String, dynamic>? eval) =>
      ((_e(eval, 'anxious') + _e(eval, 'angry') + _e(eval, 'afraid')) / 3 * 100)
          .clamp(0.0, 100.0);

  double _avg(
    List<Session> sessions,
    double Function(Map<String, dynamic>?) fn,
  ) {
    if (sessions.isEmpty) return 0;
    return sessions.map((s) => fn(s.evaluation)).reduce((a, b) => a + b) /
        sessions.length;
  }
}
