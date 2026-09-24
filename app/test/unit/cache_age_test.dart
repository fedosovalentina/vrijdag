import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/core/database/cache_age.dart';

void main() {
  final now = DateTime.utc(2026, 9, 24, 12);

  test('under a minute is still current', () {
    expect(cacheAge(now.subtract(const Duration(seconds: 20)), now), isNull);
  });

  test('age is minutes, then hours, then days', () {
    expect(
      cacheAge(now.subtract(const Duration(minutes: 12)), now),
      const CacheAge(unit: CacheAgeUnit.minutes, count: 12),
    );
    expect(
      cacheAge(now.subtract(const Duration(hours: 3)), now),
      const CacheAge(unit: CacheAgeUnit.hours, count: 3),
    );
    expect(
      cacheAge(now.subtract(const Duration(days: 4)), now),
      const CacheAge(unit: CacheAgeUnit.days, count: 4),
    );
  });
}
