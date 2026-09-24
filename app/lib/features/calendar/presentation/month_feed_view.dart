import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/domain/calendar_presence.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_entry.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_frame.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_row.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_scale.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_slots.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/presentation/calendar_providers.dart';
import 'package:vrijdag/shared/formatters/spoken_date.dart';
import 'package:vrijdag/shared/theme/vrijdag_theme.dart';
import 'package:vrijdag/shared/theme/vrijdag_tokens.dart';
import 'package:vrijdag/shared/widgets/quiet_state.dart';

/// Continuous month feed. Replaces the month grid (F-011, DEC-029).
class MonthFeedView extends ConsumerStatefulWidget {
  const MonthFeedView({
    super.key,
    required this.onOpenEvent,
    required this.onOpenBirthday,
  });

  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<Birthday> onOpenBirthday;

  @override
  ConsumerState<MonthFeedView> createState() => _MonthFeedViewState();
}

class _MonthFeedViewState extends ConsumerState<MonthFeedView> {
  final _scroll = ScrollController();
  Timer? _clock;
  DateTime _now = DateTime.now();
  DateTime? _jumpedFor;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    final pos = _scroll.position;
    if (pos.maxScrollExtent < 48) {
      return;
    }
    final window = ref.read(monthFeedWindowProvider);
    if (pos.pixels < 240) {
      ref
          .read(monthFeedWindowProvider.notifier)
          .growTo(window.from.subtract(const Duration(days: 1)));
    }
    if (pos.maxScrollExtent - pos.pixels < 240) {
      ref.read(monthFeedWindowProvider.notifier).growTo(window.to);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final eventsAsync = ref.watch(monthFeedEventsProvider);
    final birthdays = ref
        .watch(birthdaysListProvider)
        .maybeWhen(data: (items) => items, orElse: () => const <Birthday>[]);
    final window = ref.watch(monthFeedWindowProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => QuietState(message: l10n.calendarLoadFailed),
      data: (entries) {
        final ranges = <FeedWallRange>[
          for (final entry in entries)
            if (entry.event.timed != null)
              FeedWallRange(
                startMinute: _minute(entry.event.timed!.startsAt.toLocal()),
                endMinute: _minute(entry.event.timed!.endsAt.toLocal()),
              ),
        ];
        final computed = FeedScale.fromWallRanges(ranges);
        final spans = _spans(entries);
        final assigned = assignFeedSlots(spans);
        final used = assigned
            .where((s) => s.slot >= 0)
            .fold<int>(1, (max, s) => s.slot + 1 > max ? s.slot + 1 : max);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          ref
              .read(monthFeedWindowProvider.notifier)
              .adoptScale(computed, slots: used);
        });
        final scale = window.scale ?? computed;
        final slotCount = window.slotCount < used ? used : window.slotCount;
        return _FeedList(
          scroll: _scroll,
          window: window,
          entries: entries,
          birthdays: birthdays,
          scale: scale,
          slotCount: slotCount,
          slots: {for (final s in assigned) s.id: s.slot},
          now: _now,
          locale: locale,
          onOpenEvent: widget.onOpenEvent,
          onOpenBirthday: widget.onOpenBirthday,
          onJumpReady: (offset) {
            final month = DateTime(window.from.year, window.from.month);
            if (_jumpedFor == month || !_scroll.hasClients) {
              return;
            }
            final viewport = _scroll.position.viewportDimension;
            final target = (offset - viewport / 3).clamp(
              0.0,
              _scroll.position.maxScrollExtent,
            );
            _scroll.jumpTo(target);
            _jumpedFor = month;
          },
        );
      },
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.scroll,
    required this.window,
    required this.entries,
    required this.birthdays,
    required this.scale,
    required this.slotCount,
    required this.slots,
    required this.now,
    required this.locale,
    required this.onOpenEvent,
    required this.onOpenBirthday,
    required this.onJumpReady,
  });

  final ScrollController scroll;
  final MonthFeedWindow window;
  final List<FeedEntry> entries;
  final List<Birthday> birthdays;
  final FeedScale scale;
  final int slotCount;
  final Map<String, int> slots;
  final DateTime now;
  final Locale locale;
  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<Birthday> onOpenBirthday;
  final ValueChanged<double> onJumpReady;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final l10n = context.l10n;
    final weekdayWidth = _weekdayColumnWidth(context, locale);
    final slotWidth =
        14.0 * slotCount + (slotCount > 1 ? 2.0 * (slotCount - 1) : 0);
    final spineX = 28 + weekdayWidth + slotWidth;
    final months = _months(window.from, window.to);
    var running = 0.0;
    double? todayOffset;

    final slivers = <Widget>[];
    for (var m = 0; m < months.length; m++) {
      final month = months[m];
      final header = 46.0;
      if (m == 0) {
        running += header;
      } else {
        running += header + 8;
      }
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: _MonthHeaderDelegate(
            month: month,
            locale: locale,
            scale: scale,
            spineX: spineX,
            topGap: m == 0 ? 0 : 8,
          ),
        ),
      );
      final days = DateTime(month.year, month.month + 1, 0).day;
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final day = DateTime(month.year, month.month, index + 1);
            final dayEntries = entries
                .where((e) => CalendarPresence.eventOverlapsDay(e.event, day))
                .toList();
            final dayBirthdays = CalendarPresence.birthdaysOnDay(
              birthdays,
              day,
            );
            final timed =
                dayEntries.where((e) => e.event.timed != null).toList()..sort(
                  (a, b) => compareFeedEvents(
                    aUntimed: false,
                    aStart: _minute(a.event.timed!.startsAt.toLocal()),
                    bUntimed: false,
                    bStart: _minute(b.event.timed!.startsAt.toLocal()),
                  ),
                );
            final singleAllDay = dayEntries.where((e) {
              final event = e.event;
              return event.isAllDay && !_multiDay(event);
            }).toList();
            final chips = [...singleAllDay, ...timed];
            return _DayRow(
              day: day,
              chips: chips,
              birthdays: dayBirthdays,
              spans: _spansOn(day, entries, slots),
              scale: scale,
              slotCount: slotCount,
              weekdayWidth: weekdayWidth,
              now: now,
              locale: locale,
              l10nNow: l10n.feedNow,
              moreLabel: l10n.feedMore,
              lessLabel: l10n.feedShowLess,
              dstLabel: _dstLabel(day, l10n.feedDstPlus, l10n.feedDstMinus),
              onOpenEvent: onOpenEvent,
              onOpenBirthday: onOpenBirthday,
            );
          }, childCount: days),
        ),
      );
      for (var d = 1; d <= days; d++) {
        final day = DateTime(month.year, month.month, d);
        final count = entries
            .where(
              (e) =>
                  CalendarPresence.eventOverlapsDay(e.event, day) &&
                  (e.event.timed != null || !_multiDay(e.event)),
            )
            .length;
        final birthdayOnly =
            CalendarPresence.birthdaysOnDay(birthdays, day).isNotEmpty &&
            count == 0;
        final height = layoutFeedDay(birthdayOnly ? 1 : count).rowHeight;
        final today =
            day.year == now.year &&
            day.month == now.month &&
            day.day == now.day;
        if (today) {
          todayOffset = running;
        }
        running += height;
      }
    }

    if (todayOffset != null) {
      final offset = todayOffset;
      WidgetsBinding.instance.addPostFrameCallback((_) => onJumpReady(offset));
    }

    return Stack(
      children: [
        CustomScrollView(controller: scroll, slivers: slivers),
        Positioned(
          left: spineX,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: ColoredBox(
              color: colors.dust,
              child: const SizedBox(width: 1),
            ),
          ),
        ),
      ],
    );
  }
}

