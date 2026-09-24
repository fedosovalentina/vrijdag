/// How a change applies to a repeating event (F-005).
enum RecurrenceScope { thisEvent, thisAndFollowing, all }

class RecurrenceEditPlan {
  const RecurrenceEditPlan({
    required this.exdates,
    required this.detachOccurrence,
    required this.applyToSeries,
    this.seriesUntil,
    this.replaceUntil = false,
  });

  final List<DateTime> exdates;
  final bool detachOccurrence;
  final bool applyToSeries;

  /// Set only when [replaceUntil] is true.
  final DateTime? seriesUntil;
  final bool replaceUntil;
}

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

/// Plans a save or delete. "All" keeps existing exclusions.
RecurrenceEditPlan planRecurrenceEdit({
  required RecurrenceScope scope,
  required DateTime occurrence,
  required List<DateTime> existingExdates,
  required bool deleting,
}) {
  final day = _day(occurrence);
  final kept = existingExdates.map(_day).toList();
  switch (scope) {
    case RecurrenceScope.thisEvent:
      final exdates = [
        for (final item in kept)
          if (item != day) item,
        day,
      ];
      return RecurrenceEditPlan(
        exdates: exdates,
        detachOccurrence: !deleting,
        applyToSeries: false,
      );
    case RecurrenceScope.thisAndFollowing:
      return RecurrenceEditPlan(
        exdates: kept,
        detachOccurrence: !deleting,
        applyToSeries: false,
        seriesUntil: day.subtract(const Duration(days: 1)),
        replaceUntil: true,
      );
    case RecurrenceScope.all:
      return RecurrenceEditPlan(
        exdates: kept,
        detachOccurrence: false,
        applyToSeries: true,
      );
  }
}
