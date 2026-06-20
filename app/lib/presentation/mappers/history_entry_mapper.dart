import 'dart:math';

import '../../data/models/session.dart';
import '../models/history_entry.dart';

class HistoryEntryMapper {
  const HistoryEntryMapper();

  HistoryEntry map(Session session) => HistoryEntry(
        sessionId: session.id,
        date: session.createdAt,
        title: _title(session.transcript),
        iconIndex: _iconIndex(session.evaluation),
      );

  // Anpassungspunkt: erste 10 Zeichen → später evaluation['summary'] oder LLM
  String _title(String? transcript) {
    final text = transcript ?? '';
    return text.substring(0, text.length.clamp(0, 10));
  }

  // Anpassungspunkt: random 0–7 → später aus evaluation-JSON berechnen
  int _iconIndex(Map<String, dynamic>? evaluation) {
    return Random().nextInt(8);
  }
}