class _DayRow extends StatefulWidget {
  const _DayRow({
    required this.day,
    required this.chips,
    required this.birthdays,
    required this.spans,
    required this.scale,
    required this.slotCount,
    required this.weekdayWidth,
    required this.now,
    required this.locale,
    required this.l10nNow,
    required this.moreLabel,
    required this.lessLabel,
    required this.dstLabel,
    required this.onOpenEvent,
    required this.onOpenBirthday,
  });

  final DateTime day;
  final List<FeedEntry> chips;
  final List<Birthday> birthdays;
  final List<({int slot, PersonalEvent event})> spans;
  final FeedScale scale;
  final int slotCount;
  final double weekdayWidth;
  final DateTime now;
  final Locale locale;
  final String l10nNow;
  final String Function(int count) moreLabel;
  final String lessLabel;
  final String? dstLabel;
  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<Birthday> onOpenBirthday;

  @override
  State<_DayRow> createState() => _DayRowState();
}

class _DayRowState extends State<_DayRow> {
  var _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final today = _sameDay(widget.day, widget.now);
    final past = widget.day.isBefore(
      DateTime(widget.now.year, widget.now.month, widget.now.day),
    );
    final layout = layoutFeedDay(widget.chips.length, expanded: _expanded);
    final shown = _expanded
        ? widget.chips
        : widget.chips.take(widget.chips.length > 3 ? 3 : widget.chips.length);
    final onlyBirthday = widget.chips.isEmpty && widget.birthdays.isNotEmpty;
    final weekday = DateFormat.E(
      widget.locale.toLanguageTag(),
    ).format(widget.day);

