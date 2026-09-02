import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/core/config/app_config.dart';
import 'package:vrijdag/core/config/vrijdag_env.dart';
import 'package:vrijdag/core/consent/telemetry_consent.dart';

void main() {
  group('resolveTelemetryConsent', () {
    test('allows telemetry on local without explicit consent', () {
      const config = AppConfig(
        environment: VrijdagEnv.local,
        supabaseUrl: AppConfig.defaultLocalSupabaseUrl,
        supabasePublishableKey: AppConfig.defaultLocalSupabasePublishableKey,
        sentryDsn: null,
        posthogApiKey: null,
        posthogHost: AppConfig.defaultPosthogHost,
        appVersion: '0.1.0+1',
      );

      expect(resolveTelemetryConsent(config), isTrue);
    });

    test('blocks telemetry on production until consent UI ships', () {
      const config = AppConfig(
        environment: VrijdagEnv.production,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'pk',
        sentryDsn: 'https://sentry.example/1',
        posthogApiKey: 'phc_test',
        posthogHost: AppConfig.defaultPosthogHost,
        appVersion: '1.0.0',
      );

      expect(resolveTelemetryConsent(config), isFalse);
    });
  });
}
