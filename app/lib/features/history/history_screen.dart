import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/session.dart';
import '../../data/notifiers/session_notifier.dart';
import '../../shared/widgets/ivy_visuals.dart';
import '../../theme.dart';
import 'presentation/screens/history_entry_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  static const String routeName = '/history';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final sessions = context.watch<SessionNotifier>().sessions;
    final items = sessions.isEmpty
        ? _fallbackItems()
        : _itemsFromSessions(sessions);

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      child: Column(
        children: [
          IvyHeader(
            trailing: _OverviewOrbButton(
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(height: 52),
          Text(
            'Your experiences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: colors.textSecondary,
              fontSize: 18,
              fontWeight: FontWeight.w200,
            ),
          ),
          const SizedBox(height: 42),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = items[index];
                return ExperienceCard(
                  item: item,
                  onTap: item.session == null
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                HistoryEntryScreen(session: item.session!),
                          ),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<ExperienceItem> _itemsFromSessions(List<Session> sessions) {
    return sessions.take(8).map((session) {
      final mood = (session.evaluation?['mood'] as num?)?.toDouble() ?? 0;
      return ExperienceItem(
        meta:
            '${_relativeDate(session.createdAt)} - ${_durationFor(session)} min',
        title: _snippet(session.transcript),
        variant: mood >= 0.2
            ? MoodOrbVariant.mint
            : mood <= -0.2
            ? MoodOrbVariant.peach
            : MoodOrbVariant.deep,
        session: session,
      );
    }).toList();
  }

  List<ExperienceItem> _fallbackItems() {
    return const [
      ExperienceItem(
        meta: 'Today - 7 min',
        title: 'A little tired from a hard day...',
        variant: MoodOrbVariant.peach,
      ),
      ExperienceItem(
        meta: 'Yesterday - 3 min',
        title: 'Awesome day, awesome we...',
        variant: MoodOrbVariant.mint,
      ),
      ExperienceItem(
        meta: 'Yesterday - 3 min',
        title: 'Awesome day, awesome we...',
        variant: MoodOrbVariant.peach,
      ),
      ExperienceItem(
        meta: 'Yesterday - 3 min',
        title: 'Awesome day, awesome we...',
        variant: MoodOrbVariant.peach,
      ),
      ExperienceItem(
        meta: 'Yesterday - 3 min',
        title: 'Awesome day, awesome we...',
        variant: MoodOrbVariant.peach,
      ),
    ];
  }

  String _relativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${date.day}.${date.month}.${date.year}';
  }

  int _durationFor(Session session) {
    final words = session.transcript?.trim().split(RegExp(r'\s+')).length ?? 45;
    return (words / 26).clamp(1, 9).round();
  }

  String _snippet(String? transcript) {
    final text = transcript?.trim();
    if (text == null || text.isEmpty) {
      return 'A quiet check-in with IvyMental...';
    }
    if (text.length <= 30) {
      return text;
    }
    return '${text.substring(0, 30)}...';
  }
}

class _OverviewOrbButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OverviewOrbButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: const SizedBox(
        width: 48,
        height: 48,
        child: Center(child: MoodOrb(size: 45, variant: MoodOrbVariant.deep)),
      ),
    );
  }
}

class ExperienceItem {
  final String meta;
  final String title;
  final MoodOrbVariant variant;
  final Session? session;

  const ExperienceItem({
    required this.meta,
    required this.title,
    required this.variant,
    this.session,
  });
}

class ExperienceCard extends StatelessWidget {
  final ExperienceItem item;
  final VoidCallback? onTap;

  const ExperienceCard({required this.item, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.backgroundGlass,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 79,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.borderSubtle),
            boxShadow: [
              BoxShadow(
                color: colors.shadowSoft,
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            children: [
              MoodOrb(size: 42, variant: item.variant),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(Icons.arrow_forward, size: 18, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
