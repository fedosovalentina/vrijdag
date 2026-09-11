import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/domain/calendar_presence.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_legend.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/shared/formatters/spoken_date.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/widgets/date_header.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

/// 3×4 month map with presence ticks (Task 02 Year). Not mini-calendars.
class YearView extends ConsumerWidget {
  const YearView({super.key, required this.onSelectMonth});

  final ValueChanged<DateTime> onSelectMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final anchor = ref.watch(calendarAnchorProvider);
    final year = anchor.year;
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
              DateHeader(weekdayLabel: l10n.yearOverview, dateLabel: '$year'),
              const SyncPendingBanner(),
              const CalendarLegend(),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  10,
                  4,
                  10,
                  VrijdagSpacing.page,
                ),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 12,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 6,
                    mainAxisExtent: 72,
                  ),
                  itemBuilder: (context, index) {
                    final month = index + 1;
                    final monthDate = DateTime(year, month, 1);
                    final ticks = _ticksForMonth(
                      year: year,
                      month: month,
                      events: events,
                      birthdays: birthdays,
                    );
                    final colors = Theme.of(context).vrijdagColors;
                    return Material(
                      color: colors.paper,
                      borderRadius: BorderRadius.circular(VrijdagRadii.control),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(
                          VrijdagRadii.control,
                        ),
                        onTap: () => onSelectMonth(monthDate),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                SpokenDate.monthShort(monthDate, locale),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: colors.ink,
                                    ),
                              ),
                              const SizedBox(height: VrijdagSpacing.xs),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: [
                                  for (final tick in ticks)
                                    tick.isBirthday
                                        ? Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: colors.rust,
                                                width: 1.5,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            width: 6,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: colors.ink,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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

  static List<_YearTick> _ticksForMonth({
    required int year,
    required int month,
    required List<PersonalEvent> events,
    required List<Birthday> birthdays,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final ticks = <_YearTick>[];
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(year, month, d);
      final bday = CalendarPresence.dayHasBirthday(birthdays, day);
      final hasEvent = CalendarPresence.dayHasEvent(events, day);
      if (bday) {
        ticks.add(const _YearTick(isBirthday: true));
      } else if (hasEvent) {
        ticks.add(const _YearTick(isBirthday: false));
      }
      if (ticks.length >= 10) {
        break;
      }
    }
    return ticks;
  }
}

class _YearTick {
  const _YearTick({required this.isBirthday});

  final bool isBirthday;
}
