/// Stored values for `app.users.school_holiday_region` (F-003 / F-033).
abstract final class SchoolHolidayRegion {
  static const noord = 'noord';
  static const centraal = 'centraal';
  static const zuid = 'zuid';

  /// Explicit "I don't know" — school-holiday layer stays off.
  static const unknown = 'unknown';

  static const all = <String>[noord, centraal, zuid, unknown];

  static bool isValid(String? value) => value != null && all.contains(value);
}
