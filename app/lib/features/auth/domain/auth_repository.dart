import 'package:vrijdag/features/auth/domain/auth_session.dart';

/// Auth operations. Presentation and other features depend on this — not on Supabase.
abstract class AuthRepository {
  Stream<AuthSession> watchSession();

  Future<AuthSession> currentSession();

  /// Sends a magic link. [emailRedirectTo] must match Supabase Auth allow-list.
  Future<void> sendMagicLink({
    required String email,
    required String emailRedirectTo,
  });

  /// Sign in with Apple (iOS). Requires Apple capability + Supabase Apple provider.
  Future<void> signInWithApple();

  /// Deletes the signed-in account via Edge Function (personal data only).
  Future<void> deleteAccount();

  Future<void> signOut();
}
