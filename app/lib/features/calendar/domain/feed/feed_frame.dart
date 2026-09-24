import 'package:vrijdag/features/calendar/domain/feed/feed_scale.dart';

enum FeedFrameKind { bar, tick, beforeScale, afterScale }

/// Horizontal placement of one timed event on [FeedScale] (spec §3.3, §6.2, §6.5).
class FeedFrame {
  const FeedFrame({
    required this.kind,
    required this.left,
    required this.width,
  });

  /// Fraction of the scale, 0–1.
  final FeedFrameKind kind;
  final double left;
  final double width;

  static const tickBelowMinutes = 20;
  static const outsideWidth = 0.22;

  static FeedFrame place({
    required FeedScale scale,
    required int startMinute,
    required int endMinute,
  }) {
    final duration = endMinute - startMinute;
    final span = scale.spanMinutes;
    if (startMinute >= scale.endMinute) {
      return const FeedFrame(
        kind: FeedFrameKind.afterScale,
        left: 1 - outsideWidth,
        width: outsideWidth,
      );
    }
    if (endMinute <= scale.startMinute) {
      return const FeedFrame(
        kind: FeedFrameKind.beforeScale,
        left: 0,
        width: outsideWidth,
      );
    }
    final left = (startMinute - scale.startMinute) / span;
    final width = duration / span;
    if (duration < tickBelowMinutes) {
      return FeedFrame(kind: FeedFrameKind.tick, left: left, width: width);
    }
    return FeedFrame(kind: FeedFrameKind.bar, left: left, width: width);
  }
}
