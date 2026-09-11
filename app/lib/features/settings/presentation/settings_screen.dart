import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/birthdays/presentation/birthdays_panel.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/widgets/component_gallery_screen.dart';

/// Account and Layer-1 settings (Instellingen). No overflow menu on Day.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).vrijdagColors;
    final config = ref.watch(appConfigProvider);
    final showTestCrash =
        kDebugMode && !config.isProduction && config.hasSentry;
    final session = ref.watch(authSessionProvider).valueOrNull;
    final email = session is AuthSignedIn ? session.email : null;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: VrijdagSpacing.sm),
        children: [
          if (email != null && email.isNotEmpty)
            ListTile(
              title: Text(email, style: TextStyle(color: colors.ink)),
            ),
          ListTile(
            title: Text(l10n.authSignOut),
            onTap: () => _confirmSignOut(context, ref),
          ),
          ListTile(
            title: Text(l10n.authDeleteAccount),
            onTap: () => _confirmDelete(context, ref),
          ),
          const Divider(),
          const BirthdaysPanel(),
          if (ComponentGalleryScreen.isAvailable) ...[
            const Divider(),
            ListTile(
              title: Text(l10n.designGalleryTitle),
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => const ComponentGalleryScreen(),
                  ),
                );
              },
            ),
          ],
          if (showTestCrash)
            ListTile(
              title: Text(l10n.bootstrapTestCrash),
              onTap: () => ref.read(errorReporterProvider).triggerTestCrash(),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final writeQueue = ref.read(writeQueueProvider);
    final analytics = ref.read(analyticsProvider);
    final auth = ref.read(authRepositoryProvider);
    final pending = await writeQueue.pendingCount();
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
                child: Text(l10n.authSignOut),
              ),
            ],
          );
        },
      );
      if (proceed != true) {
        return;
      }
    }

    await analytics.track(const AuthSignOutSucceeded());
    await auth.signOut();
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
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
    if (second != true) {
      return;
    }

    final auth = ref.read(authRepositoryProvider);
    final analytics = ref.read(analyticsProvider);

    try {
      await auth.deleteAccount();
      await analytics.track(const AuthAccountDeleted());
    } on Object {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authDeleteFailed)));
    }
  }
}
