import 'package:vrijdag/features/auth/domain/user_profile.dart';

abstract class UserProfileRepository {
  /// Ensures `app.users` exists and applies language/timezone defaults when new.
  Future<UserProfile> ensureProfile({
    required String userId,
    required String language,
    required String timezone,
  });
}
