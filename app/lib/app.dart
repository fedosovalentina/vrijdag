import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/core/localization/locale_resolution.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/auth/presentation/sign_in_screen.dart';
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
        AuthSignedIn() => const _HomeScreen(),
        AuthSignedOut() || AuthUnknown() => const SignInScreen(),
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => const SignInScreen(),
    );
  }
}

class _HomeScreen extends ConsumerStatefulWidget {
  const _HomeScreen();

  @override
  ConsumerState<_HomeScreen> createState() => _HomeScreenState();
}

enum _HomeMenuAction { signOut, deleteAccount }

class _HomeScreenState extends ConsumerState<_HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfile();
    });
  }

  Future<void> _ensureProfile() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session is! AuthSignedIn) {
      return;
    }

    final language = resolveProfileLanguage(Localizations.localeOf(context));
    final timezone = resolveDeviceTimezone();

    try {
      await ref
          .read(userProfileRepositoryProvider)
          .ensureProfile(
            userId: session.userId,
            language: language,
            timezone: timezone,
          );
    } on Object {
      // Profile trigger may already have created the row; sync failures must
      // not block the home shell (reliability before magic).
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final pending = await ref.read(writeQueueProvider).pendingCount();
    if (pending > 0) {
      if (!context.mounted) {
        return;
      }
      final proceed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.authSignOutPendingTitle),
            content: Text(l10n.authSignOutPendingBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.authSignOutPendingContinue),
              ),
            ],
          );
        },
      );
      if (proceed != true) {
        return;
      }
    }
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = context.l10n;
    final first = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.authDeleteConfirmTitle),
          content: Text(l10n.authDeleteConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.authDeleteConfirmContinue),
            ),
          ],
        );
      },
    );
    if (first != true || !context.mounted) {
      return;
    }

    final second = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.authDeleteFinalTitle),
          content: Text(l10n.authDeleteFinalBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.authDeleteFinalAction),
            ),
          ],
        );
      },
    );
    if (second != true || !context.mounted) {
      return;
    }

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authDeleteFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider);
    final supabaseReady = ref.watch(supabaseReadyProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;

    final supabaseStatus =
        config.supabaseUrl.isEmpty || config.supabasePublishableKey.isEmpty
        ? l10n.bootstrapSupabaseUnavailable
        : supabaseReady
        ? l10n.bootstrapSupabaseConnected
        : l10n.bootstrapSupabaseUnavailable;
    final sentryStatus = config.hasSentry
        ? l10n.bootstrapSentryReady
        : l10n.bootstrapSentryUnavailable;
    final showTestCrash =
        kDebugMode && !config.isProduction && config.hasSentry;

    final email = switch (session) {
      AuthSignedIn(:final email, :final userId) => email ?? userId,
      _ => '',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commonAppName),
        actions: [
          PopupMenuButton<_HomeMenuAction>(
            onSelected: (value) async {
              switch (value) {
                case _HomeMenuAction.signOut:
                  await _confirmSignOut(context);
                case _HomeMenuAction.deleteAccount:
                  await _confirmDelete(context);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _HomeMenuAction.signOut,
                child: Text(l10n.authSignOut),
              ),
              PopupMenuItem(
                value: _HomeMenuAction.deleteAccount,
                child: Text(l10n.authDeleteAccount),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.commonAppName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.bootstrapFoundationMessage,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(l10n.authSignedInAs(email)),
              const SizedBox(height: 8),
              Text(l10n.bootstrapEnvironment(config.environment.label)),
              const SizedBox(height: 8),
              Text(supabaseStatus),
              const SizedBox(height: 8),
              Text(sentryStatus),
              const SizedBox(height: 16),
              Text(
                l10n.bootstrapStatusReady,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (showTestCrash) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () =>
                      ref.read(errorReporterProvider).triggerTestCrash(),
                  child: Text(l10n.bootstrapTestCrash),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
