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
      // Stay silent without a key — never call Posthog().setup with empty config.
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
      case AuthMagicLinkSent():
        await Posthog().capture(eventName: 'auth_magic_link_sent');
      case AuthSignInSucceeded(:final method):
        await Posthog().capture(
          eventName: 'auth_signed_in',
          properties: {'method': method},
        );
      case AuthSignOutSucceeded():
        await Posthog().capture(eventName: 'auth_signed_out');
      case AuthAccountDeleted():
        await Posthog().capture(eventName: 'auth_account_deleted');
      case EventCreated(:final source, :final isAllDay, :final hasLocation):
        await Posthog().capture(
          eventName: 'event_created',
          properties: {
            'source': source,
            'is_all_day': isAllDay,
            'has_location': hasLocation,
          },
        );
      case EventEdited(:final source):
        await Posthog().capture(
          eventName: 'event_edited',
          properties: {'source': source},
        );
      case EventDeleted(:final source):
        await Posthog().capture(
          eventName: 'event_deleted',
          properties: {'source': source},
        );
      case EventDeleteUndone():
        await Posthog().capture(eventName: 'event_delete_undone');
    }
  }
}
