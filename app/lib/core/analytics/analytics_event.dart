/// Typed product analytics events. Features must use [Analytics] — never PostHog directly.
sealed class AnalyticsEvent {
  const AnalyticsEvent();
}

/// F-001 smoke event — proves the analytics pipeline works (AC-5).
class AppStarted extends AnalyticsEvent {
  const AppStarted({required this.environment, required this.version});

  final String environment;
  final String version;
}
