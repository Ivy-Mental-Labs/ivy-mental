class WeeklyEvaluation {
  final DateTime weekStart;
  final double overallScore;
  final double calmScore;
  final double energyScore;
  final double stressScore;
  final int sessionCount;

  const WeeklyEvaluation({
    required this.weekStart,
    required this.overallScore,
    required this.calmScore,
    required this.energyScore,
    required this.stressScore,
    required this.sessionCount,
  });
}
