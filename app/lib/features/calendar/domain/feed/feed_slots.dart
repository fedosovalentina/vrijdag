/// Greedy left-to-right lanes for multi-day spans (spec §7.1).
class FeedSpan {
  const FeedSpan({
    required this.id,
    required this.startDay,
    required this.endDay,
  });

  final String id;

  /// Inclusive date ordinals (`DateTime.millisecondsSinceEpoch` of the date, or any
  /// monotonic day index). End is inclusive.
  final int startDay;
  final int endDay;
}

class FeedSlotAssignment {
  const FeedSlotAssignment({required this.id, required this.slot});

  final String id;

  /// `0..maxSlots-1`, or `-1` when the span does not get a lane.
  final int slot;
}

List<FeedSlotAssignment> assignFeedSlots(
  List<FeedSpan> spans, {
  int maxSlots = 3,
}) {
  final ordered = [...spans]
    ..sort((a, b) {
      final byStart = a.startDay.compareTo(b.startDay);
      if (byStart != 0) {
        return byStart;
      }
      return a.endDay.compareTo(b.endDay);
    });

  final laneEnds = List<int?>.filled(maxSlots, null);
  final out = <FeedSlotAssignment>[];

  for (final span in ordered) {
    var slot = -1;
    for (var i = 0; i < maxSlots; i++) {
      final occupiedUntil = laneEnds[i];
      if (occupiedUntil == null || occupiedUntil < span.startDay) {
        slot = i;
        laneEnds[i] = span.endDay;
        break;
      }
    }
    out.add(FeedSlotAssignment(id: span.id, slot: slot));
  }
  return out;
}
