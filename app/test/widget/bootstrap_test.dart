import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vrijdag/app.dart';
import 'package:vrijdag/core/analytics/noop_analytics.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/config/app_config.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/config/vrijdag_env.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/errors/noop_error_reporter.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/features/onboarding/presentation/onboarding_providers.dart';

import '../support/fake_auth_repository.dart';
import '../support/memory_birthdays_repository.dart';
import '../support/memory_personal_events_repository.dart';
import '../support/memory_write_queue.dart';

void main() {
  late FakeAuthRepository auth;

  setUp(() {
    SharedPreferences.setMockInitialValues({onboardingCompletedPrefsKey: true});
  });

  tearDown(() async {
    await auth.dispose();
  });

  List<Override> overrides({required AuthSession session}) {
    auth = FakeAuthRepository(session);
    return [
      appConfigProvider.overrideWithValue(
        const AppConfig(
          environment: VrijdagEnv.local,
          supabaseUrl: AppConfig.defaultLocalSupabaseUrl,
          supabasePublishableKey: AppConfig.defaultLocalSupabasePublishableKey,
          sentryDsn: null,
          posthogApiKey: null,
          posthogHost: AppConfig.defaultPosthogHost,
          appVersion: '0.1.0+1',
        ),
      ),
      supabaseReadyProvider.overrideWithValue(true),
      errorReporterProvider.overrideWithValue(NoopErrorReporter()),
      analyticsProvider.overrideWithValue(NoopAnalytics()),
      authRepositoryProvider.overrideWithValue(auth),
      authSessionProvider.overrideWith((ref) => auth.watchSession()),
      writeQueueProvider.overrideWithValue(MemoryWriteQueue()),
      personalEventsRepositoryProvider.overrideWithValue(
        MemoryPersonalEventsRepository(),
      ),
      birthdaysRepositoryProvider.overrideWithValue(
        MemoryBirthdaysRepository(),
      ),
      isOnlineProvider.overrideWith((ref) => Stream.value(true)),
      writeQueueReplayControllerProvider.overrideWith((ref) {}),
      onboardingCompletedProvider.overrideWith((ref) async => true),
    ];
  }

  testWidgets('signed out shows magic link form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(session: const AuthSignedOut()),
        child: const VrijdagApp(locale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Vrijdag'), findsWidgets);
    expect(
      find.text('Your own time, and what sits around it.'),
      findsOneWidget,
    );
    expect(find.text('Sign in with Apple'), findsOneWidget);
    expect(find.text('Send sign-in link'), findsOneWidget);
  });

  testWidgets('signed in shows Day shell without scale tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(
          session: const AuthSignedIn(
            userId: 'user-1',
            email: 'test@example.com',
          ),
        ),
        child: const VrijdagApp(locale: Locale('nl')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('F-001'), findsNothing);
    expect(find.text('Nieuw'), findsOneWidget);
    expect(find.text('Instellingen'), findsOneWidget);
    // Scale jump removed (DEC-031).
    expect(find.text('Dag'), findsNothing);
    expect(find.text('Lijst'), findsNothing);
    expect(find.text('Week'), findsNothing);
    expect(find.text('Maand'), findsNothing);
    expect(find.text('Geen afspraken vandaag.'), findsOneWidget);
    expect(find.text('08'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
    expect(find.text('${DateTime.now().day}'), findsWidgets);

    // Swipe to List shell.
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Geen afspraken vandaag.'), findsNothing);

    // Swipe to Year shell.
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('overzicht'), findsOneWidget);

    // Swipe onward — circular back toward Day.
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Geen afspraken vandaag.'), findsOneWidget);
  });

  testWidgets('signed in Day quiet copy works in English', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(
          session: const AuthSignedIn(
            userId: 'user-1',
            email: 'test@example.com',
          ),
        ),
        child: const VrijdagApp(locale: Locale('en')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No events today.'), findsOneWidget);
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
