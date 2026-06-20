import 'package:flutter/material.dart';

import '../../shared/widgets/ivy_visuals.dart';
import '../../theme.dart';
import '../history/history_screen.dart';
import 'evaluation_screen.dart';

class OverviewPagerScreen extends StatefulWidget {
  const OverviewPagerScreen({super.key});

  @override
  State<OverviewPagerScreen> createState() => _OverviewPagerScreenState();
}

class _OverviewPagerScreenState extends State<OverviewPagerScreen> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundPrimary,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: const [EvaluationScreen(), HistoryScreen()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Column(
                children: [
                  PageIndicator(currentIndex: _currentPage),
                  const SizedBox(height: AppSpacing.lg),
                  const PrivacyHint(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
