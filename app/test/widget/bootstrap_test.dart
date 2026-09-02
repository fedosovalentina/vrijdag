import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vrijdag/app.dart';
import 'package:vrijdag/core/analytics/noop_analytics.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/config/app_config.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/config/vrijdag_env.dart';
import 'package:vrijdag/core/errors/noop_error_reporter.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';

void main() {
  testWidgets('bootstrap screen shows localized Dutch copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: VrijdagEnv.local,
              supabaseUrl: AppConfig.defaultLocalSupabaseUrl,
              supabasePublishableKey:
                  AppConfig.defaultLocalSupabasePublishableKey,
              sentryDsn: null,
              posthogApiKey: null,
              posthogHost: AppConfig.defaultPosthogHost,
              appVersion: '0.1.0+1',
            ),
          ),
          supabaseReadyProvider.overrideWithValue(true),
          errorReporterProvider.overrideWithValue(NoopErrorReporter()),
          analyticsProvider.overrideWithValue(NoopAnalytics()),
        ],
        child: const VrijdagApp(locale: Locale('nl')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vrijdag'), findsWidgets);
    expect(find.textContaining('F-001'), findsOneWidget);
    expect(find.text('Omgeving: local'), findsOneWidget);
    expect(find.text('Supabase-client gereed.'), findsOneWidget);
    expect(find.text('Omgevingsskelet gereed.'), findsOneWidget);
  });

  testWidgets('bootstrap screen shows localized English copy', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: VrijdagEnv.staging,
              supabaseUrl: '',
              supabasePublishableKey: '',
              sentryDsn: null,
              posthogApiKey: null,
              posthogHost: AppConfig.defaultPosthogHost,
              appVersion: '0.1.0+1',
            ),
          ),
          supabaseReadyProvider.overrideWithValue(false),
          errorReporterProvider.overrideWithValue(NoopErrorReporter()),
          analyticsProvider.overrideWithValue(NoopAnalytics()),
        ],
        child: const VrijdagApp(locale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Environment: staging'), findsOneWidget);
    expect(find.text('Supabase not configured.'), findsOneWidget);
    expect(find.text('Environment scaffold ready.'), findsOneWidget);
  });
}
