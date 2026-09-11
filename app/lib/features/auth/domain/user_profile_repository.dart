import 'package:vrijdag/features/auth/domain/user_profile.dart';

abstract class UserProfileRepository {
  /// Ensures `app.users` exists and applies language/timezone defaults when new.
  Future<UserProfile> ensureProfile({
    required String userId,
    required String language,
    required String timezone,
  });

  /// Loads the profile row, or null when missing.
  Future<UserProfile?> fetchProfile(String userId);

  /// Updates language, home city, and school holiday region preferences.
  Future<UserProfile> updatePreferences({
    required String userId,
    required String language,
    String? homeCity,
    String? schoolHolidayRegion,
  });
}
