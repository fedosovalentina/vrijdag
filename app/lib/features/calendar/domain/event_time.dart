/// Absolute wall-clock instant with IANA timezone (timed events).
class TimedEventSpan {
  const TimedEventSpan({
    required this.startsAt,
    required this.endsAt,
    required this.timezone,
  });

  final DateTime startsAt;
  final DateTime endsAt;
  final String timezone;

  Duration get duration => endsAt.difference(startsAt);

  void validate() {
    if (endsAt.isBefore(startsAt)) {
      throw ArgumentError('endsAt must be >= startsAt');
    }
  }
}

/// Calendar-date span for all-day events (never midnight timestamps).
class AllDayEventSpan {
  const AllDayEventSpan({required this.startDate, required this.endDate});

  final DateTime startDate; // date-only; time ignored
  final DateTime endDate;

  void validate() {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    if (end.isBefore(start)) {
      throw ArgumentError('endDate must be >= startDate');
    }
  }
}

/// Default duration for a new timed event (F-004).
const Duration defaultTimedEventDuration = Duration(minutes: 60);

DateTime defaultTimedEventEnd(DateTime start) =>
    start.add(defaultTimedEventDuration);
