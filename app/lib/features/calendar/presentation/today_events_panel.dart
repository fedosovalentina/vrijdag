import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/features/calendar/presentation/event_editor_screen.dart';
import 'package:vrijdag/shared/widgets/event_row.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';

/// Utilitarian today list until Design Task 02 lands Day chrome.
class TodayEventsPanel extends ConsumerWidget {
  const TodayEventsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final events = ref.watch(todaysEventsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.calendarTodayTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const EventEditorScreen()),
                );
                ref.invalidate(todaysEventsProvider);
                ref.invalidate(pendingWriteCountProvider);
              },
              child: Text(l10n.calendarNewEvent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        events.when(
          data: (items) {
            if (items.isEmpty) {
              return QuietState(message: l10n.calendarEmptyToday);
            }
            return Column(
              children: [
                for (final event in items)
                  Row(
                    children: [
                      Expanded(
                        child: EventRow(
                          title: event.title,
                          timeLabel: event.isAllDay
                              ? null
                              : _formatTimed(event),
                          subtitle: event.isAllDay
                              ? l10n.calendarAllDay
                              : (event.hasLocation ? event.location : null),
                          kind: event.isAllDay
                              ? EventMarkerKind.allDay
                              : EventMarkerKind.timed,
                          onTap: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventEditorScreen(existing: event),
                              ),
                            );
                            ref.invalidate(todaysEventsProvider);
                            ref.invalidate(pendingWriteCountProvider);
                          },
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteWithUndo(context, ref, event),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: l10n.commonDelete,
                      ),
                    ],
                  ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Text(l10n.calendarLoadFailed),
        ),
      ],
    );
  }

  Future<void> _deleteWithUndo(
    BuildContext context,
    WidgetRef ref,
    PersonalEvent event,
  ) async {
    final l10n = context.l10n;
    final repo = ref.read(personalEventsRepositoryProvider);
    final analytics = ref.read(analyticsProvider);
    await repo.softDelete(event.id);
    await analytics.track(EventDeleted(source: event.source.name));
    ref.invalidate(todaysEventsProvider);
    ref.invalidate(pendingWriteCountProvider);

    if (!context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.calendarDeleted),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: l10n.calendarUndo,
          onPressed: () async {
            await repo.undoSoftDelete(event.id);
            await analytics.track(const EventDeleteUndone());
            ref.invalidate(todaysEventsProvider);
            ref.invalidate(pendingWriteCountProvider);
          },
        ),
      ),
    );
  }

  String _formatTimed(PersonalEvent event) {
    final start = event.timed!.startsAt.toLocal();
    final end = event.timed!.endsAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)}–${two(end.hour)}:${two(end.minute)}';
  }
}
