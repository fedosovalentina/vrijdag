import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/database/database_providers.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/auth/domain/auth_session.dart';
import 'package:vrijdag/features/auth/domain/profile_defaults.dart';
import 'package:vrijdag/features/auth/presentation/auth_providers.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_editor_screen.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_nav.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/features/calendar/presentation/day_focus_screen.dart';
import 'package:vrijdag/features/calendar/presentation/event_editor_screen.dart';
import 'package:vrijdag/features/calendar/presentation/event_search_screen.dart';
import 'package:vrijdag/features/calendar/presentation/month_feed_view.dart';
import 'package:vrijdag/features/calendar/presentation/year_view.dart';
import 'package:vrijdag/features/settings/presentation/settings_screen.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
import 'package:vrijdag/shared/formatters/spoken_date.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/widgets/date_header.dart';
import 'package:vrijdag/shared/widgets/hour_spine.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/stale_badge.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

/// Signed-in home: Day ↔ List ↔ Year by swipe (DEC-031).
class DayScreen extends ConsumerStatefulWidget {
  const DayScreen({super.key});

  @override
  ConsumerState<DayScreen> createState() => _DayScreenState();
}

class _DayScreenState extends ConsumerState<DayScreen> {
  static const _shellDay = 0;
  static const _shellList = 1;
  static const _shellYear = 2;
  static const _shellCount = 3;

  /// Large enough to swipe both ways; modulo maps to the three shells.
  static const _pageOrigin = 3000;

  var _openedTracked = false;
  late final PageController _pages;
  var _shell = _shellDay;

