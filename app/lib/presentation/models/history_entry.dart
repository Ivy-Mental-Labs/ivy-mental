class HistoryEntry {
  final String sessionId;
  final DateTime date;
  final String title;
  final int iconIndex; // 0–7

  const HistoryEntry({
    required this.sessionId,
    required this.date,
    required this.title,
    required this.iconIndex,
  });
}
