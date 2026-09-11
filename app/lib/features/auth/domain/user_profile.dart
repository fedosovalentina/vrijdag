/// User profile row in `app.users`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.language,
    required this.timezone,
    this.homeCity,
    this.schoolHolidayRegion,
  });

  final String id;
  final String language;
  final String timezone;

  /// Optional free-text home city (F-003).
  final String? homeCity;

  /// `noord` | `centraal` | `zuid` | `unknown`, or null when unset/skipped.
  final String? schoolHolidayRegion;
}
