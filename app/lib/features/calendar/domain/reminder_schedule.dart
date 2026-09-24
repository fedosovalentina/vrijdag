/// Preset offsets in minutes before the start. `0` is the start itself.
const reminderPresetMinutes = <int>[0, 5, 15, 30, 60, 1440];

/// Start instant reminders are measured from.
///
/// Timed events use their start. All-day events use 09:00 local on the first day.
DateTime reminderAnchor({DateTime? startsAt, DateTime? allDayStart}) {
  if (startsAt != null) {
    return startsAt.toUtc();
  }
  final day = allDayStart!;
  return DateTime(day.year, day.month, day.day, 9).toUtc();
}

/// Future fire times for [reminderMinutes], in UTC. Past offsets are dropped.
List<DateTime> reminderFireTimes({
  required DateTime anchor,
  required List<int> reminderMinutes,
  required DateTime now,
}) {
  final clock = now.toUtc();
  final times = <DateTime>[];
  for (final minutes in reminderMinutes) {
    final when = anchor.toUtc().subtract(Duration(minutes: minutes));
    if (!when.isBefore(clock)) {
      times.add(when);
    }
  }
  return times;
}

/// Stable 31-bit id for one offset on one event.
int reminderNotificationId(String eventId, int minutes) {
  return Object.hash(eventId, minutes) & 0x7fffffff;
}
