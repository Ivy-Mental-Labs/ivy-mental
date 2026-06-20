import 'package:flutter/material.dart';
import 'theme.dart';
import 'core/ml/services/text_analyzer.dart';
import 'core/ml/services/onnx_text_analyzer.dart';
import 'features/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final analyzer = OnnxTextAnalyzer();
  await analyzer.load();

  runApp(MainApp(analyzer: analyzer));
}

class MainApp extends StatelessWidget {
  final TextAnalyzer analyzer;

  const MainApp({required this.analyzer, super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: appTheme,
      home: MainNavigationScreen(analyzer: analyzer),
    );
  }
}
