import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/shared/formatters/spoken_date.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/stale_badge.dart';
import 'package:vrijdag/shared/widgets/hour_spine.dart';

/// One day at full height, opened from the feed's day number (F-017).
class DayFocusScreen extends ConsumerStatefulWidget {
  const DayFocusScreen({
    super.key,
    required this.day,
    required this.onOpenEvent,
  });

  final DateTime day;
  final ValueChanged<PersonalEvent> onOpenEvent;

  @override
  ConsumerState<DayFocusScreen> createState() => _DayFocusScreenState();
}

class _DayFocusScreenState extends ConsumerState<DayFocusScreen> {
  late DateTime _day;

  @override
  void initState() {
    super.initState();
    _day = CalendarRange.dateOnly(widget.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _track());
  }

  Future<void> _track() async {
    final events = await ref.read(focusDayEventsProvider(_day).future);
    if (!mounted) {
      return;
    }
    await ref
        .read(analyticsProvider)
        .track(DayFocusOpened(eventCountBucket: _bucket(events.length)));
  }

  void _shift(int direction) {
    setState(() => _day = _day.add(Duration(days: direction)));
    final date = CalendarRange.dateOnly(_day);
    ref.read(calendarAnchorProvider.notifier).state = date;
    ref.read(monthFeedJumpProvider.notifier).state = date;
    _track();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final events = ref.watch(focusDayEventsProvider(_day));
    final birthdays = ref
        .watch(birthdaysListProvider)
        .maybeWhen(
          data: (items) => items.where((birthday) {
            final occ = Birthday.occurrenceDate(
              year: _day.year,
              month: birthday.month,
              day: birthday.day,
            );
            return occ.month == _day.month && occ.day == _day.day;
          }).toList(),
          orElse: () => const <Birthday>[],
        );

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity;
        if (velocity == null) {
          return;
        }
        if (velocity < -200) {
          _shift(1);
        } else if (velocity > 200) {
          _shift(-1);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${SpokenDate.weekday(_day, locale)} ${SpokenDate.dayMonth(_day, locale)}',
          ),
        ),
        body: events.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => QuietState(message: l10n.calendarLoadFailed),
          data: (items) {
            final allDay = items.where((event) => event.isAllDay).toList();
            final timed = items.where((event) => !event.isAllDay).toList();
            if (allDay.isEmpty && timed.isEmpty && birthdays.isEmpty) {
              return QuietState(message: l10n.calendarEmptyToday);
            }
            return ListView(
              padding: const EdgeInsets.all(VrijdagSpacing.page),
              children: [
                for (final birthday in birthdays)
                  AllDayMarker(
                    label: l10n.dayTagBirthday,
                    title: birthday.name,
                    onTap: null,
                  ),
                for (final event in allDay)
                  AllDayMarker(
                    label: l10n.dayTagAllDay,
                    title: event.title,
                    onTap: () => widget.onOpenEvent(event),
                  ),
                ...HourSpine.busyRows(
                  timed: timed,
                  timeLabel: _formatStart,
                  subtitle: (event) => _meta(l10n, event),
                  onEventTap: widget.onOpenEvent,
                ),
              ],
            );
          },
        ),
      ),
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
    return l10n.dayDurationMinutes(minutes < 0 ? 0 : minutes);
  }

  static String _bucket(int count) {
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
}
