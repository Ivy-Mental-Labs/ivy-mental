import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/session.dart';
import '../../data/repositories/session_repository.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'daily_diary_reminder';
  static const String _channelName = 'Daily Diary Reminder';
  static const String _channelDesc =
      'Reminds you in the evening about your diary';

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Berlin'));
    } catch (error) {
      debugPrint('Failed to set notification timezone: $error');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(settings: initializationSettings);
  }

  static Future<bool> requestPermissions() async {
    if (Platform.isIOS) {
      return await _notificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >()
              ?.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }

    if (Platform.isAndroid) {
      final androidImplementation = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final enabledBefore =
          await androidImplementation?.areNotificationsEnabled() ?? false;
      if (enabledBefore) return true;

      final granted =
          await androidImplementation?.requestNotificationsPermission() ??
          false;
      final enabledAfter =
          await androidImplementation?.areNotificationsEnabled() ?? granted;
      debugPrint('Android notification permission granted: $enabledAfter');
      return enabledAfter;
    }

    return true;
  }

  static double? calculateWeeklyAverageScore(List<Session> sessions) {
    final now = DateTime.now();
    final startOf7DaysAgo = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));

    final recentMoods = sessions
        .where((s) {
          if (s.evaluation == null || s.evaluation!['mood'] is! num) {
            return false;
          }
          DateTime sessionDate;
          try {
            sessionDate = DateTime.parse(s.id);
          } catch (_) {
            sessionDate = s.createdAt;
          }
          final dateOnly = DateTime(
            sessionDate.year,
            sessionDate.month,
            sessionDate.day,
          );
          return !dateOnly.isBefore(startOf7DaysAgo);
        })
        .map((s) => (s.evaluation!['mood'] as num).toDouble())
        .toList();

    if (recentMoods.isEmpty) return null;
    final averageMood =
        recentMoods.reduce((a, b) => a + b) / recentMoods.length;
    return ((averageMood + 1) / 2) * 100;
  }

  static Future<void> updateSchedule({
    required bool isActive,
    required int hour,
    required int minute,
    required bool isScoreActive,
    required int threshold,
    required double? weeklyAverageScore,
  }) async {
    await _notificationsPlugin.cancel(id: 0);

    if (!isActive) {
      debugPrint('Notifications disabled. Canceled existing schedule.');
      return;
    }

    final permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      debugPrint(
        'Daily reminder not scheduled: notification permission denied.',
      );
      return;
    }

    String title = 'Diary Time!';
    String body = "Take a moment for today's entry.";

    if (isScoreActive && weeklyAverageScore != null) {
      final intScore = weeklyAverageScore.round();
      if (intScore < threshold) {
        title = 'Mental Health Alert';
        body =
            'Your average score this week is low ($intScore/100). Please take care of yourself and consider seeking help.';
      }
    }

    final scheduledDate = _nextInstanceOfTime(hour, minute);
    debugPrint(
      "Scheduling daily notification for ${scheduledDate.toLocal()} via ${tz.local.name}. Title: '$title', Body: '$body'",
    );

    await _notificationsPlugin.zonedSchedule(
      id: 0,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    final pending = await _notificationsPlugin.pendingNotificationRequests();
    debugPrint('Pending notifications after scheduling: ${pending.length}');
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> triggerTestNotification() async {
    final permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      debugPrint(
        'Test notification not shown: notification permission denied.',
      );
      return;
    }

    final box = Hive.box('settings');
    final isScoreActive = box.get('isScoreActive', defaultValue: true) as bool;
    final threshold = box.get('threshold', defaultValue: 45) as int;

    final sessions = SessionRepository().getAll();
    final weeklyAverageScore = calculateWeeklyAverageScore(sessions);

    String title = 'Test Notification';
    String body = 'This is a test! Notifications are working.';

    if (isScoreActive &&
        weeklyAverageScore != null &&
        weeklyAverageScore.round() < threshold) {
      final intScore = weeklyAverageScore.round();
      title = 'Mental Health Alert';
      body =
          'Your average score this week is low ($intScore/100). Please take care of yourself and consider seeking help.';
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'test_channel',
          'Test Notification',
          channelDescription: 'Channel for testing',
          importance: Importance.max,
          priority: Priority.high,
        );
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _notificationsPlugin.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
