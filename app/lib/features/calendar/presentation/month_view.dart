import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/domain/calendar_presence.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_legend.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/shared/formatters/spoken_date.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/widgets/date_header.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

/// Conventional month grid with presence markers (Task 02 T6).
class MonthView extends ConsumerWidget {
  const MonthView({super.key, required this.onSelectDay});

  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final anchor = ref.watch(calendarAnchorProvider);
    final monthStart = DateTime(anchor.year, anchor.month, 1);
    final eventsAsync = ref.watch(visibleEventsProvider);
    final birthdaysAsync = ref.watch(birthdaysListProvider);

    final zoomLabels = [
      l10n.zoomMonday,
      l10n.zoomTuesday,
      l10n.zoomWednesday,
      l10n.zoomThursday,
      l10n.zoomFriday,
      l10n.zoomSaturday,
      l10n.zoomSunday,
    ];

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => QuietState(message: l10n.calendarLoadFailed),
      data: (events) {
        final birthdays = birthdaysAsync.maybeWhen(
          data: (items) => items,
          orElse: () => const <Birthday>[],
        );
        final daysInMonth = DateTime(anchor.year, anchor.month + 1, 0).day;
        final leading = monthStart.weekday - DateTime.monday;
        final cells = <DateTime?>[
          for (var i = 0; i < leading; i++) null,
          for (var d = 1; d <= daysInMonth; d++)
            DateTime(anchor.year, anchor.month, d),
        ];

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DateHeader(
                weekdayLabel: SpokenDate.seasonName(anchor.month, l10n),
                dateLabel: SpokenDate.monthName(anchor, locale),
              ),
              const SyncPendingBanner(),
              const CalendarLegend(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VrijdagSpacing.page,
                  0,
                  VrijdagSpacing.page,
                  VrijdagSpacing.page,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        for (final label in zoomLabels)
                          Expanded(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).vrijdagColors.warmGrey,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: VrijdagSpacing.xs),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cells.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisExtent: 40,
                          ),
                      itemBuilder: (context, index) {
                        final day = cells[index];
                        if (day == null) {
                          return const SizedBox.shrink();
                        }
                        final hasEvent = CalendarPresence.dayHasEvent(
                          events,
                          day,
                        );
                        final hasBirthday = CalendarPresence.dayHasBirthday(
                          birthdays,
                          day,
                        );
                        final selected =
                            day.year == anchor.year &&
                            day.month == anchor.month &&
                            day.day == anchor.day;
                        final colors = Theme.of(context).vrijdagColors;
                        return InkWell(
                          onTap: () => onSelectDay(day),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${day.day}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: 14,
                                      fontWeight: selected
                                          ? FontWeight.w500
                                          : FontWeight.w400,
                                      color: colors.ink,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              SizedBox(
                                height: 8,
                                child: hasBirthday
                                    ? Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colors.rust,
                                            width: 1.5,
                                          ),
                                        ),
                                      )
                                    : hasEvent
                                    ? Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: colors.ink,
                                          shape: BoxShape.circle,
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          ),
                        );
                      },
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
