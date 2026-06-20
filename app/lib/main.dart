import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'features/audio_recording/audio_recording_screen.dart';
import 'features/evaluation/evaluation_screen.dart';
import 'features/history/history_screen.dart';
import 'data/repositories/session_repository.dart';
import 'data/notifiers/session_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await SessionRepository.init();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SessionNotifier(SessionRepository()),
      child: MaterialApp(
        theme: appTheme,
        initialRoute: AudioRecordingScreen.routeName,
        routes: {
          AudioRecordingScreen.routeName: (_) => const AudioRecordingScreen(),
          EvaluationScreen.routeName: (_) => const EvaluationScreen(),
          HistoryScreen.routeName: (_) => const HistoryScreen(),
        },
      ),
    );
  }
}
