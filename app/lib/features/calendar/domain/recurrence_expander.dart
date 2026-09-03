import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

/// One occurrence produced by expanding an RRULE over a range.
class RecurrenceOccurrence {
  const RecurrenceOccurrence({required this.startsAt});

  final DateTime startsAt;
}

/// Expands a [RecurrenceRule] into concrete starts within [from, to).
///
/// V1 subset: daily / weekly / monthly / yearly with INTERVAL, COUNT, UNTIL, BYDAY.
/// February 29 yearly → February 28 in non-leap years (DEC-013).
class RecurrenceExpander {
  const RecurrenceExpander();

  List<RecurrenceOccurrence> expand({
    required RecurrenceRule rule,
    required DateTime seriesStart,
    required DateTime from,
    required DateTime to,
    int safetyLimit = 732,
  }) {
    rule.validate();
    if (!from.isBefore(to)) {
      return const [];
    }

    final start = seriesStart.toUtc();
    final results = <RecurrenceOccurrence>[];
    var emitted = 0;
    final until = rule.until?.toUtc();
    final scanEnd = to.add(const Duration(days: 370));
    var day = DateTime.utc(start.year, start.month, start.day);

    while (!day.isAfter(scanEnd) && emitted < safetyLimit) {
      final candidate = DateTime.utc(
        day.year,
        day.month,
        day.day,
        start.hour,
        start.minute,
        start.second,
      );

      if (until != null && candidate.isAfter(until)) {
        break;
      }

      if (_matches(rule, start, candidate)) {
        if (!candidate.isBefore(from) && candidate.isBefore(to)) {
          results.add(RecurrenceOccurrence(startsAt: candidate));
        }
        emitted++;
        if (rule.count != null && emitted >= rule.count!) {
          break;
        }
      }

      day = day.add(const Duration(days: 1));
    }

    return results;
  }

  bool _matches(RecurrenceRule rule, DateTime seriesStart, DateTime candidate) {
    final interval = rule.interval;
    return switch (rule.frequency) {
      RecurrenceFrequency.daily =>
        candidate
                    .difference(
                      DateTime.utc(
                        seriesStart.year,
                        seriesStart.month,
                        seriesStart.day,
                      ),
                    )
                    .inDays %
                interval ==
            0,
      RecurrenceFrequency.weekly => _matchesWeekly(
        rule,
        seriesStart,
        candidate,
      ),
      RecurrenceFrequency.monthly =>
        _monthsBetween(seriesStart, candidate) % interval == 0 &&
            candidate.day ==
                seriesStart.day.clamp(
                  1,
                  _daysInMonth(candidate.year, candidate.month),
                ),
      RecurrenceFrequency.yearly =>
        (candidate.year - seriesStart.year) % interval == 0 &&
            _yearlyMonthDay(seriesStart, candidate.year) ==
                DateTime.utc(candidate.year, candidate.month, candidate.day),
    };
  }

  bool _matchesWeekly(
    RecurrenceRule rule,
    DateTime seriesStart,
    DateTime candidate,
  ) {
    final weeks =
        DateTime.utc(candidate.year, candidate.month, candidate.day)
            .difference(
              DateTime.utc(
                seriesStart.year,
                seriesStart.month,
                seriesStart.day,
              ),
            )
            .inDays ~/
        7;
    if (weeks % rule.interval != 0) {
      return false;
    }
    if (rule.byDay.isEmpty) {
      return candidate.weekday == seriesStart.weekday;
    }
    return rule.byDay.contains(_weekdayCode(candidate));
  }

  DateTime _yearlyMonthDay(DateTime seriesStart, int year) {
    if (seriesStart.month == 2 && seriesStart.day == 29 && !_isLeap(year)) {
      return DateTime.utc(year, 2, 28);
    }
    return DateTime.utc(year, seriesStart.month, seriesStart.day);
  }

  int _monthsBetween(DateTime a, DateTime b) {
    return (b.year - a.year) * 12 + (b.month - a.month);
  }

  int _daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

  bool _isLeap(int year) =>
      (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));

  String _weekdayCode(DateTime value) {
    return const ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'][value.weekday - 1];
  }
}
