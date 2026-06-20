import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/notifiers/score_reminder_notifier.dart';

class ScoreReminderSettingsScreen extends StatelessWidget {
  const ScoreReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 27, 22, 18),
          child: Consumer<ScoreReminderNotifier>(
            builder: (context, notifier, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'IvyMental',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w200,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(shape: BoxShape.circle),
                          child: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.5), size: 20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Section label
                  Text(
                    'SCORE REMINDER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card 1: Threshold slider
                  _Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notify below',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${notifier.threshold}',
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.w300,
                                color: colorScheme.onSurface,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '/ 100',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: colorScheme.onSurface,
                            inactiveTrackColor: colorScheme.onSurface.withOpacity(0.15),
                            thumbColor: colorScheme.onSurface,
                            overlayColor: colorScheme.onSurface.withOpacity(0.08),
                            trackHeight: 2,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: notifier.threshold.toDouble(),
                            min: 0,
                            max: 100,
                            divisions: 100,
                            onChanged: (v) => notifier.setThreshold(v.round()),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('0', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.4))),
                              Text('50', style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.4))),
                              Text(
                                '100',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.4)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Card 2: Active toggle
                  _Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                        ),
                        Switch(
                          value: notifier.isActive,
                          onChanged: notifier.setActive,
                          activeThumbColor: colorScheme.secondary,
                          activeTrackColor: colorScheme.secondary.withOpacity(0.5),
                          inactiveThumbColor: colorScheme.onSurface.withOpacity(0.3),
                          inactiveTrackColor: colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Description text
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Be aware of your overall mental score',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        const TextSpan(text: ' — check your evaluation and take better care of yourself.'),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Footer
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: colorScheme.onSurface.withOpacity(0.3)),
                        const SizedBox(width: 6),
                        Text(
                          'On-device analysis',
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withOpacity(0.3),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}
