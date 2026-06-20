import '../models/analysis_result.dart';

abstract class TextAnalyzer {
  Future<void> load();
  Future<AnalysisResult> analyze(String text);
  void dispose();
}
