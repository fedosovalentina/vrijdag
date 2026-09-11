/// Time-scale geometry for Day / Week / Month / Year (F-007, F-008).
///
/// Week starts Monday in both locales (F-008). Season is not a scale here.
enum CalendarScale { day, week, month, year }

abstract final class CalendarRange {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  /// Monday of the ISO week containing [day].
  static DateTime startOfWeek(DateTime day) {
    final date = dateOnly(day);
    return date.subtract(Duration(days: date.weekday - DateTime.monday));
  }

  /// Visible half-open range `[from, to)` in local calendar dates.
  static (DateTime from, DateTime to) visibleRange(
    CalendarScale scale,
    DateTime anchor,
  ) {
    final day = dateOnly(anchor);
    switch (scale) {
      case CalendarScale.day:
        return (day, day.add(const Duration(days: 1)));
      case CalendarScale.week:
        final start = startOfWeek(day);
        return (start, start.add(const Duration(days: 7)));
      case CalendarScale.month:
        final start = DateTime(day.year, day.month, 1);
        return (start, DateTime(day.year, day.month + 1, 1));
      case CalendarScale.year:
        final start = DateTime(day.year, 1, 1);
        return (start, DateTime(day.year + 1, 1, 1));
    }
  }

  /// ISO-8601 week number (week with the year's first Thursday is week 1).
  static int isoWeek(DateTime date) {
    final thursday = date.add(Duration(days: DateTime.thursday - date.weekday));
    final firstThursdayWeekStart = DateTime(thursday.year, 1, 4).subtract(
      Duration(days: DateTime(thursday.year, 1, 4).weekday - DateTime.monday),
    );
    return 1 + thursday.difference(firstThursdayWeekStart).inDays ~/ 7;
  }

  /// Meteorological season months containing [month] (1–12).
  static List<int> seasonMonths(int month) {
    if (month == 12 || month <= 2) {
      return const [12, 1, 2];
    }
    if (month <= 5) {
      return const [3, 4, 5];
    }
    if (month <= 8) {
      return const [6, 7, 8];
    }
    return const [9, 10, 11];
  }

  /// ISO week numbers that overlap [month] in [year], in calendar order.
  static List<int> isoWeeksInMonth(int year, int month) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    var cursor = startOfWeek(first);
    final weeks = <int>[];
    while (!cursor.isAfter(last)) {
      final week = isoWeek(cursor);
      if (weeks.isEmpty || weeks.last != week) {
        weeks.add(week);
      }
      cursor = cursor.add(const Duration(days: 7));
    }
    return weeks;
  }
}
