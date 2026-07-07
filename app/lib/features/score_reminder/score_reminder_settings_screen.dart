import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../data/notifiers/settings_notifier.dart';
import '../../core/localization/app_translations.dart';

class ScoreReminderSettingsScreen extends StatelessWidget {
  const ScoreReminderSettingsScreen({super.key});

  Future<void> _showLanguageChangeConfirmation(
    BuildContext context,
    SettingsNotifier settings,
    String targetLang,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppTranslations.get('model_download_warning_title', settings.appLanguage)),
        content: Text(AppTranslations.get('model_download_warning_desc', settings.appLanguage)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppTranslations.get('cancel', settings.appLanguage)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppTranslations.get('delete', settings.appLanguage)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await settings.setSpeechLanguage(targetLang);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 27, 22, 18),
          child: Consumer<SettingsNotifier>(
            builder: (context, notifier, _) {
              final lang = notifier.appLanguage;

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
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(shape: BoxShape.circle),
                          child: Icon(Icons.close, color: colorScheme.onSurface.withValues(alpha: 0.5), size: 20),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Text(
                    AppTranslations.get('score_reminder_title', lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.get('active', lang),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                        ),
                        Switch(
                          value: notifier.isScoreActive,
                          onChanged: notifier.setScoreActive,
                          activeThumbColor: colorScheme.secondary,
                          activeTrackColor: colorScheme.secondary.withValues(alpha: 0.5),
                          inactiveThumbColor: colorScheme.onSurface.withValues(alpha: 0.3),
                          inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.1),
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
                              AppTranslations.get('notify_below', lang),
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
                                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderThemeData(
                                activeTrackColor: colorScheme.onSurface,
                                inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.15),
                                thumbColor: colorScheme.onSurface,
                                overlayColor: colorScheme.onSurface.withValues(alpha: 0.08),
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
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                                  ),
                                  Text(
                                    '50',
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
                                  ),
                                  Text(
                                    '100',
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withValues(alpha: 0.4)),
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
                    AppTranslations.get('daily_reminder_title', lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _Card(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppTranslations.get('active', lang),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                        ),
                        Switch(
                          value: notifier.isActive,
                          onChanged: notifier.setActive,
                          activeThumbColor: colorScheme.secondary,
                          activeTrackColor: colorScheme.secondary.withValues(alpha: 0.5),
                          inactiveThumbColor: colorScheme.onSurface.withValues(alpha: 0.3),
                          inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.1),
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
                                  AppTranslations.get('notification_time', lang),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppTranslations.get('notification_time_desc', lang),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                                color: colorScheme.onSurface.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${notifier.notificationHour.toString().padLeft(2, '0')}:${notifier.notificationMinute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: notifier.isActive
                                      ? colorScheme.primary
                                      : colorScheme.onSurface.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Language & Model section
                  Text(
                    lang == 'de' ? 'SPRACHE & MODELL' : 'LANGUAGE & SPEECH MODEL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _Card(
                    child: Column(
                      children: [
                        // App language selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.get('app_lang', lang),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppTranslations.get('app_lang_desc', lang),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 150,
                              child: LanguageSelector(
                                selectedValue: notifier.appLanguage,
                                onChanged: (newLang) => notifier.setAppLanguage(newLang),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        Divider(color: colorScheme.onSurface.withValues(alpha: 0.08), height: 1),
                        const SizedBox(height: 18),

                        // Speech language / model selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppTranslations.get('speech_recognition_lang', lang),
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: colorScheme.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppTranslations.get('speech_recognition_lang_desc', lang),
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: colorScheme.onSurface.withValues(alpha: 0.5)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 150,
                              child: LanguageSelector(
                                selectedValue: notifier.speechLanguage,
                                onChanged: (newLang) {
                                  if (newLang != notifier.speechLanguage) {
                                    _showLanguageChangeConfirmation(context, notifier, newLang);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Model downloading / status banner
                        GestureDetector(
                          onTap: (!notifier.isModelReady && !notifier.isDownloadingModel)
                              ? () => notifier.downloadSpeechModel()
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: notifier.isModelReady
                                  ? Colors.green.withValues(alpha: 0.06)
                                  : notifier.isDownloadingModel
                                      ? colorScheme.secondary.withValues(alpha: 0.06)
                                      : colorScheme.error.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: notifier.isModelReady
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : notifier.isDownloadingModel
                                        ? colorScheme.secondary.withValues(alpha: 0.12)
                                        : colorScheme.error.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (notifier.isDownloadingModel)
                                  SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1.5,
                                      color: colorScheme.secondary,
                                    ),
                                  )
                                else
                                  Icon(
                                    notifier.isModelReady ? Icons.check_circle_outline : Icons.error_outline,
                                    size: 16,
                                    color: notifier.isModelReady
                                        ? Colors.green
                                        : notifier.isDownloadingModel
                                            ? colorScheme.secondary
                                            : colorScheme.error,
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    notifier.isDownloadingModel
                                        ? AppTranslations.get('model_status_downloading', lang)
                                        : notifier.isModelReady
                                            ? AppTranslations.get('model_status_loaded', lang)
                                            : AppTranslations.get('model_status_not_downloaded', lang),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: notifier.isModelReady
                                          ? Colors.green[700]
                                          : notifier.isDownloadingModel
                                              ? colorScheme.secondary
                                              : colorScheme.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    AppTranslations.get('developer_tools', lang),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.2,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
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
                                AppTranslations.get('test_notification', lang),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                AppTranslations.get('test_notification_desc', lang),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
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
                            backgroundColor: colorScheme.secondary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            AppTranslations.get('trigger', lang),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
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
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: AppTranslations.get('settings_footer_highlight', lang),
                          style: TextStyle(color: colorScheme.primary),
                        ),
                        TextSpan(text: AppTranslations.get('settings_footer_body', lang)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline, size: 14, color: colorScheme.onSurface.withValues(alpha: 0.3)),
                        const SizedBox(width: 6),
                        Text(
                          AppTranslations.get('on_device_analysis', lang),
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurface.withValues(alpha: 0.3),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class LanguageSelector extends StatelessWidget {
  final String selectedValue;
  final ValueChanged<String> onChanged;

  const LanguageSelector({
    required this.selectedValue,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEn = selectedValue == 'en';

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            alignment: isEn ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged('en'),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'English',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isEn ? FontWeight.w600 : FontWeight.w400,
                        color: isEn ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => onChanged('de'),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Text(
                      'Deutsch',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: !isEn ? FontWeight.w600 : FontWeight.w400,
                        color: !isEn ? colorScheme.primary : colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
