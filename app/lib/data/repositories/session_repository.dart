import 'package:hive_flutter/hive_flutter.dart';
import '../models/session.dart';

class SessionRepository {
  static const _boxName = 'sessions';

  Box get _box => Hive.box(_boxName);

  static Future<void> init() async {
    await Hive.openBox(_boxName);
  }

  List<Session> getAll() {
    return _box.values.map((v) => Session.fromJsonString(v as String)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Session? getForDate(DateTime date) {
    final raw = _box.get(Session.dateKey(date));
    if (raw != null) {
      return Session.fromJsonString(raw as String);
    }

    for (final rawValue in _box.values) {
      if (rawValue is String) {
        final session = Session.fromJsonString(rawValue);
        if (session.createdAt.year == date.year &&
            session.createdAt.month == date.month &&
            session.createdAt.day == date.day) {
          return session;
        }
      }
    }

    return null;
  }

  Future<void> upsert(Session session) async {
    await _box.put(session.id, session.toJsonString());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
