import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/notifications/notification_service.dart';
import '../models/session.dart';
import '../repositories/session_repository.dart';

class SessionNotifier extends ChangeNotifier {
  final SessionRepository _repo;

  SessionNotifier(this._repo) {
    _sessions = _repo.getAll();
  }

  List<Session> _sessions = [];

  List<Session> get sessions => List.unmodifiable(_sessions);

  Future<void> upsert(Session session) async {
    await _repo.upsert(session);
    _sessions = _repo.getAll();
    notifyListeners();
  }

  Future<void> updateTranscript(String id, String transcript) async {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    await _repo.upsert(_sessions[idx].withTranscript(transcript));
    _sessions = _repo.getAll();
    notifyListeners();
  }

  Future<void> updateEvaluation(String id, Map<String, dynamic> evaluation) async {
    final idx = _sessions.indexWhere((s) => s.id == id);
    if (idx == -1) return;
    await _repo.upsert(_sessions[idx].withEvaluation(evaluation));
    _sessions = _repo.getAll();
    notifyListeners();
    await _reschedule();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _sessions = _repo.getAll();
    notifyListeners();
  }

  Future<void> _reschedule() async {
    try {
      final box = Hive.box('settings');
      final isActive = box.get('isActive', defaultValue: true) as bool;
      final hour = box.get('notificationHour', defaultValue: 20) as int;
      final minute = box.get('notificationMinute', defaultValue: 0) as int;
      final isScoreActive = box.get('isScoreActive', defaultValue: true) as bool;
      final threshold = box.get('threshold', defaultValue: 45) as int;

      final weeklyAverageScore = NotificationService.calculateWeeklyAverageScore(_sessions);
      await NotificationService.updateSchedule(
        isActive: isActive,
        hour: hour,
        minute: minute,
        isScoreActive: isScoreActive,
        threshold: threshold,
        weeklyAverageScore: weeklyAverageScore,
      );
    } catch (_) {

    }
  }
}
