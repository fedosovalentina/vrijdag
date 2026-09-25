import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/domain/calendar_presence.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_legend.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/shared/formatters/spoken_date.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/widgets/date_header.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

/// Year as twelve mini month grids. Today is circled; presence is quiet.
///
/// Product override of Task 02 “ticks only” Year map (dogfood 2026-09-25).
class YearView extends ConsumerWidget {
  const YearView({
    super.key,
    required this.onSelectMonth,
    required this.onSelectDay,
  });

  final ValueChanged<DateTime> onSelectMonth;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final anchor = ref.watch(calendarAnchorProvider);
    final year = anchor.year;
    final today = CalendarRange.dateOnly(DateTime.now());
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
        final weekdayLabels = [
          l10n.zoomMonday,
          l10n.zoomTuesday,
          l10n.zoomWednesday,
          l10n.zoomThursday,
          l10n.zoomFriday,
          l10n.zoomSaturday,
          l10n.zoomSunday,
        ];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DateHeader(weekdayLabel: l10n.yearOverview, dateLabel: '$year'),
              const SyncPendingBanner(),
              const CalendarLegend(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VrijdagSpacing.sm,
                  VrijdagSpacing.xs,
                  VrijdagSpacing.sm,
                  VrijdagSpacing.page,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = VrijdagSpacing.sm;
                    final cellWidth = (constraints.maxWidth - gap * 2) / 3;
                    // Title + weekday row + up to 6 week rows.
                    const cellHeight = 148.0;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var month = 1; month <= 12; month++)
                          SizedBox(
                            width: cellWidth,
                            height: cellHeight,
                            child: _MiniMonth(
                              year: year,
                              month: month,
                              locale: locale,
                              weekdayLabels: weekdayLabels,
                              today: today,
                              events: events,
                              birthdays: birthdays,
                              onSelectMonth: onSelectMonth,
                              onSelectDay: onSelectDay,
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MiniMonth extends StatelessWidget {
  const _MiniMonth({
    required this.year,
    required this.month,
    required this.locale,
    required this.weekdayLabels,
    required this.today,
    required this.events,
    required this.birthdays,
    required this.onSelectMonth,
    required this.onSelectDay,
  });

  final int year;
  final int month;
  final Locale locale;
  final List<String> weekdayLabels;
  final DateTime today;
  final List<PersonalEvent> events;
  final List<Birthday> birthdays;
  final ValueChanged<DateTime> onSelectMonth;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final monthDate = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final leading = monthDate.weekday - DateTime.monday;
    final cells = <DateTime?>[
      for (var i = 0; i < leading; i++) null,
      for (var d = 1; d <= daysInMonth; d++) DateTime(year, month, d),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () => onSelectMonth(monthDate),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              SpokenDate.monthShort(monthDate, locale),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colors.ink,
              ),
            ),
          ),
        ),
        Row(
          children: [
            for (final label in weekdayLabels)
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    color: colors.warmGrey,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        Expanded(
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cells.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisExtent: 16,
            ),
            itemBuilder: (context, index) {
              final day = cells[index];
              if (day == null) {
                return const SizedBox.shrink();
              }
              final isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final hasBirthday = CalendarPresence.dayHasBirthday(
                birthdays,
                day,
              );
              final hasEvent = CalendarPresence.dayHasEvent(events, day);
              return InkWell(
                onTap: () => onSelectDay(day),
                customBorder: const CircleBorder(),
                child: Center(
                  child: _DayCell(
                    day: day.day,
                    isToday: isToday,
                    hasEvent: hasEvent,
                    hasBirthday: hasBirthday,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isToday,
    required this.hasEvent,
    required this.hasBirthday,
  });

  final int day;
  final bool isToday;
  final bool hasEvent;
  final bool hasBirthday;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final ink = hasBirthday
        ? colors.rust
        : hasEvent
        ? colors.ink
        : colors.inkSoft;

    return SizedBox(
      width: 16,
      height: 16,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: isToday ? Border.all(color: colors.ink, width: 1.25) : null,
        ),
        child: Center(
          child: Text(
            '$day',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 9,
              height: 1,
              fontWeight: isToday || hasEvent || hasBirthday
                  ? FontWeight.w600
                  : FontWeight.w400,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: ink,
            ),
          ),
        ),
      ),
    );
  }
}
