import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vrijdag/core/analytics/analytics.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/analytics/noop_analytics.dart';
import 'package:vrijdag/core/analytics/posthog_analytics.dart';
import 'package:vrijdag/core/config/app_config.dart';
import 'package:vrijdag/core/errors/error_reporter.dart';
import 'package:vrijdag/core/errors/noop_error_reporter.dart';
import 'package:vrijdag/core/errors/sentry_error_reporter.dart';

final errorReporterProvider = Provider<ErrorReporter>(
  (ref) => throw UnimplementedError(
    'errorReporterProvider must be overridden before runApp',
  ),
);

final analyticsProvider = Provider<Analytics>(
  (ref) => throw UnimplementedError(
    'analyticsProvider must be overridden before runApp',
  ),
);

/// Wires observability SDKs according to config and consent rules.
class ObservabilityBootstrap {
  ObservabilityBootstrap({
    required AppConfig config,
    required bool consentGranted,
  }) : _config = config,
       _consentGranted = consentGranted;

  final AppConfig _config;
  final bool _consentGranted;

  late final ErrorReporter errorReporter = _createErrorReporter();
  late final Analytics analytics = _createAnalytics();

  bool get usesSentry =>
      _consentGranted &&
      _config.hasSentry &&
      errorReporter is SentryErrorReporter;

  ErrorReporter _createErrorReporter() {
    if (!_consentGranted || !_config.hasSentry) {
      return NoopErrorReporter();
    }
    return SentryErrorReporter(_config);
  }

  Analytics _createAnalytics() {
    if (!_consentGranted || !_config.hasPosthog) {
      return NoopAnalytics();
    }
    return PosthogAnalytics(_config);
  }

  Future<void> initializeAnalytics() => analytics.initialize();

  Future<void> initializeErrorReporter() => errorReporter.initialize();

  Future<void> emitAppStarted() {
    return analytics.track(
      AppStarted(
        environment: _config.environment.label,
        version: _config.appVersion,
      ),
    );
  }

  void configureSentry(SentryFlutterOptions options) {
    if (errorReporter is SentryErrorReporter) {
      (errorReporter as SentryErrorReporter).configure(options);
    }
  }

  List<Override> get providerOverrides => [
    errorReporterProvider.overrideWithValue(errorReporter),
    analyticsProvider.overrideWithValue(analytics),
  ];
}
