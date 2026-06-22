class HistoryEntry {
  final String sessionId;
  final DateTime date;
  final String title;
  final int iconIndex;

  const HistoryEntry({
    required this.sessionId,
    required this.date,
    required this.title,
    required this.iconIndex,
  });
}