    return SizedBox(
      height: onlyBirthday ? 34 : layout.rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Row(
                children: [
                  if (today) Container(width: 3, height: 14, color: colors.ink),
                  Text(
                    '${widget.day.day}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: today ? FontWeight.w700 : FontWeight.w400,
                      color: past && !today ? colors.warmGrey : colors.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: widget.weekdayWidth,
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 9),
                child: Text(
                  weekday,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: today ? FontWeight.w600 : FontWeight.w400,
                    color: past && !today ? colors.warmGrey : colors.inkSoft,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 14.0 * widget.slotCount,
            child: Stack(
              children: [
                for (final span in widget.spans)
                  if (span.slot >= 0)
                    Positioned(
                      left: span.slot * 16,
                      width: 14,
                      top: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => widget.onOpenEvent(span.event),
                        child: ColoredBox(color: _slotColor(colors, span.slot)),
                      ),
                    ),
                if (widget.birthdays.isNotEmpty && widget.chips.isNotEmpty)
                  Center(
                    child: GestureDetector(
                      onTap: () =>
                          widget.onOpenBirthday(widget.birthdays.first),
                      child: Icon(
                        Icons.star,
                        size: 13,
                        color: colors.goldBright,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Opacity(
              opacity: past && !today ? 0.45 : 1,
              child: Padding(
                padding: const EdgeInsets.only(left: 9, right: 8),
                child: onlyBirthday
                    ? _BirthdayLine(
                        birthday: widget.birthdays.first,
                        color: colors.gold,
                        onTap: () =>
                            widget.onOpenBirthday(widget.birthdays.first),
                      )
                    : widget.chips.isEmpty
                    ? Center(child: Container(height: 1, color: colors.dust))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (final entry in shown)
                            SizedBox(
                              height: layout.chipHeight,
                              child: _Chip(
                                entry: entry,
                                day: widget.day,
                                scale: widget.scale,
                                onTap: () => widget.onOpenEvent(entry.event),
                              ),
                            ),
                          if (widget.chips.length > 3)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _expanded = !_expanded),
                              child: Text(
                                _expanded
                                    ? widget.lessLabel
                                    : widget.moreLabel(widget.chips.length - 3),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colors.warmGrey,
                                ),
                              ),
                            ),
                          if (widget.dstLabel != null)
                            Text(
                              widget.dstLabel!,
                              style: TextStyle(
                                fontSize: 9,
                                color: colors.warmGrey,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.entry,
    required this.day,
    required this.scale,
    required this.onTap,
  });

  final FeedEntry entry;
  final DateTime day;
  final FeedScale scale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final event = entry.event;
    if (event.isAllDay) {
      return GestureDetector(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: colors.dust),
            color: colors.banner,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: colors.ink),
              ),
            ),
          ),
        ),
      );
    }
    final start = event.timed!.startsAt.toLocal();
    final end = event.timed!.endsAt.toLocal();
    final frame = FeedFrame.place(
      scale: scale,
      startMinute: _clippedStart(start, day),
      endMinute: _clippedEnd(end, day),
    );
    if (frame.kind == FeedFrameKind.tick) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            SizedBox(width: frame.left.clamp(0, 1) * 8),
            Container(width: 2, height: 17, color: colors.warmGrey),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                event.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: colors.ink),
              ),
            ),
          ],
        ),
      );
    }
    final left = frame.left.clamp(0.0, 1.0);
    final width = frame.kind == FeedFrameKind.bar
        ? frame.width.clamp(0.02, 1 - left)
        : frame.width;
    return GestureDetector(
      onTap: onTap,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: width.clamp(0.04, 1),
          alignment: Alignment.centerLeft,
          child: Container(
            margin: EdgeInsets.only(left: left * 4),
            padding: const EdgeInsets.symmetric(horizontal: 7),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: colors.banner,
              border: entry.frequency == null
                  ? null
                  : Border(left: BorderSide(color: colors.warmGrey, width: 3)),
            ),
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colors.ink),
            ),
          ),
        ),
      ),
    );
  }
}

class _BirthdayLine extends StatelessWidget {
  const _BirthdayLine({
    required this.birthday,
    required this.color,
    required this.onTap,
  });

