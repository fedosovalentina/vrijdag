/// How a day with nothing on it is drawn in the month feed.
enum FeedEmptyMode {
  compact,
  collapsed,
  hidden;

  static FeedEmptyMode fromName(String? raw) {
    return switch (raw) {
      'collapsed' => FeedEmptyMode.collapsed,
      'hidden' => FeedEmptyMode.hidden,
      _ => FeedEmptyMode.compact,
    };
  }
}

sealed class FeedDayPiece {
  const FeedDayPiece();
}

class FeedSingleDay extends FeedDayPiece {
  const FeedSingleDay(this.day);

  final DateTime day;
}

class FeedEmptyFold extends FeedDayPiece {
  const FeedEmptyFold({
    required this.from,
    required this.to,
    required this.count,
  });

  final DateTime from;
  final DateTime to;
  final int count;
}

/// [isEmpty] is false for a birthday, an event, or a day inside a multi-day span.
List<FeedDayPiece> layoutFeedDays({
  required List<DateTime> days,
  required bool Function(DateTime day) isEmpty,
  required FeedEmptyMode mode,
  Set<DateTime> openFolds = const {},
}) {
  if (mode == FeedEmptyMode.compact) {
    return [for (final day in days) FeedSingleDay(day)];
  }
  if (mode == FeedEmptyMode.hidden) {
    return [
      for (final day in days)
        if (!isEmpty(day)) FeedSingleDay(day),
    ];
  }

  final pieces = <FeedDayPiece>[];
  final buffer = <DateTime>[];
  void flush() {
    if (buffer.length >= 3) {
      final key = buffer.first;
      final opened = openFolds.any(
        (day) =>
            day.year == key.year &&
            day.month == key.month &&
            day.day == key.day,
      );
      if (opened) {
        pieces.addAll([for (final day in buffer) FeedSingleDay(day)]);
      } else {
        pieces.add(
          FeedEmptyFold(
            from: buffer.first,
            to: buffer.last,
            count: buffer.length,
          ),
        );
      }
    } else {
      pieces.addAll([for (final day in buffer) FeedSingleDay(day)]);
    }
    buffer.clear();
  }

  for (final day in days) {
    if (isEmpty(day)) {
      buffer.add(day);
    } else {
      flush();
      pieces.add(FeedSingleDay(day));
    }
  }
  flush();
  return pieces;
}
