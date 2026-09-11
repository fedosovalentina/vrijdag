import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/features/auth/data/supabase_auth_repository.dart';
import 'package:vrijdag/features/auth/data/supabase_user_profile_repository.dart';
import 'package:vrijdag/features/auth/domain/auth_repository.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/domain/user_profile.dart';
import 'package:vrijdag/features/auth/domain/user_profile_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return SupabaseUserProfileRepository();
});

final authSessionProvider = StreamProvider<AuthSession>((ref) {
  return ref.watch(authRepositoryProvider).watchSession();
});

/// Current `app.users` profile for the signed-in user (F-003 preferences).
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session is! AuthSignedIn) {
    return null;
  }
  return ref.read(userProfileRepositoryProvider).fetchProfile(session.userId);
});