  @override
  void initState() {
    super.initState();
    _pages = PageController(initialPage: _pageOrigin + _shellDay);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _ensureProfile();
      _trackTodayOpened();
      _applyShell(_shellDay);
    });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  Future<void> _ensureProfile() async {
    if (!mounted) {
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session is! AuthSignedIn) {
      return;
    }

    final language = resolveProfileLanguage(Localizations.localeOf(context));
    final timezone = await resolveDeviceTimezoneId();

    try {
      final profiles = ref.read(userProfileRepositoryProvider);
      await profiles.ensureProfile(
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
    if (_openedTracked || !mounted) {
      return;
    }
    _openedTracked = true;

    final analytics = ref.read(analyticsProvider);
    final events = await ref.read(todaysEventsProvider.future);
    if (!mounted) {
      return;
    }
    final count = events.length;
    await analytics.track(
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

  Future<void> _openEditor({
    PersonalEvent? existing,
    DateTime? initialStartLocal,
  }) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EventEditorScreen(
          existing: existing,
          initialStartLocal: initialStartLocal,
        ),
      ),
    );
    ref.invalidate(dayEventsProvider);
    ref.invalidate(todaysEventsProvider);
    ref.invalidate(visibleEventsProvider);
    ref.invalidate(monthFeedEventsProvider);
    ref.invalidate(pendingWriteCountProvider);
  }

  void _setAnchor(DateTime value) {
    ref.read(calendarAnchorProvider.notifier).state = CalendarRange.dateOnly(
      value,
    );
  }

  void _jumpFeed(DateTime day, {required String target}) {
    final date = CalendarRange.dateOnly(day);
    ref.read(monthFeedJumpProvider.notifier).state = date;
    _setAnchor(date);
    _goToShell(_shellList);
    final bucket = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    ref.read(analyticsProvider).track(FeedJump(target: target, bucket: bucket));
  }

  void _goToToday() {
    final today = CalendarRange.dateOnly(DateTime.now());
    _setAnchor(today);
    if (_shell == _shellList) {
      ref.read(monthFeedJumpProvider.notifier).state = today;
    }
    _goToShell(_shellDay);
    final bucket = '${today.year}-${today.month.toString().padLeft(2, '0')}';
    ref
        .read(analyticsProvider)
        .track(FeedJump(target: 'today', bucket: bucket));
  }

  void _goToShell(int shell) {
    if (!_pages.hasClients) {
      _applyShell(shell);
      return;
    }
    final current = _pages.page?.round() ?? _pageOrigin;
    final currentShell = current % _shellCount;
    var delta = shell - currentShell;
    if (delta > 1) {
      delta -= _shellCount;
    } else if (delta < -1) {
      delta += _shellCount;
    }
    final target = current + delta;
    _pages.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _applyShell(int shell) {
    setState(() => _shell = shell);
    final today = CalendarRange.dateOnly(DateTime.now());
    switch (shell) {
      case _shellDay:
        _setAnchor(today);
        ref.read(calendarScaleProvider.notifier).state = CalendarScale.day;
      case _shellList:
        ref.read(calendarScaleProvider.notifier).state = CalendarScale.month;
      case _shellYear:
        ref.read(calendarScaleProvider.notifier).state = CalendarScale.year;
        final anchor = ref.read(calendarAnchorProvider);
        if (anchor.year != today.year) {
          _setAnchor(DateTime(today.year, today.month, today.day));
        }
    }
  }

  Widget _dayPage(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final today = CalendarRange.dateOnly(DateTime.now());
    final eventsAsync = ref.watch(dayEventsProvider);
    final birthdaysAsync = ref.watch(birthdaysListProvider);
    return _DayBody(
      day: today,
      locale: locale,
      l10n: l10n,
      eventsAsync: eventsAsync,
      birthdaysAsync: birthdaysAsync,
      onOpenEditor: _openEditor,
      onBirthdayTap: (birthday) async {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => BirthdayEditorScreen(existing: birthday),
          ),
        );
        ref.invalidate(birthdaysListProvider);
      },
      onHourTap: (hour) {
        _openEditor(
          initialStartLocal: DateTime(today.year, today.month, today.day, hour),
        );
      },
    );
  }

  Widget _listPage(BuildContext context) {
    return MonthFeedView(
      onOpenSearch: () {
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => EventSearchScreen(
              onOpenEvent: (event) => _openEditor(existing: event),
            ),
          ),
        );
      },
      onOpenDay: (day) {
        final date = CalendarRange.dateOnly(day);
        _setAnchor(date);
        ref.read(monthFeedJumpProvider.notifier).state = date;
        Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => DayFocusScreen(
              day: date,
              onOpenEvent: (event) => _openEditor(existing: event),
            ),
          ),
        );
      },
      onOpenEvent: (event) => _openEditor(existing: event),
      onOpenBirthday: (birthday) async {
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => BirthdayEditorScreen(existing: birthday),
          ),
        );
        ref.invalidate(birthdaysListProvider);
      },
    );
  }

  Widget _yearPage() {
    return YearView(
      onSelectMonth: (value) => _jumpFeed(value, target: 'month'),
      onSelectDay: (value) => _jumpFeed(value, target: 'day'),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(writeQueueReplayControllerProvider);

    final today = CalendarRange.dateOnly(DateTime.now());
    final onDayShell = _shell == _shellDay;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalendarChrome(
              onToday: _goToToday,
              todayDayOfMonth: today.day,
              onTodayActive: onDayShell,
              onNew: () => _openEditor(),
              onSettings: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                // Nested vertical scroll in List / Year; allow cross-axis swipe.
                allowImplicitScrolling: false,
                onPageChanged: (index) {
                  _applyShell(index % _shellCount);
                },
                itemBuilder: (context, index) {
                  return switch (index % _shellCount) {
                    _shellDay => _dayPage(context),
                    _shellList => _listPage(context),
                    _ => _yearPage(),
                  };
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBody extends StatelessWidget {
  const _DayBody({
    required this.day,
    required this.locale,
    required this.l10n,
    required this.eventsAsync,
    required this.birthdaysAsync,
    required this.onOpenEditor,
    required this.onBirthdayTap,
    required this.onHourTap,
  });

  final DateTime day;
  final Locale locale;
  final AppLocalizations l10n;
  final AsyncValue<List<PersonalEvent>> eventsAsync;
  final AsyncValue<List<Birthday>> birthdaysAsync;
  final Future<void> Function({
    PersonalEvent? existing,
    DateTime? initialStartLocal,
  })
  onOpenEditor;
  final ValueChanged<Birthday> onBirthdayTap;
  final ValueChanged<int> onHourTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final birthdaysToday = birthdaysAsync.maybeWhen(
      data: (items) => items.where((b) {
        final occ = Birthday.occurrenceDate(
          year: day.year,
          month: b.month,
          day: b.day,
        );
        return occ.month == day.month && occ.day == day.day;
      }).toList(),
      orElse: () => const <Birthday>[],
    );

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => QuietState(message: l10n.calendarLoadFailed),
      data: (events) {
        final allDay = events.where((e) => e.isAllDay).toList();
        final timed = events.where((e) => !e.isAllDay).toList()
          ..sort((a, b) {
            final aStart = a.timed!.startsAt;
            final bStart = b.timed!.startsAt;
            return aStart.compareTo(bStart);
          });
        final quiet = allDay.isEmpty && timed.isEmpty && birthdaysToday.isEmpty;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DateHeader(
                weekdayLabel: SpokenDate.weekday(day, locale),
                dateLabel: SpokenDate.dayMonth(day, locale),
              ),
              const SyncPendingBanner(),
              for (final birthday in birthdaysToday)
                AllDayMarker(
                  label: l10n.dayTagBirthday,
                  title: () {
                    final age = birthday.ageOn(day);
                    if (age == null) {
                      return birthday.name;
                    }
                    return '${birthday.name} · ${l10n.birthdayAge(age)}';
                  }(),
                  onTap: () => onBirthdayTap(birthday),
                ),
              for (final event in allDay)
                AllDayMarker(
                  label: l10n.dayTagAllDay,
                  title: event.title,
                  onTap: () => onOpenEditor(existing: event),
                ),
              if (quiet) QuietState(message: l10n.calendarEmptyToday),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VrijdagSpacing.page,
                  VrijdagSpacing.xs,
                  VrijdagSpacing.page,
                  VrijdagSpacing.page,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 68,
                      top: 0,
                      bottom: 12,
                      child: Container(width: 1, color: colors.hair),
                    ),
                    if (quiet)
                      HourSpine(onHourTap: onHourTap)
                    else
                      Column(
                        children: HourSpine.busyRows(
                          timed: timed,
                          timeLabel: _formatStart,
                          subtitle: (event) => _meta(l10n, event),
                          onEventTap: (event) => onOpenEditor(existing: event),
                          onHourTap: onHourTap,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static String _formatStart(PersonalEvent event) {
    final start = event.timed!.startsAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)}';
  }

  static String? _meta(AppLocalizations l10n, PersonalEvent event) {
    final timed = event.timed;
    if (timed == null) {
      return null;
    }
    final minutes = timed.endsAt.difference(timed.startsAt).inMinutes;
    final duration = l10n.dayDurationMinutes(minutes < 0 ? 0 : minutes);
    if (event.hasLocation) {
      return '$duration · ${event.location}';
    }
    return duration;
  }
}
