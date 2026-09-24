import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_frame.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_month_span.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_name.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_row.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_scale.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_slots.dart';

void main() {
  test('scale floors the start, ceils the end, and ignores all-day', () {
    final scale = FeedScale.fromWallRanges(const [
      FeedWallRange(startMinute: 9 * 60 + 30, endMinute: 11 * 60 + 15),
      FeedWallRange(startMinute: 0, endMinute: 0, timed: false),
    ]);
    expect(scale.startMinute, 8 * 60 + 30);
    expect(scale.endMinute, 12 * 60 + 30);
  });

  test('scale caps at 12 hours from the start', () {
    final scale = FeedScale.fromWallRanges(const [
      FeedWallRange(startMinute: 8 * 60, endMinute: 22 * 60),
    ]);
    expect(scale.startMinute, 8 * 60);
    expect(scale.endMinute, 20 * 60);
  });

  test('scale expands and does not move events already placed', () {
    final first = FeedScale.fromWallRanges(const [
      FeedWallRange(startMinute: 9 * 60, endMinute: 12 * 60),
    ]);
    final later = FeedScale.fromWallRanges(const [
      FeedWallRange(startMinute: 14 * 60, endMinute: 18 * 60),
    ]);
    final grown = first.expandTo(later);
    expect(grown.startMinute, first.startMinute);
    expect(grown.endMinute, greaterThan(first.endMinute));

    final full = const FeedScale(startMinute: 8 * 60, endMinute: 20 * 60);
    final earlier = const FeedScale(startMinute: 6 * 60, endMinute: 9 * 60);
    final held = full.expandTo(earlier);
    expect(held.startMinute, full.startMinute);
    expect(held.endMinute, full.endMinute);
  });

  test('15-minute event is a tick on its start', () {
    const scale = FeedScale(startMinute: 8 * 60, endMinute: 17 * 60);
    final frame = FeedFrame.place(
      scale: scale,
      startMinute: 11 * 60,
      endMinute: 11 * 60 + 15,
    );
    expect(frame.kind, FeedFrameKind.tick);
    expect(frame.left, closeTo(3 / 9, 0.0001));
  });

  test(
    'wall-clock 16:00 stays at 16:00 when the UTC gap is an hour longer',
    () {
      const scale = FeedScale(startMinute: 8 * 60, endMinute: 20 * 60);
      const wallMinute = 16 * 60;
      final frame = FeedFrame.place(
        scale: scale,
        startMinute: wallMinute,
        endMinute: wallMinute + 60,
      );
      final shifted = FeedFrame.place(
        scale: scale,
        startMinute: wallMinute + 60,
        endMinute: wallMinute + 120,
      );
      expect(frame.left, closeTo((16 - 8) / 12, 0.0001));
      expect(shifted.left, isNot(closeTo(frame.left, 0.0001)));
    },
  );

  test('event past the scale pins to the right edge', () {
    const scale = FeedScale(startMinute: 8 * 60, endMinute: 16 * 60);
    final frame = FeedFrame.place(
      scale: scale,
      startMinute: 18 * 60,
      endMinute: 19 * 60,
    );
    expect(frame.kind, FeedFrameKind.afterScale);
    expect(frame.left, closeTo(0.78, 0.0001));
    expect(frame.width, 0.22);
  });

  test('overlapping spans take the first free slot, fourth is unmarked', () {
    final slots = assignFeedSlots(const [
      FeedSpan(id: 'a', startDay: 1, endDay: 5),
      FeedSpan(id: 'b', startDay: 2, endDay: 4),
      FeedSpan(id: 'c', startDay: 3, endDay: 6),
      FeedSpan(id: 'd', startDay: 4, endDay: 4),
      FeedSpan(id: 'e', startDay: 6, endDay: 8),
    ]);
    expect(slots.map((s) => s.slot), [0, 1, 2, -1, 0]);
  });

  test('span caption breaks on the month boundary', () {
    final after = captionForMonth(
      spanStart: 20,
      spanEnd: 40,
      monthStart: 1,
      monthEnd: 30,
      startDayLabel: '29',
      endDayLabel: '3',
    );
    expect(after.edge, FeedSpanEdge.continuesAfter);
    expect(after.dayLabel, '29');

    final before = captionForMonth(
      spanStart: 20,
      spanEnd: 40,
      monthStart: 32,
      monthEnd: 60,
      startDayLabel: '29',
      endDayLabel: '3',
    );
    expect(before.edge, FeedSpanEdge.continuedFrom);
  });

  test('five events show three and two hidden', () {
    final layout = layoutFeedDay(5);
    expect(layout.hiddenCount, 2);
    expect(layout.rowHeight, 100);
    expect(layoutFeedDay(5, expanded: true).hiddenCount, 0);
  });

  test('name keeps the first word and ellipsizes on a word boundary', () {
    double measure(String text) => text.length * 10;
    final fitted = fitFeedName('Design review with the team', 180, measure);
    expect(fitted.fit, FeedNameFit.truncated);
    expect(fitted.text, 'Design review…');
    expect(fitted.text.contains('revie…'), isFalse);

    final longWord = fitFeedName('Supercalifragilistic', 50, measure);
    expect(longWord.fit, FeedNameFit.firstWordOnly);
    expect(longWord.text, 'Supercalifragilistic');
  });
}
