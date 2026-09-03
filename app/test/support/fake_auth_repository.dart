import 'dart:async';

import 'package:vrijdag/features/auth/domain/auth_repository.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository([this._current = const AuthSignedOut()]);

  final StreamController<AuthSession> _controller =
      StreamController<AuthSession>.broadcast();
  AuthSession _current;

  @override
  Stream<AuthSession> watchSession() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AuthSession> currentSession() async => _current;

  @override
  Future<void> sendMagicLink({
    required String email,
    required String emailRedirectTo,
  }) async {}

  @override
  Future<void> signInWithApple() async {}

  @override
  Future<void> deleteAccount() async {
    emit(const AuthSignedOut());
  }

  @override
  Future<void> signOut() async {
    emit(const AuthSignedOut());
  }

  void emit(AuthSession session) {
    _current = session;
    _controller.add(session);
  }

  Future<void> dispose() => _controller.close();
}
