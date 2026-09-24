/// Shared clock range for the month feed (F-011, spec §3).
///
/// Minutes are wall-clock minutes from local midnight, not UTC elapsed time.
class FeedScale {
  const FeedScale({required this.startMinute, required this.endMinute})
    : assert(endMinute > startMinute);

  final int startMinute;
  final int endMinute;

  int get spanMinutes => endMinute - startMinute;

  /// Four hours when nothing timed is loaded, so the axis still has a shape.
  static const empty = FeedScale(startMinute: 8 * 60, endMinute: 12 * 60);

  static const maxSpan = 12 * 60;
  static const minSpan = 4 * 60;

  static FeedScale fromWallRanges(Iterable<FeedWallRange> ranges) {
    var start = 1 << 30;
    var end = -1;
    for (final range in ranges) {
      if (!range.timed) {
        continue;
      }
      if (range.startMinute < start) {
        start = range.startMinute;
      }
      if (range.endMinute > end) {
        end = range.endMinute;
      }
    }
    if (end < 0) {
      return empty;
    }
    return FeedScale(
      startMinute: _floorHour(start),
      endMinute: _ceilHour(end),
    )._clampSpan();
  }

  /// Grows to include [next]. The start only moves earlier when the current end
  /// still fits in the 12-hour cap. The end never moves earlier.
  FeedScale expandTo(FeedScale next) {
    var start = startMinute;
    var end = endMinute;
    if (next.endMinute > end) {
      end = next.endMinute;
    }
    if (next.startMinute < start && end - next.startMinute <= maxSpan) {
      start = next.startMinute;
    }
    if (end - start > maxSpan) {
      end = start + maxSpan;
    }
    return FeedScale(startMinute: start, endMinute: end);
  }

  FeedScale _clampSpan() {
    var start = startMinute;
    var end = endMinute;
    if (end - start > maxSpan) {
      end = start + maxSpan;
    }
    if (end - start < minSpan) {
      final deficit = minSpan - (end - start);
      final left = deficit ~/ 2;
      final right = deficit - left;
      start -= left;
      end += right;
    }
    if (start < 0) {
      end -= start;
      start = 0;
    }
    if (end > 24 * 60) {
      start -= end - 24 * 60;
      end = 24 * 60;
    }
    if (start < 0) {
      start = 0;
    }
    if (end - start > maxSpan) {
      end = start + maxSpan;
    }
    return FeedScale(startMinute: start, endMinute: end);
  }

  static int _floorHour(int minute) => minute - (minute % 60);

  static int _ceilHour(int minute) {
    if (minute % 60 == 0) {
      return minute;
    }
    return minute + (60 - minute % 60);
  }
}

class FeedWallRange {
  const FeedWallRange({
    required this.startMinute,
    required this.endMinute,
    this.timed = true,
  });

  final int startMinute;
  final int endMinute;
  final bool timed;
}
