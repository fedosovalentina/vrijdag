import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/app_locale_provider.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/core/localization/locale_resolution.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/auth/presentation/sign_in_screen.dart';
import 'package:vrijdag/features/day/presentation/day_screen.dart';
import 'package:vrijdag/features/onboarding/presentation/onboarding_providers.dart';
import 'package:vrijdag/features/onboarding/presentation/onboarding_screen.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';

/// Root widget: Material shell, localization, auth gate.
class VrijdagApp extends ConsumerWidget {
  const VrijdagApp({super.key, this.locale});

  /// Optional locale override (used in widget tests).
  final Locale? locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferred = locale ?? ref.watch(appLocaleProvider);

    return MaterialApp(
      locale: preferred,
      onGenerateTitle: (context) => context.l10n.commonAppName,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: resolveAppLocale,
      theme: buildVrijdagTheme(),
      darkTheme: buildVrijdagTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider);

    return session.when(
      data: (value) => switch (value) {
        AuthSignedIn() => const _SignedInHome(),
        AuthSignedOut() || AuthUnknown() => const SignInScreen(),
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SignInScreen(),
    );
  }
}

class _SignedInHome extends ConsumerWidget {
  const _SignedInHome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarding = ref.watch(onboardingCompletedProvider);

    ref.listen(userProfileProvider, (_, next) {
      final profile = next.asData?.value;
      if (profile == null) {
        return;
      }
      final done = ref.read(onboardingCompletedProvider).asData?.value;
      if (done != true) {
        return;
      }
      ref.read(appLocaleProvider.notifier).state = Locale(profile.language);
    });

    return onboarding.when(
      data: (done) => done ? const DayScreen() : const OnboardingScreen(),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const OnboardingScreen(),
    );
  }
}
