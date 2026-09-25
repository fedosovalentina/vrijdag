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

/// Signed-in calendar home: Day / List / Year (DEC-030).
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
      if (!mounted) {
        return;
      }
      _ensureProfile();
      _trackTodayOpened();
    });
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
    _setScale(CalendarScale.month);
    final bucket = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    ref.read(analyticsProvider).track(FeedJump(target: target, bucket: bucket));
  }

  void _goToToday() {
    final today = CalendarRange.dateOnly(DateTime.now());
    final scale = ref.read(calendarScaleProvider);
    _setAnchor(today);
    switch (scale) {
      case CalendarScale.day:
        break;
      case CalendarScale.week:
        // Week chrome removed (DEC-030); treat as list.
        _setScale(CalendarScale.month);
        ref.read(monthFeedJumpProvider.notifier).state = today;
      case CalendarScale.month:
        ref.read(monthFeedJumpProvider.notifier).state = today;
      case CalendarScale.year:
        break;
    }
    final bucket = '${today.year}-${today.month.toString().padLeft(2, '0')}';
    ref
        .read(analyticsProvider)
        .track(FeedJump(target: 'today', bucket: bucket));
  }

  void _setScale(CalendarScale value) {
    // Week is no longer in chrome (DEC-030).
    final next = value == CalendarScale.week ? CalendarScale.month : value;
    ref.read(calendarScaleProvider.notifier).state = next;
  }

  void _shiftWithinScale(int direction) {
    final scale = ref.read(calendarScaleProvider);
    final anchor = ref.read(calendarAnchorProvider);
    switch (scale) {
      case CalendarScale.day:
        _setAnchor(anchor.add(Duration(days: direction)));
      case CalendarScale.week:
        _setAnchor(anchor.add(Duration(days: 7 * direction)));
      case CalendarScale.month:
        _setAnchor(_shiftMonth(anchor, direction));
      case CalendarScale.year:
        _setAnchor(DateTime(anchor.year + direction, anchor.month, anchor.day));
    }
  }

  static DateTime _shiftMonth(DateTime anchor, int direction) {
    final first = DateTime(anchor.year, anchor.month + direction, 1);
    final last = DateTime(first.year, first.month + 1, 0).day;
    final day = anchor.day > last ? last : anchor.day;
    return DateTime(first.year, first.month, day);
  }

  void _selectWeekday(int weekday) {
    final anchor = ref.read(calendarAnchorProvider);
    final start = CalendarRange.startOfWeek(anchor);
    _setAnchor(start.add(Duration(days: weekday - DateTime.monday)));
  }

  List<CalendarZoomItem> _zoomItems({
    required CalendarScale scale,
    required DateTime day,
    required AppLocalizations l10n,
    required Locale locale,
  }) {
    switch (scale) {
      case CalendarScale.day:
        final labels = [
          l10n.zoomMonday,
          l10n.zoomTuesday,
          l10n.zoomWednesday,
          l10n.zoomThursday,
          l10n.zoomFriday,
          l10n.zoomSaturday,
          l10n.zoomSunday,
        ];
        return [
          for (var i = 0; i < 7; i++)
            CalendarZoomItem(
              label: labels[i],
              selected: day.weekday == DateTime.monday + i,
              onTap: () => _selectWeekday(DateTime.monday + i),
            ),
        ];
      case CalendarScale.week:
      case CalendarScale.month:
      case CalendarScale.year:
        // List and Year carry their own headers; Week is unused (DEC-030).
        return const [];
    }
  }

  String _zoomSemantic(CalendarScale scale, AppLocalizations l10n) {
    return switch (scale) {
      CalendarScale.day => l10n.navZoomWeekdays,
      CalendarScale.week || CalendarScale.month => l10n.navList,
      CalendarScale.year => l10n.navYear,
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(writeQueueReplayControllerProvider);

    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final scale = ref.watch(calendarScaleProvider);
    final anchor = ref.watch(calendarAnchorProvider);
    final day = CalendarRange.dateOnly(anchor);
    final today = CalendarRange.dateOnly(DateTime.now());
    final viewingToday = day == today;
    final eventsAsync = ref.watch(dayEventsProvider);
    final birthdaysAsync = ref.watch(birthdaysListProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalendarNav(
              scale: scale,
              zoomSemanticLabel: _zoomSemantic(scale, l10n),
              zoomItems: _zoomItems(
                scale: scale,
                day: day,
                l10n: l10n,
                locale: locale,
              ),
              onScaleSelected: _setScale,
              onToday: _goToToday,
              todayDayOfMonth: today.day,
              onTodayActive: viewingToday && scale == CalendarScale.day,
              onNew: () => _openEditor(),
              onSettings: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (scale == CalendarScale.month) {
                    return;
                  }
                  final v = details.primaryVelocity;
                  if (v == null) {
                    return;
                  }
                  if (v < -200) {
                    _shiftWithinScale(1);
                  } else if (v > 200) {
                    _shiftWithinScale(-1);
                  }
                },
                child: switch (scale) {
                  CalendarScale.day => _DayBody(
                    day: day,
                    locale: locale,
                    l10n: l10n,
                    eventsAsync: eventsAsync,
                    birthdaysAsync: birthdaysAsync,
                    onOpenEditor: _openEditor,
                    onBirthdayTap: (birthday) async {
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              BirthdayEditorScreen(existing: birthday),
                        ),
                      );
                      ref.invalidate(birthdaysListProvider);
                    },
                    onHourTap: (hour) {
                      _openEditor(
                        initialStartLocal: DateTime(
                          day.year,
                          day.month,
                          day.day,
                          hour,
                        ),
                      );
                    },
                  ),
                  // Week chrome removed (DEC-030); show the continuous list.
                  CalendarScale.week || CalendarScale.month => MonthFeedView(
                    onOpenYear: () => _setScale(CalendarScale.year),
                    onOpenSearch: () {
                      Navigator.of(context).push<void>(
                        MaterialPageRoute(
                          builder: (_) => EventSearchScreen(
                            onOpenEvent: (event) =>
                                _openEditor(existing: event),
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
                            onOpenEvent: (event) =>
                                _openEditor(existing: event),
                          ),
                        ),
                      );
                    },
                    onOpenEvent: (event) => _openEditor(existing: event),
                    onOpenBirthday: (birthday) async {
                      await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) =>
                              BirthdayEditorScreen(existing: birthday),
                        ),
                      );
                      ref.invalidate(birthdaysListProvider);
                    },
                  ),
                  CalendarScale.year => YearView(
                    onSelectMonth: (value) => _jumpFeed(value, target: 'month'),
                    onSelectDay: (value) => _jumpFeed(value, target: 'day'),
                  ),
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
