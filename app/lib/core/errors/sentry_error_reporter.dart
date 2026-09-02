import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vrijdag/core/config/app_config.dart';
import 'package:vrijdag/core/errors/error_reporter.dart';

class SentryErrorReporter implements ErrorReporter {
  SentryErrorReporter(this._config);

  final AppConfig _config;
  var _initialized = false;

  void configure(SentryFlutterOptions options) {
    options.dsn = _config.sentryDsn;
    options.environment = _config.environment.label;
    options.release = 'vrijdag@${_config.appVersion}';
    options.attachScreenshot = false;
    options.enableAutoSessionTracking = true;
    options.enableUserInteractionTracing = false;
  }

  @override
  Future<void> initialize() async {
    _initialized = true;
  }

  @override
  Future<void> captureException(Object error, StackTrace stackTrace) async {
    if (!_initialized) {
      return;
    }
    await Sentry.captureException(error, stackTrace: stackTrace);
  }

  @override
  Never triggerTestCrash() {
    throw StateError('F-001 deliberate test crash');
  }
}
