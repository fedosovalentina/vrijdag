import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';

import '../support/fake_auth_repository.dart';

void main() {
  test('fake auth repository emits signed-in session', () async {
    final auth = FakeAuthRepository();
    addTearDown(auth.dispose);

    expect(await auth.currentSession(), isA<AuthSignedOut>());

    final future = auth.watchSession().firstWhere((s) => s is AuthSignedIn);
    auth.emit(const AuthSignedIn(userId: 'u1', email: 'a@b.c'));
    final session = await future;
    expect(session, isA<AuthSignedIn>());
  });
}
