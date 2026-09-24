import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_jump.dart';

void main() {
  test('home places the row in the upper third', () {
    expect(
      feedUpperThirdOffset(rowOffset: 900, viewport: 300, maxScroll: 4000),
      800,
    );
  });

  test('a row already on screen is visible', () {
    expect(
      feedDayIsVisible(
        rowOffset: 100,
        rowHeight: 34,
        pixels: 80,
        viewport: 300,
      ),
      isTrue,
    );
    expect(
      feedDayIsVisible(
        rowOffset: 900,
        rowHeight: 34,
        pixels: 0,
        viewport: 300,
      ),
      isFalse,
    );
  });
}
