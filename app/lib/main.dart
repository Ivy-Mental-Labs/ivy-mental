import 'dart:io';
import 'package:app/recording/audio_recording_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'theme.dart';
import 'core/ml/services/text_analyzer.dart';
import 'core/ml/services/onnx_text_analyzer.dart';
import 'core/ml/services/text_analyzer.dart';
import 'data/notifiers/session_notifier.dart';
import 'data/repositories/session_repository.dart';
import 'features/main_navigation_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Test variables for language/text
String notificationTitle = "Diary Time!";
String notificationBody = "Take a moment for today's entry.";

Future<void> initNotifications() async {
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Europe/Berlin'));

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings initializationSettingsIOS =
      DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    iOS: initializationSettingsIOS,
  );

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
}

Future<void> requestNotificationPermissions() async {
  if (Platform.isIOS) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  } else if (Platform.isAndroid) {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidImplementation?.requestNotificationsPermission();
  }
}

Future<void> scheduleDailyEveningNotification() async {
  // Set the time to 20:00 (8 PM)
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    notificationTitle,
    notificationBody,
    _nextInstanceOfTime(20, 0),
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'daily_diary_reminder',
        'Daily Diary Reminder',
        channelDescription: 'Reminds you in the evening about your diary',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    matchDateTimeComponents: DateTimeComponents.time,
  );
}

tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
  final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
  tz.TZDateTime scheduledDate = tz.TZDateTime(
    tz.local,
    now.year,
    now.month,
    now.day,
    hour,
    minute,
  );
  if (scheduledDate.isBefore(now)) {
    scheduledDate = scheduledDate.add(const Duration(days: 1));
  }
  return scheduledDate;
}

Future<void> triggerTestNotification() async {
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
  await flutterLocalNotificationsPlugin.show(
    1,
    'Test Notification',
    'This is a test! Notifications are working.',
    notificationDetails,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SessionRepository.init();

  // Notification Setup
  await initNotifications();
  await requestNotificationPermissions();
  await scheduleDailyEveningNotification();

  // Test notification: triggers 3 seconds after app start
  Future.delayed(const Duration(seconds: 3), () {
    triggerTestNotification();
  });

  final analyzer = OnnxTextAnalyzer();
  await analyzer.load();
  runApp(MainApp(analyzer: analyzer));
}

class MainApp extends StatelessWidget {
  final TextAnalyzer analyzer;

  const MainApp({required this.analyzer, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionNotifier(SessionRepository()),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: MainNavigationScreen(analyzer: analyzer),
      ),
    );
  }
}
