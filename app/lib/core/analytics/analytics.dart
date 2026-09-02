import 'package:vrijdag/core/analytics/analytics_event.dart';

abstract class Analytics {
  Future<void> initialize();

  Future<void> track(AnalyticsEvent event);
}
