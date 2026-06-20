import '../../data/models/session.dart';
import '../models/history_entry.dart';

class HistoryEntryMapper {
  const HistoryEntryMapper();

  static const _emotionOrder = [
    'happy', 'sad', 'satisfied', 'proud', 'anxious', 'angry', 'afraid', 'jealous',
  ];

  HistoryEntry map(Session session) => HistoryEntry(
        sessionId: session.id,
        date: session.createdAt,
        title: _title(session.transcript),
        iconIndex: _iconIndex(session.evaluation),
      );

  String _title(String? transcript) {
    final text = transcript?.trim() ?? '';
    if (text.isEmpty) return '';
    final sentenceEnd = text.indexOf(RegExp(r'[.!?]'));
    final candidate = sentenceEnd >= 0 ? text.substring(0, sentenceEnd) : text;
    if (candidate.length <= 50) return candidate.trim();
    final cut = candidate.lastIndexOf(' ', 50);
    return '${candidate.substring(0, cut > 0 ? cut : 50).trim()}…';
  }

  int _iconIndex(Map<String, dynamic>? evaluation) {
    final emotions = (evaluation?['emotions'] as Map?)?.cast<String, num>();
    if (emotions == null || emotions.isEmpty) {
      final mood = (evaluation?['mood'] as num?)?.toDouble() ?? 0.0;
      return mood >= 0 ? 0 : 1;
    }
    var maxVal = -1.0;
    var maxIdx = 0;
    for (var i = 0; i < _emotionOrder.length; i++) {
      final v = (emotions[_emotionOrder[i]] ?? 0).toDouble();
      if (v > maxVal) {
        maxVal = v;
        maxIdx = i;
      }
    }
    return maxIdx;
  }
}
