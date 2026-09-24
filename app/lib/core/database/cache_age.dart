/// How old a local cache is, in one unit. Null means it is still fresh.
class CacheAge {
  const CacheAge({required this.unit, required this.count});

  final CacheAgeUnit unit;
  final int count;

  @override
  bool operator ==(Object other) =>
      other is CacheAge && other.unit == unit && other.count == count;

  @override
  int get hashCode => Object.hash(unit, count);
}

enum CacheAgeUnit { minutes, hours, days }

/// Age of [cachedAt] at [now]. Under a minute is still current.
CacheAge? cacheAge(DateTime cachedAt, DateTime now) {
  final delta = now.toUtc().difference(cachedAt.toUtc());
  if (delta.isNegative || delta.inMinutes < 1) {
    return null;
  }
  if (delta.inMinutes < 60) {
    return CacheAge(unit: CacheAgeUnit.minutes, count: delta.inMinutes);
  }
  if (delta.inHours < 48) {
    return CacheAge(unit: CacheAgeUnit.hours, count: delta.inHours);
  }
  return CacheAge(unit: CacheAgeUnit.days, count: delta.inDays);
}
