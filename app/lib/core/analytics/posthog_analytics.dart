import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:vrijdag/core/analytics/analytics.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/config/app_config.dart';

class PosthogAnalytics implements Analytics {
  PosthogAnalytics(this._config);

  final AppConfig _config;
  var _initialized = false;

  @override
  Future<void> initialize() async {
    final apiKey = _config.posthogApiKey;
    if (apiKey == null || apiKey.isEmpty) {
      return;
    }

    final config = PostHogConfig(apiKey)
      ..host = _config.posthogHost
      ..captureApplicationLifecycleEvents = false
      ..sessionReplay = false;

    await Posthog().setup(config);
    _initialized = true;
  }

  @override
  Future<void> track(AnalyticsEvent event) async {
    if (!_initialized) {
      return;
    }

    switch (event) {
      case AppStarted(:final environment, :final version):
        await Posthog().capture(
          eventName: 'app_started',
          properties: {'environment': environment, 'version': version},
        );
    }
  }
}
