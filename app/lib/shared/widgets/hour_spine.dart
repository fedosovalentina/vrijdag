import 'package:flutter/material.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/shared/widgets/event_row.dart';

/// Quiet-day hour marks (Task 02). Numerals, not copy.
class HourSpine extends StatelessWidget {
  const HourSpine({
    super.key,
    this.hours = defaultHours,
    this.faded = true,
    this.onHourTap,
  });

  /// Default sparse anchors for quiet and busy days.
  static const List<int> defaultHours = [8, 12, 18];

  final List<int> hours;
  final bool faded;
  final ValueChanged<int>? onHourTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: faded ? 0.35 : 1,
      child: Column(
        children: [
          for (final hour in hours)
            EventRow(
              timeLabel: hour.toString().padLeft(2, '0'),
              title: '',
              kind: EventMarkerKind.emptyHour,
              onTap: onHourTap == null ? null : () => onHourTap!(hour),
            ),
        ],
      ),
    );
  }

  /// Timed events plus faded empty-hour marks where the day is sparse.
  ///
  /// Anchors that already have an event starting in that hour are omitted.
  static List<Widget> busyRows({
    required List<PersonalEvent> timed,
    required String Function(PersonalEvent event) timeLabel,
    required String? Function(PersonalEvent event) subtitle,
    required ValueChanged<PersonalEvent> onEventTap,
    ValueChanged<int>? onHourTap,
    List<int> anchorHours = defaultHours,
  }) {
    final sorted = List<PersonalEvent>.of(timed)
      ..sort(
        (a, b) =>
            a.timed!.startsAt.toLocal().compareTo(b.timed!.startsAt.toLocal()),
      );

    final day = sorted.isEmpty
        ? DateTime(2000)
        : sorted.first.timed!.startsAt.toLocal();
    final occupied = {
      for (final event in sorted) event.timed!.startsAt.toLocal().hour,
    };

    final items = <({DateTime at, bool isEmpty, Widget child})>[];
    for (final event in sorted) {
      items.add((
        at: event.timed!.startsAt.toLocal(),
        isEmpty: false,
        child: EventRow(
          timeLabel: timeLabel(event),
          title: event.title,
          subtitle: subtitle(event),
          onTap: () => onEventTap(event),
        ),
      ));
    }
    for (final hour in anchorHours) {
      if (occupied.contains(hour)) {
        continue;
      }
      items.add((
        at: DateTime(day.year, day.month, day.day, hour),
        isEmpty: true,
        child: Opacity(
          opacity: 0.35,
          child: EventRow(
            timeLabel: hour.toString().padLeft(2, '0'),
            title: '',
            kind: EventMarkerKind.emptyHour,
            onTap: onHourTap == null ? null : () => onHourTap(hour),
          ),
        ),
      ));
    }

    items.sort((a, b) {
      final byTime = a.at.compareTo(b.at);
      if (byTime != 0) {
        return byTime;
      }
      // Prefer real events before empty marks at the same instant.
      if (a.isEmpty == b.isEmpty) {
        return 0;
      }
      return a.isEmpty ? 1 : -1;
    });

    return [for (final item in items) item.child];
  }
}
