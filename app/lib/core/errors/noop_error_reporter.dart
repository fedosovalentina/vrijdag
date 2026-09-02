import 'package:vrijdag/core/errors/error_reporter.dart';

/// No-op reporter when DSN is absent or consent blocks telemetry.
class NoopErrorReporter implements ErrorReporter {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> captureException(Object error, StackTrace stackTrace) async {}

  @override
  Never triggerTestCrash() {
    throw StateError(
      'F-001 test crash (noop reporter — Sentry not configured)',
    );
  }
}
