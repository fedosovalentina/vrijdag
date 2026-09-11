import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/core/localization/locale_resolution.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/auth/presentation/sign_in_screen.dart';
import 'package:vrijdag/features/day/presentation/day_screen.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';

/// Root widget: Material shell, localization, auth gate.
class VrijdagApp extends StatelessWidget {
  const VrijdagApp({super.key, this.locale});

  /// Optional locale override (used in widget tests).
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: locale,
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
        AuthSignedIn() => const DayScreen(),
        AuthSignedOut() || AuthUnknown() => const SignInScreen(),
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SignInScreen(),
    );
  }
}
