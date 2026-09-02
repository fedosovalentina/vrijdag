import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/core/config/app_config.dart';
import 'package:vrijdag/core/config/vrijdag_env.dart';

void main() {
  group('AppConfig.fromEnvironment', () {
    test('defaults to local Supabase when unset', () {
      const config = AppConfig(
        environment: VrijdagEnv.local,
        supabaseUrl: AppConfig.defaultLocalSupabaseUrl,
        supabasePublishableKey: AppConfig.defaultLocalSupabasePublishableKey,
        sentryDsn: null,
        posthogApiKey: null,
        posthogHost: AppConfig.defaultPosthogHost,
        appVersion: '0.1.0+1',
      );

      expect(config.environment, VrijdagEnv.local);
      expect(config.supabaseUrl, AppConfig.defaultLocalSupabaseUrl);
      expect(config.telemetryAllowedWithoutConsent, isTrue);
    });

    test('VrijdagEnv.parse handles known values', () {
      expect(VrijdagEnv.parse('staging'), VrijdagEnv.staging);
      expect(VrijdagEnv.parse('PRODUCTION'), VrijdagEnv.production);
      expect(VrijdagEnv.parse(null), VrijdagEnv.local);
      expect(VrijdagEnv.parse(''), VrijdagEnv.local);
    });

    test('production requires explicit telemetry consent path', () {
      const config = AppConfig(
        environment: VrijdagEnv.production,
        supabaseUrl: 'https://example.supabase.co',
        supabasePublishableKey: 'pk',
        sentryDsn: 'https://sentry.example/1',
        posthogApiKey: 'phc_test',
        posthogHost: AppConfig.defaultPosthogHost,
        appVersion: '1.0.0',
      );

      expect(config.isProduction, isTrue);
      expect(config.telemetryAllowedWithoutConsent, isFalse);
      expect(config.hasSentry, isTrue);
      expect(config.hasPosthog, isTrue);
    });
  });
}
