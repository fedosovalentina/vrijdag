/// Authentication session snapshot for the UI gate.
sealed class AuthSession {
  const AuthSession();
}

class AuthSignedOut extends AuthSession {
  const AuthSignedOut();
}

class AuthSignedIn extends AuthSession {
  const AuthSignedIn({required this.userId, required this.email});

  final String userId;
  final String? email;
}

class AuthUnknown extends AuthSession {
  const AuthUnknown();
}
