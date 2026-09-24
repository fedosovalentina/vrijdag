/// Scroll math for the month feed home control (F-014).
double feedUpperThirdOffset({
  required double rowOffset,
  required double viewport,
  required double maxScroll,
}) {
  final target = rowOffset - viewport / 3;
  if (target < 0) {
    return 0;
  }
  if (target > maxScroll) {
    return maxScroll;
  }
  return target;
}

/// True when any part of the row is inside the viewport.
bool feedDayIsVisible({
  required double rowOffset,
  required double rowHeight,
  required double pixels,
  required double viewport,
}) {
  final bottom = rowOffset + rowHeight;
  return bottom > pixels && rowOffset < pixels + viewport;
}
