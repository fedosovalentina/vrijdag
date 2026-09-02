import 'package:vrijdag/core/analytics/analytics.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';

class NoopAnalytics implements Analytics {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> track(AnalyticsEvent event) async {}
}
