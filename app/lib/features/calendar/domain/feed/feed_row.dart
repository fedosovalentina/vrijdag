class FeedChipLayout {
  const FeedChipLayout({
    required this.rowHeight,
    required this.chipHeight,
    required this.gap,
    required this.hiddenCount,
  });

  final double rowHeight;
  final double chipHeight;
  final double gap;
  final int hiddenCount;
}

/// Visible stack for one day (spec §4.1, §8). Untimed items sort first.
FeedChipLayout layoutFeedDay(int eventCount, {bool expanded = false}) {
  if (eventCount <= 0) {
    return const FeedChipLayout(
      rowHeight: 22,
      chipHeight: 0,
      gap: 0,
      hiddenCount: 0,
    );
  }
  if (eventCount == 1) {
    return const FeedChipLayout(
      rowHeight: 34,
      chipHeight: 24,
      gap: 0,
      hiddenCount: 0,
    );
  }
  if (eventCount == 2) {
    return const FeedChipLayout(
      rowHeight: 58,
      chipHeight: 21,
      gap: 5,
      hiddenCount: 0,
    );
  }
  if (eventCount == 3) {
    return const FeedChipLayout(
      rowHeight: 78,
      chipHeight: 17,
      gap: 4,
      hiddenCount: 0,
    );
  }
  if (!expanded) {
    return FeedChipLayout(
      rowHeight: 78 + 22,
      chipHeight: 17,
      gap: 4,
      hiddenCount: eventCount - 3,
    );
  }
  return FeedChipLayout(
    rowHeight: 78 + (eventCount - 3) * (17 + 4),
    chipHeight: 17,
    gap: 4,
    hiddenCount: 0,
  );
}

int compareFeedEvents({
  required bool aUntimed,
  required int aStart,
  required bool bUntimed,
  required int bStart,
}) {
  if (aUntimed != bUntimed) {
    return aUntimed ? -1 : 1;
  }
  return aStart.compareTo(bStart);
}
