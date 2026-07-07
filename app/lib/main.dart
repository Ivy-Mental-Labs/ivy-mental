import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'core/ml/services/onnx_text_analyzer.dart';
import 'core/ml/services/text_analyzer.dart';
import 'core/notifications/notification_service.dart';
import 'data/notifiers/session_notifier.dart';
import 'data/notifiers/settings_notifier.dart';
// import 'data/mock_data_seeder.dart';
import 'data/repositories/session_repository.dart';
import 'features/main_navigation_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SessionRepository.init();
  // await MockDataSeeder.seedIfEmpty(SessionRepository());
  await Hive.openBox('settings');

  await NotificationService.init();
  await NotificationService.requestPermissions();


  final box = Hive.box('settings');
  final isActive = box.get('isActive', defaultValue: true) as bool;
  final hour = box.get('notificationHour', defaultValue: 20) as int;
  final minute = box.get('notificationMinute', defaultValue: 0) as int;
  final isScoreActive = box.get('isScoreActive', defaultValue: true) as bool;
  final threshold = box.get('threshold', defaultValue: 45) as int;

  final sessions = SessionRepository().getAll();
  final weeklyAverageScore = NotificationService.calculateWeeklyAverageScore(sessions);

  await NotificationService.updateSchedule(
    isActive: isActive,
    hour: hour,
    minute: minute,
    isScoreActive: isScoreActive,
    threshold: threshold,
    weeklyAverageScore: weeklyAverageScore,
  );

  final analyzer = OnnxTextAnalyzer();
  await analyzer.load();
  runApp(MainApp(analyzer: analyzer));
}

class MainApp extends StatelessWidget {
  final TextAnalyzer analyzer;

  const MainApp({required this.analyzer, super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SessionNotifier(SessionRepository()),
        ),
        ChangeNotifierProvider(create: (_) => SettingsNotifier()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: MainNavigationScreen(analyzer: analyzer),
      ),
    );
  }
}
