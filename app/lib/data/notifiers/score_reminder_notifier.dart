import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/notifications/notification_service.dart';
import '../repositories/session_repository.dart';

class ScoreReminderNotifier extends ChangeNotifier {
  static const _boxName = 'settings';

  int _threshold = 45;
  bool _isActive = true;
  int _notificationHour = 20;
  int _notificationMinute = 0;
  bool _isScoreActive = true;

  ScoreReminderNotifier() {
    final box = Hive.box(_boxName);
    _threshold = box.get('threshold', defaultValue: 45) as int;
    _isActive = box.get('isActive', defaultValue: true) as bool;
    _notificationHour = box.get('notificationHour', defaultValue: 20) as int;
    _notificationMinute = box.get('notificationMinute', defaultValue: 0) as int;
    _isScoreActive = box.get('isScoreActive', defaultValue: true) as bool;
  }

  int get threshold => _threshold;
  bool get isActive => _isActive;
  int get notificationHour => _notificationHour;
  int get notificationMinute => _notificationMinute;
  bool get isScoreActive => _isScoreActive;

  Future<void> setThreshold(int value) async {
    _threshold = value;
    final box = Hive.box(_boxName);
    await box.put('threshold', value);
    notifyListeners();
    await _reschedule();
  }

  Future<void> setActive(bool value) async {
    _isActive = value;
    final box = Hive.box(_boxName);
    await box.put('isActive', value);
    notifyListeners();
    await _reschedule();
  }

  Future<void> setNotificationTime(int hour, int minute) async {
    _notificationHour = hour;
    _notificationMinute = minute;
    final box = Hive.box(_boxName);
    await box.put('notificationHour', hour);
    await box.put('notificationMinute', minute);
    notifyListeners();
    await _reschedule();
  }

  Future<void> setScoreActive(bool value) async {
    _isScoreActive = value;
    final box = Hive.box(_boxName);
    await box.put('isScoreActive', value);
    notifyListeners();
    await _reschedule();
  }

  Future<void> _reschedule() async {
    try {
      final sessions = SessionRepository().getAll();
      final score = NotificationService.calculateWeeklyAverageScore(sessions);
      await NotificationService.updateSchedule(
        isActive: _isActive,
        hour: _notificationHour,
        minute: _notificationMinute,
        isScoreActive: _isScoreActive,
        threshold: _threshold,
        weeklyAverageScore: score,
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to reschedule score reminder: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
