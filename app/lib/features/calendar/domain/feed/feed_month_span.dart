enum FeedSpanEdge { inside, continuesAfter, continuedFrom, both }

class FeedSpanCaption {
  const FeedSpanCaption({required this.edge, required this.dayLabel});

  final FeedSpanEdge edge;
  final String dayLabel;
}

/// How a multi-day bar is labelled inside one month (spec §7.3).
FeedSpanCaption captionForMonth({
  required int spanStart,
  required int spanEnd,
  required int monthStart,
  required int monthEnd,
  required String startDayLabel,
  required String endDayLabel,
}) {
  final fromBefore = spanStart < monthStart;
  final after = spanEnd > monthEnd;
  if (fromBefore && after) {
    return const FeedSpanCaption(edge: FeedSpanEdge.both, dayLabel: '');
  }
  if (after) {
    return FeedSpanCaption(
      edge: FeedSpanEdge.continuesAfter,
      dayLabel: startDayLabel,
    );
  }
  if (fromBefore) {
    return FeedSpanCaption(
      edge: FeedSpanEdge.continuedFrom,
      dayLabel: endDayLabel,
    );
  }
  return FeedSpanCaption(
    edge: FeedSpanEdge.inside,
    dayLabel: '$startDayLabel–$endDayLabel',
  );
}
