/// User profile row in `app.users`.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.language,
    required this.timezone,
  });

  final String id;
  final String language;
  final String timezone;
}
