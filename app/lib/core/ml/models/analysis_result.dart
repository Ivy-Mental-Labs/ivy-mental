class AnalysisResult {
  final double mood;
  final Map<String, double> emotions;

  const AnalysisResult({
    required this.mood,
    required this.emotions,
  });

  @override
  String toString() => 'AnalysisResult(mood: $mood, emotions: $emotions)';
}
