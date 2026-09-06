import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:vrijdag/app.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/config/app_config.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/consent/telemetry_consent.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  var supabaseReady = false;

  if (config.supabaseUrl.isNotEmpty &&
      config.supabasePublishableKey.isNotEmpty) {
    try {
      await initializeSupabase(config);
      supabaseReady = true;
    } on Object {
      supabaseReady = false;
    }
  }

  final consent = resolveTelemetryConsent(config);
  final observability = ObservabilityBootstrap(
    config: config,
    consentGranted: consent,
  );

  void launchApp() {
    runApp(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          supabaseReadyProvider.overrideWithValue(supabaseReady),
          ...observability.providerOverrides,
        ],
        child: const VrijdagApp(),
      ),
    );
  }

  Future<void> afterSdkReady() async {
    // Init PostHog after the Flutter engine/plugins are up (Sentry appRunner or
    // plain path). Setup before runApp can queue events that never flush.
    await observability.initializeAnalytics();
    await observability.initializeErrorReporter();
    await observability.emitAppStarted();
    launchApp();
  }

  if (observability.usesSentry) {
    await SentryFlutter.init(
      observability.configureSentry,
      appRunner: () async {
        await afterSdkReady();
      },
    );
    return;
  }

  await afterSdkReady();
}
