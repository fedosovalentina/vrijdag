import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/app_locale_provider.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/domain/school_holiday_region.dart';
import 'package:vrijdag/features/auth/domain/user_profile.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/birthdays/presentation/birthdays_panel.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
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
    final profile = ref.watch(userProfileProvider).valueOrNull;

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
            title: Text(l10n.settingsLanguage),
            subtitle: Text(
              _languageLabel(l10n, profile?.language),
              style: TextStyle(color: colors.inkSoft),
            ),
            onTap: profile == null
                ? null
                : () => _editLanguage(context, ref, profile),
          ),
          ListTile(
            title: Text(l10n.settingsHomeCity),
            subtitle: Text(
              profile?.homeCity?.isNotEmpty == true
                  ? profile!.homeCity!
                  : l10n.weekDayEmpty,
              style: TextStyle(color: colors.inkSoft),
            ),
            onTap: profile == null
                ? null
                : () => _editHomeCity(context, ref, profile),
          ),
          ListTile(
            title: Text(l10n.settingsSchoolRegion),
            subtitle: Text(
              _regionLabel(l10n, profile?.schoolHolidayRegion),
              style: TextStyle(color: colors.inkSoft),
            ),
            onTap: profile == null
                ? null
                : () => _editSchoolRegion(context, ref, profile),
          ),
          const Divider(),
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

  static String _languageLabel(AppLocalizations l10n, String? language) {
    return switch (language) {
      'nl' => l10n.languageNameNl,
      'en' => l10n.languageNameEn,
      _ => l10n.weekDayEmpty,
    };
  }

  static String _regionLabel(AppLocalizations l10n, String? region) {
    return switch (region) {
      SchoolHolidayRegion.noord => l10n.onboardingRegionNoord,
      SchoolHolidayRegion.centraal => l10n.onboardingRegionCentraal,
      SchoolHolidayRegion.zuid => l10n.onboardingRegionZuid,
      SchoolHolidayRegion.unknown => l10n.onboardingRegionUnknown,
      _ => l10n.weekDayEmpty,
    };
  }

  Future<void> _editLanguage(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = context.l10n;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.settingsLanguage),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('nl'),
              child: Text(l10n.languageNameNl),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop('en'),
              child: Text(l10n.languageNameEn),
            ),
          ],
        );
      },
    );
    if (selected == null || !context.mounted) {
      return;
    }
    await _savePreferences(
      context,
      ref,
      profile: profile,
      language: selected,
      homeCity: profile.homeCity,
      schoolHolidayRegion: profile.schoolHolidayRegion,
    );
    ref.read(appLocaleProvider.notifier).state = Locale(selected);
  }

  Future<void> _editHomeCity(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = context.l10n;
    final controller = TextEditingController(text: profile.homeCity ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.settingsHomeCity),
          content: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
            decoration: InputDecoration(hintText: l10n.settingsHomeCity),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    );
    final city = controller.text;
    controller.dispose();
    if (saved != true || !context.mounted) {
      return;
    }
    await _savePreferences(
      context,
      ref,
      profile: profile,
      language: profile.language,
      homeCity: city.trim().isEmpty ? null : city.trim(),
      schoolHolidayRegion: profile.schoolHolidayRegion,
    );
  }

  Future<void> _editSchoolRegion(
    BuildContext context,
    WidgetRef ref,
    UserProfile profile,
  ) async {
    final l10n = context.l10n;
    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: Text(l10n.settingsSchoolRegion),
          children: [
            for (final option in [
              (SchoolHolidayRegion.noord, l10n.onboardingRegionNoord),
              (SchoolHolidayRegion.centraal, l10n.onboardingRegionCentraal),
              (SchoolHolidayRegion.zuid, l10n.onboardingRegionZuid),
              (SchoolHolidayRegion.unknown, l10n.onboardingRegionUnknown),
            ])
              SimpleDialogOption(
                onPressed: () => Navigator.of(context).pop(option.$1),
                child: Text(option.$2),
              ),
          ],
        );
      },
    );
    if (selected == null || !context.mounted) {
      return;
    }
    await _savePreferences(
      context,
      ref,
      profile: profile,
      language: profile.language,
      homeCity: profile.homeCity,
      schoolHolidayRegion: selected,
    );
  }

  Future<void> _savePreferences(
    BuildContext context,
    WidgetRef ref, {
    required UserProfile profile,
    required String language,
    String? homeCity,
    String? schoolHolidayRegion,
  }) async {
    try {
      await ref
          .read(userProfileRepositoryProvider)
          .updatePreferences(
            userId: profile.id,
            language: language,
            homeCity: homeCity,
            schoolHolidayRegion: schoolHolidayRegion,
          );
      ref.invalidate(userProfileProvider);
    } on Object {
      if (!context.mounted) {
        return;
      }
      // Soft failure — keep current UI values until next refresh.
    }
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
