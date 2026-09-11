import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/birthdays/presentation/birthdays_panel.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/features/calendar/presentation/today_events_panel.dart';
import 'package:vrijdag/shared/widgets/component_gallery_screen.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

enum _DayMenuAction { signOut, deleteAccount, componentGallery, testCrash }

/// Signed-in home: Day (Layer 1) — date, personal events, birthdays.
class DayScreen extends ConsumerStatefulWidget {
  const DayScreen({super.key});

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  var _openedTracked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureProfile();
      _trackTodayOpened();
    });
  }

  Future<void> _ensureProfile() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session is! AuthSignedIn) {
      return;
    }

    final language = resolveProfileLanguage(Localizations.localeOf(context));
    final timezone = await resolveDeviceTimezoneId();

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
      // not block Day (reliability before magic).
    }
  }

  Future<void> _trackTodayOpened() async {
    if (_openedTracked) {
      return;
    }
    _openedTracked = true;

    final events = await ref.read(todaysEventsProvider.future);
    final count = events.length;
    await ref
        .read(analyticsProvider)
        .track(
          TodayOpened(
            hasEvents: count > 0,
            eventCountBucket: _eventCountBucket(count),
          ),
        );
  }

  static String _eventCountBucket(int count) {
    if (count <= 0) {
      return '0';
    }
    if (count <= 2) {
      return '1-2';
    }
    if (count <= 5) {
      return '3-5';
    }
    return '6+';
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

    await ref.read(analyticsProvider).track(const AuthSignOutSucceeded());
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
    if (second != true) {
      return;
    }

    try {
      await ref.read(authRepositoryProvider).deleteAccount();
      await ref.read(analyticsProvider).track(const AuthAccountDeleted());
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
    ref.watch(writeQueueReplayControllerProvider);

    final l10n = context.l10n;
    final config = ref.watch(appConfigProvider);
    final locale = Localizations.localeOf(context).toString();
    final spokenDate = DateFormat.MMMMEEEEd(locale).format(DateTime.now());
    final showTestCrash =
        kDebugMode && !config.isProduction && config.hasSentry;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.commonAppName),
        actions: [
          PopupMenuButton<_DayMenuAction>(
            onSelected: (value) async {
              switch (value) {
                case _DayMenuAction.signOut:
                  await _confirmSignOut(context);
                case _DayMenuAction.deleteAccount:
                  await _confirmDelete(context);
                case _DayMenuAction.componentGallery:
                  if (!ComponentGalleryScreen.isAvailable) {
                    return;
                  }
                  if (!context.mounted) {
                    return;
                  }
                  await Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => const ComponentGalleryScreen(),
                    ),
                  );
                case _DayMenuAction.testCrash:
                  ref.read(errorReporterProvider).triggerTestCrash();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _DayMenuAction.signOut,
                child: Text(l10n.authSignOut),
              ),
              PopupMenuItem(
                value: _DayMenuAction.deleteAccount,
                child: Text(l10n.authDeleteAccount),
              ),
              if (ComponentGalleryScreen.isAvailable)
                PopupMenuItem(
                  value: _DayMenuAction.componentGallery,
                  child: Text(l10n.designGalleryTitle),
                ),
              if (showTestCrash)
                PopupMenuItem(
                  value: _DayMenuAction.testCrash,
                  child: Text(l10n.bootstrapTestCrash),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SyncPendingBanner(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      spokenDate,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    const TodayEventsPanel(),
                    const SizedBox(height: 24),
                    const BirthdaysPanel(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
