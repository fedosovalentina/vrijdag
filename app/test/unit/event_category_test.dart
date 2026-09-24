import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/calendar/domain/event_category.dart';

void main() {
  test('a new list starts empty and a ninth label is refused', () {
    var catalog = const CategoryCatalog([]);
    for (var i = 0; i < 8; i++) {
      catalog = catalog.add(id: '$i', name: 'Label $i')!;
    }
    expect(catalog.items, hasLength(8));
    expect(catalog.add(id: '9', name: 'Extra'), isNull);
  });

  test('removing a label leaves it out of the list', () {
    final catalog = const CategoryCatalog([]).add(id: 'a', name: 'Werk')!;
    expect(catalog.remove('a').items, isEmpty);
  });
}
