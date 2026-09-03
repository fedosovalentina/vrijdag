import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/auth/domain/auth_repository.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? supabaseClient;

  final SupabaseClient? _client;

  GoTrueClient get _auth {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized');
    }
    return client.auth;
  }

  @override
  Stream<AuthSession> watchSession() async* {
    yield await currentSession();
    final client = _client;
    if (client == null) {
      return;
    }
    yield* client.auth.onAuthStateChange.map((event) {
      return _mapUser(event.session?.user);
    });
  }

  @override
  Future<AuthSession> currentSession() async {
    final client = _client;
    if (client == null) {
      return const AuthSignedOut();
    }
    return _mapUser(client.auth.currentUser);
  }

  @override
  Future<void> sendMagicLink({
    required String email,
    required String emailRedirectTo,
  }) {
    return _auth.signInWithOtp(
      email: email.trim(),
      emailRedirectTo: emailRedirectTo,
      shouldCreateUser: true,
    );
  }

  @override
  Future<void> signInWithApple() async {
    final rawNonce = _auth.generateRawNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: hashedNonce,
    );

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw StateError('Apple Sign In did not return an identity token');
    }

    await _auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthSession _mapUser(User? user) {
    if (user == null) {
      return const AuthSignedOut();
    }
    return AuthSignedIn(userId: user.id, email: user.email);
  }
}
