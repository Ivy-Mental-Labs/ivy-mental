import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifications/notification_service.dart';
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
              return ListView(
                children: [
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

                  _Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Active',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                        ),
                        Switch(
                          value: notifier.isScoreActive,
                          onChanged: notifier.setScoreActive,
                          activeThumbColor: colorScheme.secondary,
                          activeTrackColor: colorScheme.secondary.withOpacity(0.5),
                          inactiveThumbColor: colorScheme.onSurface.withOpacity(0.3),
                          inactiveTrackColor: colorScheme.onSurface.withOpacity(0.1),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Opacity(
                    opacity: notifier.isScoreActive ? 1.0 : 0.4,
                    child: IgnorePointer(
                      ignoring: !notifier.isScoreActive,
                      child: _Card(
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
                                  Text(
                                    '0',
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.4)),
                                  ),
                                  Text(
                                    '50',
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.4)),
                                  ),
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
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'DAILY REMINDER',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),

                  const SizedBox(height: 12),

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

                  const SizedBox(height: 12),

                  Opacity(
                    opacity: notifier.isActive ? 1.0 : 0.4,
                    child: _Card(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Notification Time',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Set when to receive your daily check-in reminder',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    color: colorScheme.onSurface.withOpacity(0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: notifier.isActive
                                ? () async {
                                    final TimeOfDay? picked = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay(
                                        hour: notifier.notificationHour,
                                        minute: notifier.notificationMinute,
                                      ),
                                    );
                                    if (picked != null) {
                                      await notifier.setNotificationTime(picked.hour, picked.minute);
                                    }
                                  }
                                : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${notifier.notificationHour.toString().padLeft(2, '0')}:${notifier.notificationMinute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: notifier.isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'DEVELOPER TOOLS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Test Notification',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Send an immediate reminder notification',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                  color: colorScheme.onSurface.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: () async {
                            await NotificationService.triggerTestNotification();
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.secondary,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            backgroundColor: colorScheme.secondary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Trigger', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: colorScheme.onSurface.withOpacity(0.6),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'Be aware of your overall mental score\n',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        const TextSpan(text: 'Check your evaluation and take care of yourself.'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

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
