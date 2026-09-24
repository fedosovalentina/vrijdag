import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_empty.dart';

void main() {
  final days = [
    for (var d = 1; d <= 6; d++) DateTime(2026, 9, d),
  ];
  bool empty(DateTime day) => day.day != 1 && day.day != 6;

  test('hidden drops empty days and keeps a day inside a span', () {
    final pieces = layoutFeedDays(
      days: days,
      isEmpty: empty,
      mode: FeedEmptyMode.hidden,
    );
    expect(
      pieces.whereType<FeedSingleDay>().map((piece) => piece.day.day),
      [1, 6],
    );
  });

  test('collapsed folds three or more empty days', () {
    final pieces = layoutFeedDays(
      days: days,
      isEmpty: empty,
      mode: FeedEmptyMode.collapsed,
    );
    expect(pieces, hasLength(3));
    expect((pieces[1] as FeedEmptyFold).count, 4);
  });
}
