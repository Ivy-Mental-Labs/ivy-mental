import 'package:flutter/material.dart';
import '../../core/ml/models/analysis_result.dart';
import '../../core/ml/services/text_analyzer.dart';

class EvaluationScreen extends StatefulWidget {
  final TextAnalyzer analyzer;

  const EvaluationScreen({required this.analyzer, super.key});

  static const String routeName = '/evaluation';

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final _controller = TextEditingController();
  AnalysisResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final result = await widget.analyzer.analyze(text);
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analysis failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Evaluation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter text to analyze',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _analyze,
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Analyze'),
            ),
            if (_result != null) ...[
              const SizedBox(height: 24),
              _MoodCard(mood: _result!.mood),
              const SizedBox(height: 16),
              _EmotionsCard(emotions: _result!.emotions),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final double mood;

  const _MoodCard({required this.mood});

  Color _moodColor() {
    if (mood >= 0.3) return Colors.green;
    if (mood <= -0.3) return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text('Mood', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _moodColor().withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                mood.toStringAsFixed(2),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _moodColor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmotionsCard extends StatelessWidget {
  final Map<String, double> emotions;

  const _EmotionsCard({required this.emotions});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emotions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...emotions.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        e.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: e.value,
                          minHeight: 12,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        (e.value * 100).toStringAsFixed(0),
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
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
