import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/session.dart';
import '../../data/notifiers/session_notifier.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const String routeName = '/history';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Consumer<SessionNotifier>(
        builder: (context, notifier, _) {
          final sessions = notifier.sessions;
          if (sessions.isEmpty) {
            return const Center(child: Text('No entries yet'));
          }
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) => _SessionListItem(
              session: sessions[index],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SessionDetailScreen(
                    session: sessions[index],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SessionListItem extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;

  const _SessionListItem({required this.session, required this.onTap});

  Color _moodColor() {
    final mood = session.evaluation?['mood'] as double?;
    if (mood == null) return Colors.grey;
    if (mood >= 0.3) return Colors.green;
    if (mood <= -0.3) return Colors.red;
    return Colors.amber;
  }

  static const _months = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  String _formattedDate() {
    final d = session.createdAt;
    return '${d.day} ${_months[d.month]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(_formattedDate()),
        subtitle: session.transcript != null
            ? Text(
                session.transcript!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: _moodColor(),
            shape: BoxShape.circle,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class SessionDetailScreen extends StatelessWidget {
  final Session session;

  const SessionDetailScreen({required this.session, super.key});

  @override
  Widget build(BuildContext context) {
    final mood = session.evaluation?['mood'] as double?;
    final emotions = session.evaluation?['emotions'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${session.createdAt.day}.${session.createdAt.month}.${session.createdAt.year}',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            if (session.transcript != null) ...[
              Text('Transcript',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(session.transcript!),
                ),
              ),
              const SizedBox(height: 24),
            ],
            if (mood != null) ...[
              _MoodIndicator(mood: mood),
              const SizedBox(height: 24),
            ],
            if (emotions != null && emotions.isNotEmpty) ...[
              Text('Emotions',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: emotions.entries.map((e) {
                      final value = (e.value as num).toDouble();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(e.key),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 12,
                                  backgroundColor: Colors.grey.shade200,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 48,
                              child: Text(
                                (value * 100).toStringAsFixed(0),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoodIndicator extends StatelessWidget {
  final double mood;

  const _MoodIndicator({required this.mood});

  Color _moodColor() {
    if (mood >= 0.3) return Colors.green;
    if (mood <= -0.3) return Colors.red;
    return Colors.amber;
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
