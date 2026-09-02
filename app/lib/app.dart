import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/core/localization/locale_resolution.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/l10n/app_localizations.dart';

/// Root widget: Material shell, localization, bootstrap placeholder.
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D5016)),
        useMaterial3: true,
      ),
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends ConsumerWidget {
  const _BootstrapScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider);
    final supabaseReady = ref.watch(supabaseReadyProvider);

    final supabaseStatus =
        config.supabaseUrl.isEmpty || config.supabasePublishableKey.isEmpty
        ? l10n.bootstrapSupabaseUnavailable
        : supabaseReady
        ? l10n.bootstrapSupabaseConnected
        : l10n.bootstrapSupabaseUnavailable;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commonAppName)),
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
              Text(l10n.bootstrapEnvironment(config.environment.label)),
              const SizedBox(height: 8),
              Text(supabaseStatus),
              const SizedBox(height: 16),
              Text(
                l10n.bootstrapStatusReady,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
