import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/domain/calendar_presence.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/l10n/app_localizations.dart';
import 'package:vrijdag/shared/formatters/spoken_date.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/widgets/date_header.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

/// Seven day-fragments (Task 04 Week). Not an hour grid.
class WeekView extends ConsumerWidget {
  const WeekView({
    super.key,
    required this.onOpenEvent,
    required this.onSelectDay,
  });

  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final anchor = ref.watch(calendarAnchorProvider);
    final weekStart = CalendarRange.startOfWeek(anchor);
    final week = CalendarRange.isoWeek(anchor);
    final eventsAsync = ref.watch(visibleEventsProvider);
    final birthdaysAsync = ref.watch(birthdaysListProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => QuietState(message: l10n.calendarLoadFailed),
      data: (events) {
        final birthdays = birthdaysAsync.maybeWhen(
          data: (items) => items,
          orElse: () => const <Birthday>[],
        );

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DateHeader(
                weekdayLabel: l10n.weekHeading(week),
                dateLabel: SpokenDate.weekRange(weekStart, locale),
              ),
              const SyncPendingBanner(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VrijdagSpacing.page,
                  VrijdagSpacing.sm,
                  VrijdagSpacing.page,
                  VrijdagSpacing.page,
                ),
                child: Column(
                  children: [
                    for (var i = 0; i < 7; i++)
                      _WeekDayFragment(
                        day: weekStart.add(Duration(days: i)),
                        locale: locale,
                        l10n: l10n,
                        events: CalendarPresence.eventsOnDay(
                          events,
                          weekStart.add(Duration(days: i)),
                        ),
                        birthdays: CalendarPresence.birthdaysOnDay(
                          birthdays,
                          weekStart.add(Duration(days: i)),
                        ),
                        onOpenEvent: onOpenEvent,
                        onSelectDay: onSelectDay,
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
}

class _WeekDayFragment extends StatelessWidget {
  const _WeekDayFragment({
    required this.day,
    required this.locale,
    required this.l10n,
    required this.events,
    required this.birthdays,
    required this.onOpenEvent,
    required this.onSelectDay,
  });

  final DateTime day;
  final Locale locale;
  final AppLocalizations l10n;
  final List<PersonalEvent> events;
  final List<Birthday> birthdays;
  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final weekday = SpokenDate.weekday(day, locale);
    final short = SpokenDate.monthShort(day, locale);
    final heading = '$weekday ${day.day} $short';

    final timed = events.where((e) => !e.isAllDay).toList()
      ..sort((a, b) => a.timed!.startsAt.compareTo(b.timed!.startsAt));
    final allDay = events.where((e) => e.isAllDay).toList();
    final empty = timed.isEmpty && allDay.isEmpty && birthdays.isEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.hair)),
      ),
      child: InkWell(
        onTap: () => onSelectDay(day),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                heading,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: colors.ink,
                ),
              ),
              const SizedBox(height: 6),
              if (empty)
                Text(
                  l10n.weekDayEmpty,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colors.warmGrey),
                )
              else ...[
                for (final birthday in birthdays)
                  _WeekLine(
                    timeLabel: null,
                    title: birthday.name,
                    birthday: true,
                  ),
                for (final event in allDay)
                  _WeekLine(
                    timeLabel: l10n.dayTagAllDay,
                    title: event.title,
                    onTap: () => onOpenEvent(event),
                  ),
                for (final event in timed)
                  _WeekLine(
                    timeLabel: _formatStart(event),
                    title: event.title,
                    onTap: () => onOpenEvent(event),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _formatStart(PersonalEvent event) {
    final start = event.timed!.startsAt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)}';
  }
}

class _WeekLine extends StatelessWidget {
  const _WeekLine({
    required this.timeLabel,
    required this.title,
    this.birthday = false,
    this.onTap,
  });

  final String? timeLabel;
  final String title;
  final bool birthday;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: VrijdagSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: timeLabel == null
                  ? null
                  : Text(
                      timeLabel!,
                      textAlign: TextAlign.right,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: colors.warmGrey,
                      ),
                    ),
            ),
            const SizedBox(width: VrijdagSpacing.sm),
            SizedBox(
              width: 16,
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: birthday
                      ? Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.rust, width: 2),
                          ),
                        )
                      : Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors.ink,
                            shape: BoxShape.circle,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: VrijdagSpacing.sm),
            Expanded(
              child: Text(
                title,
                softWrap: true,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  color: colors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
