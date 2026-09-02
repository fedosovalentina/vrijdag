/// Build-time environment. Selected via `--dart-define=VRIJDAG_ENV=…`.
enum VrijdagEnv {
  local,
  staging,
  production;

  static VrijdagEnv parse(String? raw) {
    return switch (raw?.toLowerCase().trim()) {
      'staging' => VrijdagEnv.staging,
      'production' => VrijdagEnv.production,
      _ => VrijdagEnv.local,
    };
  }

  String get label => name;
}
