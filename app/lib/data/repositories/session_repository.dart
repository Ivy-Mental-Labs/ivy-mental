import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';

class SessionRepository {
  static const _boxName = 'sessions';

  Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  List<Session> getAll() {
    return _box.values
        .map((v) => Session.fromJsonString(v as String))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Session? getForDate(DateTime date) {
    final raw = _box.get(Session.dateKey(date));
    return raw != null ? Session.fromJsonString(raw as String) : null;
  }

  Future<void> upsert(Session session) async {
    await _box.put(session.id, session.toJsonString());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
