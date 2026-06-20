import 'package:flutter/foundation.dart';
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
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    _sessions = _repo.getAll();
    notifyListeners();
  }
}