  final Birthday birthday;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.star, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              birthday.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHeaderDelegate extends SliverPersistentHeaderDelegate {
  _MonthHeaderDelegate({
    required this.month,
    required this.locale,
    required this.scale,
    required this.spineX,
    required this.topGap,
  });

  final DateTime month;
  final Locale locale;
  final FeedScale scale;
  final double spineX;
  final double topGap;

  @override
  double get minExtent => 46 + topGap;

  @override
  double get maxExtent => 46 + topGap;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = Theme.of(context).vrijdagColors;
    final title = '${SpokenDate.monthName(month, locale)} ${month.year}';
    final hours = <int>[];
    for (var m = scale.startMinute; m <= scale.endMinute; m += 60) {
      final hour = m ~/ 60;
      if (scale.spanMinutes >= 4 * 60 && hour.isOdd) {
        continue;
      }
      hours.add(hour);
    }
    return Material(
      color: colors.paper,
      child: Padding(
        padding: EdgeInsets.only(top: topGap),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: colors.ink,
              ),
            ),
            SizedBox(
              height: 16,
              child: Padding(
                padding: EdgeInsets.only(left: spineX + 9),
                child: Row(
                  children: [
                    for (final hour in hours)
                      Expanded(
                        child: Text(
                          '$hour',
                          style: TextStyle(fontSize: 9, color: colors.warmGrey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _MonthHeaderDelegate oldDelegate) {
    return oldDelegate.month != month ||
        oldDelegate.scale.startMinute != scale.startMinute ||
        oldDelegate.scale.endMinute != scale.endMinute ||
        oldDelegate.spineX != spineX;
  }
}

Color _slotColor(VrijdagColorTokens colors, int slot) {
  return switch (slot) {
    0 => colors.ink,
    1 => colors.inkSoft,
    _ => colors.warmGrey,
  };
}

double _weekdayColumnWidth(BuildContext context, Locale locale) {
  final style = Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10);
  var max = 0.0;
  final monday = DateTime(2026, 9, 7);
  for (var i = 0; i < 7; i++) {
    final label = DateFormat.E(
      locale.toLanguageTag(),
    ).format(monday.add(Duration(days: i)));
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    if (painter.width > max) {
      max = painter.width;
    }
  }
  return max + 9;
}

List<DateTime> _months(DateTime from, DateTime to) {
  final out = <DateTime>[];
  var cursor = DateTime(from.year, from.month, 1);
  final end = DateTime(to.year, to.month, 1);
  while (cursor.isBefore(end)) {
    out.add(cursor);
    cursor = DateTime(cursor.year, cursor.month + 1, 1);
  }
  return out;
}

List<FeedSpan> _spans(List<FeedEntry> entries) {
  final out = <FeedSpan>[];
  for (final entry in entries) {
    final event = entry.event;
    if (!_multiDay(event)) {
      continue;
    }
    final start = CalendarRange.dateOnly(event.allDay!.startDate);
    final end = CalendarRange.dateOnly(event.allDay!.endDate);
    out.add(
      FeedSpan(
        id: event.id,
        startDay: start.millisecondsSinceEpoch,
        endDay: end.millisecondsSinceEpoch,
      ),
    );
  }
  return out;
}

List<({int slot, PersonalEvent event})> _spansOn(
  DateTime day,
  List<FeedEntry> entries,
  Map<String, int> slots,
) {
  final out = <({int slot, PersonalEvent event})>[];
  for (final entry in entries) {
    final event = entry.event;
    if (!_multiDay(event) || !CalendarPresence.eventOverlapsDay(event, day)) {
      continue;
    }
    out.add((slot: slots[event.id] ?? -1, event: event));
  }
  return out;
}

bool _multiDay(PersonalEvent event) {
  if (!event.isAllDay) {
    return false;
  }
  final start = CalendarRange.dateOnly(event.allDay!.startDate);
  final end = CalendarRange.dateOnly(event.allDay!.endDate);
  return end.isAfter(start);
}

int _minute(DateTime local) => local.hour * 60 + local.minute;

int _clippedStart(DateTime start, DateTime day) {
  if (_sameDay(start, day)) {
    return _minute(start);
  }
  return 0;
}

int _clippedEnd(DateTime end, DateTime day) {
  if (_sameDay(end, day)) {
    final minute = _minute(end);
    return minute == 0 ? 24 * 60 : minute;
  }
  return 24 * 60;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String? _dstLabel(DateTime day, String plus, String minus) {
  final start = DateTime(day.year, day.month, day.day);
  final hours = start.add(const Duration(days: 1)).difference(start).inHours;
  if (hours > 24) {
    return plus;
  }
  if (hours < 24) {
    return minus;
  }
  return null;
}
