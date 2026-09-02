/// Crash and handled-error reporting. Features must use this — never Sentry directly.
abstract class ErrorReporter {
  Future<void> initialize();

  Future<void> captureException(Object error, StackTrace stackTrace);

  /// Deliberate crash for F-001 AC-4 verification.
  Never triggerTestCrash();
}
