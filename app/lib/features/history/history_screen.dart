import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const String routeName = '/history';

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('HistoryScreen'),
      ),
    );
  }
}
