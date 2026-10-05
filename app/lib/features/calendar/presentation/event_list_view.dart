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
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

/// Continuous event list for the List shell (DEC-031): day sections with
/// events, not a month grid and not the timed Month feed spine.
class EventListView extends ConsumerStatefulWidget {
  const EventListView({
    super.key,
    required this.onOpenEvent,
    required this.onSelectDay,
    required this.onOpenBirthday,
  });

  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<Birthday> onOpenBirthday;

  @override
  ConsumerState<EventListView> createState() => _EventListViewState();
}

class _EventListViewState extends ConsumerState<EventListView> {
  final _scroll = ScrollController();
  final _keys = <DateTime, GlobalKey>{};
  var _placedToday = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final today = CalendarRange.dateOnly(DateTime.now());
      ref.read(monthFeedWindowProvider.notifier).growTo(today);
      ref
          .read(monthFeedWindowProvider.notifier)
          .growTo(DateTime(today.year, today.month + 2, 1));
      ref
          .read(monthFeedWindowProvider.notifier)
          .growTo(DateTime(today.year, today.month - 1, 1));
    });
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final window = ref.read(monthFeedWindowProvider);
    final max = _scroll.position.maxScrollExtent;
    final offset = _scroll.offset;
    if (offset > max - 800) {
      ref
          .read(monthFeedWindowProvider.notifier)
          .growTo(DateTime(window.to.year, window.to.month + 1, 1));
    }
    if (offset < 400) {
      ref
          .read(monthFeedWindowProvider.notifier)
          .growTo(DateTime(window.from.year, window.from.month - 1, 1));
    }
  }

  GlobalKey _keyFor(DateTime day) {
    final date = CalendarRange.dateOnly(day);
    return _keys.putIfAbsent(date, GlobalKey.new);
  }

  void _scrollToToday() {
    final today = CalendarRange.dateOnly(DateTime.now());
    ref.read(monthFeedWindowProvider.notifier).growTo(today);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ctx = _keyFor(today).currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.15,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final window = ref.watch(monthFeedWindowProvider);
    final eventsAsync = ref.watch(monthFeedEventsProvider);
    final birthdaysAsync = ref.watch(birthdaysListProvider);
    final jump = ref.watch(monthFeedJumpProvider);
    final today = CalendarRange.dateOnly(DateTime.now());

    ref.listen(monthFeedJumpProvider, (_, next) {
      if (next == null) {
        return;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final ctx = _keyFor(next).currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.15,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
          );
        }
        ref.read(monthFeedJumpProvider.notifier).state = null;
      });
    });

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => QuietState(message: l10n.calendarLoadFailed),
      data: (entries) {
        final events = [for (final e in entries) e.event];
        final birthdays = birthdaysAsync.maybeWhen(
          data: (items) => items,
          orElse: () => const <Birthday>[],
        );

        final days = <DateTime>[];
        for (
          var cursor = CalendarRange.dateOnly(window.from);
          cursor.isBefore(window.to);
          cursor = cursor.add(const Duration(days: 1))
        ) {
          final dayEvents = CalendarPresence.eventsOnDay(events, cursor);
          final dayBirthdays = CalendarPresence.birthdaysOnDay(
            birthdays,
            cursor,
          );
          final isToday = cursor == today;
          if (isToday || dayEvents.isNotEmpty || dayBirthdays.isNotEmpty) {
            days.add(cursor);
          }
        }

        if (!_placedToday && jump == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted || _placedToday) {
              return;
            }
            _placedToday = true;
            _scrollToToday();
          });
        }

        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SyncPendingBanner(),
                Expanded(
                  child: days.isEmpty
                      ? QuietState(message: l10n.listEmpty)
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(
                            VrijdagSpacing.page,
                            VrijdagSpacing.sm,
                            VrijdagSpacing.page,
                            VrijdagSpacing.page,
                          ),
                          itemCount: days.length,
                          itemBuilder: (context, index) {
                            final day = days[index];
                            return KeyedSubtree(
                              key: _keyFor(day),
                              child: _ListDaySection(
                                day: day,
                                locale: locale,
                                l10n: l10n,
                                isToday: day == today,
                                events: CalendarPresence.eventsOnDay(
                                  events,
                                  day,
                                ),
                                birthdays: CalendarPresence.birthdaysOnDay(
                                  birthdays,
                                  day,
                                ),
                                onOpenEvent: widget.onOpenEvent,
                                onSelectDay: widget.onSelectDay,
                                onOpenBirthday: widget.onOpenBirthday,
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Semantics(
                button: true,
                label: l10n.chromeBackToToday,
                child: GestureDetector(
                  onTap: _scrollToToday,
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).vrijdagColors.paper,
                      border: Border.all(
                        color: Theme.of(context).vrijdagColors.ink,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${today.day}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: Theme.of(context).vrijdagColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ListDaySection extends StatelessWidget {
  const _ListDaySection({
    required this.day,
    required this.locale,
    required this.l10n,
    required this.isToday,
    required this.events,
    required this.birthdays,
    required this.onOpenEvent,
    required this.onSelectDay,
    required this.onOpenBirthday,
  });

  final DateTime day;
  final Locale locale;
  final AppLocalizations l10n;
  final bool isToday;
  final List<PersonalEvent> events;
  final List<Birthday> birthdays;
  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<DateTime> onSelectDay;
  final ValueChanged<Birthday> onOpenBirthday;

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
              Row(
                children: [
                  if (isToday)
                    Container(
                      width: 3,
                      height: 14,
                      margin: const EdgeInsets.only(right: 6),
                      color: colors.ink,
                    ),
                  Expanded(
                    child: Text(
                      heading,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                        color: colors.ink,
                      ),
                    ),
                  ),
                ],
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
                  _ListLine(
                    timeLabel: null,
                    title: birthday.name,
                    birthday: true,
                    onTap: () => onOpenBirthday(birthday),
                  ),
                for (final event in allDay)
                  _ListLine(
                    timeLabel: l10n.dayTagAllDay,
                    title: event.title,
                    onTap: () => onOpenEvent(event),
                  ),
                for (final event in timed)
                  _ListLine(
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

class _ListLine extends StatelessWidget {
  const _ListLine({
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
