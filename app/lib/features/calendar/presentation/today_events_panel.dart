import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/features/calendar/presentation/create_event_screen.dart';

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
                  MaterialPageRoute(builder: (_) => const CreateEventScreen()),
                );
              },
              child: Text(l10n.calendarNewEvent),
            ),
          ],
        ),
        const SizedBox(height: 8),
        events.when(
          data: (items) {
            if (items.isEmpty) {
              return Text(l10n.calendarEmptyToday);
            }
            return Column(
              children: [
                for (final event in items)
                  _EventTile(
                    event: event,
                    onDelete: () => _deleteWithUndo(context, ref, event),
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
    await repo.softDelete(event.id);
    ref.invalidate(todaysEventsProvider);

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
            ref.invalidate(todaysEventsProvider);
          },
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event, required this.onDelete});

  final PersonalEvent event;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final subtitle = event.isAllDay ? l10n.calendarAllDay : _formatTimed(event);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(event.title),
      subtitle: Text(
        [subtitle, if (event.hasLocation) event.location!].join(' · '),
      ),
      trailing: IconButton(
        onPressed: onDelete,
        icon: const Icon(Icons.delete_outline),
        tooltip: l10n.commonDelete,
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
