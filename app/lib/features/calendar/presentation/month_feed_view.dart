import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vrijdag/core/analytics/analytics_event.dart';
import 'package:vrijdag/core/bootstrap/observability_bootstrap.dart';
import 'package:vrijdag/core/localization/l10n.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/presentation/birthday_providers.dart';
import 'package:vrijdag/features/calendar/domain/calendar_presence.dart';
import 'package:vrijdag/features/calendar/domain/calendar_range.dart';
import 'package:vrijdag/features/calendar/domain/event_category.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_empty.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_entry.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_frame.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_jump.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_month_span.dart';
import 'package:vrijdag/features/calendar/domain/feed/feed_name.dart';
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
    required this.onOpenYear,
    required this.onOpenSearch,
    required this.onOpenDay,
    required this.onOpenEvent,
    required this.onOpenBirthday,
  });

  final VoidCallback onOpenYear;
  final VoidCallback onOpenSearch;
  final ValueChanged<DateTime> onOpenDay;
  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<Birthday> onOpenBirthday;

  @override
  ConsumerState<MonthFeedView> createState() => _MonthFeedViewState();
}

class _MonthFeedViewState extends ConsumerState<MonthFeedView>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  Timer? _clock;
  DateTime _now = DateTime.now();
  var _placedToday = false;
  var _openFolds = <DateTime>{};
  var _todayVisible = true;
  DateTime? _highlight;
  var _offsets = const <FeedDayPlace>[];
  late final AnimationController _scaleMotion;
  FeedScale? _scaleFrom;
  FeedScale? _scaleTo;
  FeedScale? _visualScale;

  @override
  void initState() {
    super.initState();
    _scaleMotion =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 200),
        )..addListener(() {
          final from = _scaleFrom;
          final to = _scaleTo;
          if (from == null || to == null || !mounted) {
            return;
          }
          setState(
            () => _visualScale = _lerpScale(from, to, _scaleMotion.value),
          );
        });
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _scroll.addListener(_onScroll);
  }

  void _onMetrics(List<FeedDayPlace> places) {
    _offsets = places;
    _updateTodayVisible();
    final jump = ref.read(monthFeedJumpProvider);
    if (jump != null) {
      _reveal(jump);
      ref.read(monthFeedJumpProvider.notifier).state = null;
      return;
    }
    if (_placedToday) {
      return;
    }
    final today = _placeFor(DateTime.now());
    if (today == null || !_scroll.hasClients) {
      return;
    }
    _scroll.jumpTo(
      feedUpperThirdOffset(
        rowOffset: today.offset,
        viewport: _scroll.position.viewportDimension,
        maxScroll: _scroll.position.maxScrollExtent,
      ),
    );
    _placedToday = true;
    _updateTodayVisible();
  }

  void _reveal(DateTime day) {
    final place = _placeFor(day);
    if (place == null || !_scroll.hasClients) {
      final window = ref.read(monthFeedWindowProvider);
      final date = CalendarRange.dateOnly(day);
      if (!date.isBefore(window.from) && date.isBefore(window.to)) {
        return;
      }
      ref.read(monthFeedWindowProvider.notifier).growTo(day);
      ref.read(monthFeedJumpProvider.notifier).state = date;
      return;
    }
    if (feedDayIsVisible(
      rowOffset: place.offset,
      rowHeight: place.height,
      pixels: _scroll.position.pixels,
      viewport: _scroll.position.viewportDimension,
    )) {
      setState(() => _highlight = CalendarRange.dateOnly(day));
      return;
    }
    _scroll.animateTo(
      feedUpperThirdOffset(
        rowOffset: place.offset,
        viewport: _scroll.position.viewportDimension,
        maxScroll: _scroll.position.maxScrollExtent,
      ),
      duration: VrijdagMotion.resolve(
        context,
        const Duration(milliseconds: 200),
      ),
      curve: Curves.easeOut,
    );
  }

  FeedDayPlace? _placeFor(DateTime day) {
    final date = CalendarRange.dateOnly(day);
    for (final place in _offsets) {
      if (place.day == date) {
        return place;
      }
    }
    return null;
  }

  void _updateTodayVisible() {
    if (!_scroll.hasClients) {
      return;
    }
    final today = _placeFor(_now);
    final visible =
        today != null &&
        feedDayIsVisible(
          rowOffset: today.offset,
          rowHeight: today.height,
          pixels: _scroll.position.pixels,
          viewport: _scroll.position.viewportDimension,
        );
    if (visible != _todayVisible && mounted) {
      setState(() => _todayVisible = visible);
    }
  }

  void _home() {
    final today = DateTime.now();
    final place = _placeFor(today);
    final visible =
        place != null &&
        _scroll.hasClients &&
        feedDayIsVisible(
          rowOffset: place.offset,
          rowHeight: place.height,
          pixels: _scroll.position.pixels,
          viewport: _scroll.position.viewportDimension,
        );
    if (visible) {
      setState(() => _highlight = CalendarRange.dateOnly(today));
    } else {
      _reveal(today);
    }
    final bucket = '${today.year}-${today.month.toString().padLeft(2, '0')}';
    ref
        .read(analyticsProvider)
        .track(FeedJump(target: 'today', bucket: bucket));
  }

  @override
  void dispose() {
    _clock?.cancel();
    _scaleMotion.dispose();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _animateScale(FeedScale next) {
    if (_scaleTo != null &&
        _scaleTo!.startMinute == next.startMinute &&
        _scaleTo!.endMinute == next.endMinute) {
      return;
    }
    final from = _visualScale ?? next;
    _scaleFrom = from;
    _scaleTo = next;
    if (from.startMinute == next.startMinute &&
        from.endMinute == next.endMinute) {
      _visualScale = next;
      _scaleMotion.value = 1;
      return;
    }
    _scaleMotion.duration = VrijdagMotion.resolve(
      context,
      const Duration(milliseconds: 200),
    );
    if (_scaleMotion.duration == Duration.zero) {
      setState(() => _visualScale = next);
      _scaleMotion.value = 1;
      return;
    }
    _scaleMotion.forward(from: 0);
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
    _updateTodayVisible();
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
    final jump = ref.watch(monthFeedJumpProvider);
    if (jump != null) {
      final date = CalendarRange.dateOnly(jump);
      if (date.isBefore(window.from) || !date.isBefore(window.to)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(monthFeedWindowProvider.notifier).growTo(date);
          }
        });
      }
    }

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
          _animateScale(computed);
          ref
              .read(monthFeedWindowProvider.notifier)
              .adoptScale(computed, slots: used);
        });
        final categories =
            ref.watch(eventCategoriesProvider).valueOrNull ??
            const <EventCategory>[];
        final emptyMode =
            ref.watch(feedEmptyModeProvider).valueOrNull ??
            FeedEmptyMode.hidden;
        final scale = _visualScale ?? computed;
        final slotCount = window.slotCount < used ? used : window.slotCount;
        return Stack(
          children: [
            _FeedList(
              scroll: _scroll,
              window: window,
              entries: entries,
              birthdays: birthdays,
              scale: scale,
              slotCount: slotCount,
              slots: {for (final s in assigned) s.id: s.slot},
              categories: categories,
              emptyMode: emptyMode,
              openFolds: _openFolds,
              onOpenFold: (day) {
                setState(() => _openFolds = {..._openFolds, day});
              },
              now: _now,
              locale: locale,
              onOpenYear: widget.onOpenYear,
              onOpenDay: widget.onOpenDay,
              highlight: _highlight,
              onOpenEvent: widget.onOpenEvent,
              onOpenBirthday: widget.onOpenBirthday,
              onMetrics: (places) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _onMetrics(places);
                  }
                });
              },
            ),
            Positioned(
              top: 8,
              right: 12,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onOpenSearch,
                    child: Text(
                      l10n.searchOpen,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).vrijdagColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: widget.onOpenYear,
                    child: Text(
                      l10n.navYear,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).vrijdagColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!_todayVisible)
              Positioned(
                right: 12,
                bottom: 12,
                child: Semantics(
                  button: true,
                  label: l10n.chromeBackToToday,
                  child: GestureDetector(
                    onTap: _home,
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
                        '${_now.day}',
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

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.scroll,
    required this.window,
    required this.entries,
    required this.birthdays,
    required this.scale,
    required this.slotCount,
    required this.slots,
    required this.categories,
    required this.emptyMode,
    required this.openFolds,
    required this.onOpenFold,
    required this.now,
    required this.locale,
    required this.onOpenYear,
    required this.onOpenDay,
    required this.highlight,
    required this.onOpenEvent,
    required this.onOpenBirthday,
    required this.onMetrics,
  });

  final ScrollController scroll;
  final MonthFeedWindow window;
  final List<FeedEntry> entries;
  final List<Birthday> birthdays;
  final FeedScale scale;
  final int slotCount;
  final Map<String, int> slots;
  final List<EventCategory> categories;
  final FeedEmptyMode emptyMode;
  final Set<DateTime> openFolds;
  final ValueChanged<DateTime> onOpenFold;
  final DateTime now;
  final Locale locale;
  final VoidCallback onOpenYear;
  final ValueChanged<DateTime> onOpenDay;
  final DateTime? highlight;
  final ValueChanged<PersonalEvent> onOpenEvent;
  final ValueChanged<Birthday> onOpenBirthday;
  final ValueChanged<List<FeedDayPlace>> onMetrics;

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
    final places = <FeedDayPlace>[];

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
            onOpenYear: onOpenYear,
          ),
        ),
      );
      final lastDay = DateTime(month.year, month.month + 1, 0).day;
      final monthDays = [
        for (var d = 1; d <= lastDay; d++) DateTime(month.year, month.month, d),
      ];
      final pieces = layoutFeedDays(
        days: monthDays,
        isEmpty: (day) => _dayIsEmpty(day, entries, birthdays, slots),
        mode: emptyMode,
        openFolds: openFolds,
      );
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final piece = pieces[index];
            if (piece is FeedEmptyFold) {
              return _EmptyFold(
                label: l10n.feedEmptyGroup(piece.count),
                onTap: () => onOpenFold(piece.from),
              );
            }
            final day = (piece as FeedSingleDay).day;
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
              highlighted:
                  highlight != null &&
                  day.year == highlight!.year &&
                  day.month == highlight!.month &&
                  day.day == highlight!.day,
              chips: chips,
              birthdays: dayBirthdays,
              spans: _spansOn(day, entries, slots),
              scale: scale,
              slotCount: slotCount,
              categories: categories,
              weekdayWidth: weekdayWidth,
              now: now,
              locale: locale,
              l10nNow: l10n.feedNow,
              moreLabel: l10n.feedMore,
              lessLabel: l10n.feedShowLess,
              dstLabel: _dstLabel(day, l10n.feedDstPlus, l10n.feedDstMinus),
              onOpenDay: onOpenDay,
              onOpenEvent: onOpenEvent,
              onOpenBirthday: onOpenBirthday,
            );
          }, childCount: pieces.length),
        ),
      );
      for (final piece in pieces) {
        if (piece is FeedEmptyFold) {
          places.add(
            FeedDayPlace(day: piece.from, offset: running, height: 22),
          );
          running += 22;
          continue;
        }
        final day = (piece as FeedSingleDay).day;
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
        places.add(FeedDayPlace(day: day, offset: running, height: height));
        running += height;
      }
    }

    onMetrics(places);

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
    required this.highlighted,
    required this.chips,
    required this.birthdays,
    required this.spans,
    required this.scale,
    required this.slotCount,
    required this.categories,
    required this.weekdayWidth,
    required this.now,
    required this.locale,
    required this.l10nNow,
    required this.moreLabel,
    required this.lessLabel,
    required this.dstLabel,
    required this.onOpenDay,
    required this.onOpenEvent,
    required this.onOpenBirthday,
  });

  final DateTime day;
  final bool highlighted;
  final List<FeedEntry> chips;
  final List<Birthday> birthdays;
  final List<({int slot, PersonalEvent event})> spans;
  final FeedScale scale;
  final int slotCount;
  final List<EventCategory> categories;
  final double weekdayWidth;
  final DateTime now;
  final Locale locale;
  final String l10nNow;
  final String Function(int count) moreLabel;
  final String lessLabel;
  final String? dstLabel;
  final ValueChanged<DateTime> onOpenDay;
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

    return ColoredBox(
      color: widget.highlighted
          ? colors.banner
          : colors.paper.withValues(alpha: 0),
      child: SizedBox(
        height: onlyBirthday ? 34 : layout.rowHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 28,
              // Today bar sits in the 6px left pad so the day number still fits
              // the fixed 28px column (spec §1) — a Row overflowed by ~4.5px.
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  if (today)
                    Positioned(
                      left: 2,
                      child: Container(width: 3, height: 14, color: colors.ink),
                    ),
                  GestureDetector(
                    onTap: () => widget.onOpenDay(widget.day),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        '${widget.day.day}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: today ? FontWeight.w700 : FontWeight.w400,
                          color: past && !today ? colors.warmGrey : colors.ink,
                        ),
                      ),
                    ),
                  ),
                ],
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
                          child: ColoredBox(
                            color: _slotColor(colors, span.slot),
                            child: _SpanLabel(
                              event: span.event,
                              day: widget.day,
                              color: colors.paper,
                            ),
                          ),
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
                  child: Stack(
                    children: [
                      onlyBirthday
                          ? _BirthdayLine(
                              birthday: widget.birthdays.first,
                              color: colors.gold,
                              onTap: () =>
                                  widget.onOpenBirthday(widget.birthdays.first),
                            )
                          : widget.chips.isEmpty
                          ? const _DashedEmpty()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (final entry in shown)
                                  SizedBox(
                                    height: layout.chipHeight,
                                    child: _Chip(
                                      category: _categoryFor(
                                        entry.event.categoryId,
                                        widget.categories,
                                      ),
                                      entry: entry,
                                      day: widget.day,
                                      scale: widget.scale,
                                      locale: widget.locale,
                                      onTap: () =>
                                          widget.onOpenEvent(entry.event),
                                    ),
                                  ),
                                if (widget.chips.length > 3)
                                  GestureDetector(
                                    onTap: () =>
                                        setState(() => _expanded = !_expanded),
                                    child: Text(
                                      _expanded
                                          ? widget.lessLabel
                                          : widget.moreLabel(
                                              widget.chips.length - 3,
                                            ),
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
                      if (today)
                        Positioned.fill(
                          child: _NowMark(
                            scale: widget.scale,
                            now: widget.now,
                            label: widget.l10nNow,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

EventCategory? _categoryFor(String? id, List<EventCategory> categories) {
  if (id == null) {
    return null;
  }
  for (final category in categories) {
    if (category.id == id) {
      return category;
    }
  }
  return null;
}

Color _categoryColor(VrijdagColorTokens colors, int index) {
  return switch (index % 4) {
    0 => colors.ink,
    1 => colors.moss,
    2 => colors.rust,
    _ => colors.gold,
  };
}

class FeedDayPlace {
  const FeedDayPlace({
    required this.day,
    required this.offset,
    required this.height,
  });

  final DateTime day;
  final double offset;
  final double height;
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.category,
    required this.entry,
    required this.day,
    required this.scale,
    required this.locale,
    required this.onTap,
  });

  final EventCategory? category;
  final FeedEntry entry;
  final DateTime day;
  final FeedScale scale;
  final Locale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _FeedChipBody(
      category: category,
      entry: entry,
      day: day,
      scale: scale,
      locale: locale,
      onTap: onTap,
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
    required this.onOpenYear,
  });

  final DateTime month;
  final Locale locale;
  final FeedScale scale;
  final double spineX;
  final double topGap;
  final VoidCallback onOpenYear;

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
            Row(
              children: [
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity;
                    if (velocity != null && velocity.abs() > 200) {
                      onOpenYear();
                    }
                  },
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      color: colors.ink,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 16,
              child: Padding(
                padding: EdgeInsets.only(left: spineX + 9),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final labels = hours.length < 4
                        ? [
                            for (
                              var minute = scale.startMinute;
                              minute <= scale.endMinute;
                              minute += 60
                            )
                              minute ~/ 60,
                          ]
                        : hours;
                    final span = scale.spanMinutes;
                    return Stack(
                      children: [
                        for (final hour in labels)
                          Positioned(
                            left:
                                ((hour * 60 - scale.startMinute) / span) *
                                constraints.maxWidth,
                            bottom: 0,
                            child: Text(
                              '$hour',
                              style: TextStyle(
                                fontSize: 9,
                                color: colors.warmGrey,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
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

bool _dayIsEmpty(
  DateTime day,
  List<FeedEntry> entries,
  List<Birthday> birthdays,
  Map<String, int> slots,
) {
  final hasChip = entries.any(
    (entry) =>
        CalendarPresence.eventOverlapsDay(entry.event, day) &&
        (entry.event.timed != null || !_multiDay(entry.event)),
  );
  if (hasChip || CalendarPresence.birthdaysOnDay(birthdays, day).isNotEmpty) {
    return false;
  }
  return _spansOn(day, entries, slots).isEmpty;
}

class _EmptyFold extends StatelessWidget {
  const _EmptyFold({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 22,
      child: Align(
        alignment: Alignment.centerLeft,
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).vrijdagColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
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

FeedScale _lerpScale(FeedScale from, FeedScale to, double t) {
  final start = (from.startMinute + (to.startMinute - from.startMinute) * t)
      .round();
  final end = (from.endMinute + (to.endMinute - from.endMinute) * t).round();
  return FeedScale(
    startMinute: start,
    endMinute: end <= start ? start + 60 : end,
  );
}

class _FeedChipBody extends StatelessWidget {
  const _FeedChipBody({
    required this.category,
    required this.entry,
    required this.day,
    required this.scale,
    required this.locale,
    required this.onTap,
  });

  final EventCategory? category;
  final FeedEntry entry;
  final DateTime day;
  final FeedScale scale;
  final Locale locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).vrijdagColors;
    final event = entry.event;
    final mark = category == null
        ? null
        : Border(
            left: BorderSide(
              color: _categoryColor(colors, category!.colorIndex),
              width: 4,
            ),
          );
    if (event.isAllDay) {
      return GestureDetector(
        onTap: onTap,
        child: CustomPaint(
          painter: _HatchPainter(base: colors.banner, stripe: colors.dust),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 7),
            decoration: BoxDecoration(border: Border.all(color: colors.dust)),
            child: _WordTitle(
              text: event.title,
              style: TextStyle(fontSize: 11, color: colors.ink),
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
    final clock = DateFormat.Hm(locale.toLanguageTag());
    final startLabel = clock.format(start);
    final endLabel = clock.format(end);
    return LayoutBuilder(
      builder: (context, constraints) {
        final full = constraints.maxWidth;
        final left = frame.left.clamp(0.0, 1.0) * full;
        final bar = frame.width.clamp(0.0, 1.0) * full;
        if (frame.kind == FeedFrameKind.tick) {
          return GestureDetector(
            onTap: onTap,
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                Positioned(
                  left: left,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 2, color: colors.warmGrey),
                ),
                Positioned(
                  left: left + 8,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      Flexible(
                        child: _WordTitle(
                          text: event.title,
                          style: TextStyle(fontSize: 11, color: colors.ink),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        startLabel,
                        style: TextStyle(fontSize: 10, color: colors.warmGrey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
        final outside = frame.kind != FeedFrameKind.bar;
        final edgeNote = frame.kind == FeedFrameKind.afterScale
            ? '$startLabel →'
            : frame.kind == FeedFrameKind.beforeScale
            ? '← $endLabel'
            : null;
        return GestureDetector(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                left: left,
                width: bar < 1 ? 1 : bar,
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.banner,
                    border:
                        mark ??
                        (entry.frequency == null
                            ? null
                            : Border(
                                left: BorderSide(
                                  color: colors.warmGrey,
                                  width: 3,
                                ),
                              )),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: outside
                          ? Text(
                              '${event.title}  $edgeNote',
                              maxLines: 1,
                              overflow: TextOverflow.clip,
                              style: TextStyle(
                                fontSize: 9,
                                color: colors.warmGrey,
                              ),
                            )
                          : _WordTitle(
                              text: event.title,
                              style: TextStyle(fontSize: 11, color: colors.ink),
                            ),
                    ),
                  ),
                ),
              ),
              if (!outside && left > 36)
                Positioned(
                  left: 0,
                  width: left - 4,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      startLabel,
                      style: TextStyle(fontSize: 10, color: colors.warmGrey),
                    ),
                  ),
                ),
              if (!outside && left + bar < full - 36)
                Positioned(
                  left: left + bar + 4,
                  top: 0,
                  bottom: 0,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      endLabel,
                      style: TextStyle(fontSize: 10, color: colors.warmGrey),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WordTitle extends StatelessWidget {
  const _WordTitle({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = fitFeedName(
          text,
          constraints.maxWidth,
          (sample) => _textWidth(context, sample, style),
        );
        return Text(
          fitted.text,
          maxLines: 1,
          overflow: TextOverflow.clip,
          style: style,
        );
      },
    );
  }
}

double _textWidth(BuildContext context, String text, TextStyle style) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: Directionality.of(context),
    maxLines: 1,
  )..layout();
  return painter.width;
}

class _DashedEmpty extends StatelessWidget {
  const _DashedEmpty();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashPainter(color: Theme.of(context).vrijdagColors.dust),
      child: const SizedBox(height: 22, width: double.infinity),
    );
  }
}

class _DashPainter extends CustomPainter {
  const _DashPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final y = size.height / 2;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + 4, y), paint);
      x += 7;
    }
  }

  @override
  bool shouldRepaint(covariant _DashPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _HatchPainter extends CustomPainter {
  const _HatchPainter({required this.base, required this.stripe});

  final Color base;
  final Color stripe;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    final paint = Paint()
      ..color = stripe
      ..strokeWidth = 4;
    for (var i = -size.height; i < size.width; i += 8) {
      canvas.drawLine(
        Offset(i, size.height),
        Offset(i + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HatchPainter oldDelegate) =>
      oldDelegate.base != base || oldDelegate.stripe != stripe;
}

class _NowMark extends StatelessWidget {
  const _NowMark({required this.scale, required this.now, required this.label});

  final FeedScale scale;
  final DateTime now;
  final String label;

  @override
  Widget build(BuildContext context) {
    final minute = now.hour * 60 + now.minute;
    if (minute < scale.startMinute || minute >= scale.endMinute) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).vrijdagColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final left =
            ((minute - scale.startMinute) / scale.spanMinutes) *
            constraints.maxWidth;
        return Stack(
          children: [
            Positioned(
              left: left,
              top: 0,
              bottom: 0,
              child: ColoredBox(
                color: colors.gold,
                child: const SizedBox(width: 1),
              ),
            ),
            Positioned(
              left: left + 4,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerLeft,
                child: ColoredBox(
                  color: colors.paper,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Text(
                      label,
                      style: TextStyle(fontSize: 9, color: colors.gold),
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

class _SpanLabel extends StatelessWidget {
  const _SpanLabel({
    required this.event,
    required this.day,
    required this.color,
  });

  final PersonalEvent event;
  final DateTime day;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = _spanCaption(event, day);
    if (text == null) {
      return const SizedBox.shrink();
    }
    return ClipRect(
      child: Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

String? _spanCaption(PersonalEvent event, DateTime day) {
  final start = CalendarRange.dateOnly(event.allDay!.startDate);
  final end = CalendarRange.dateOnly(event.allDay!.endDate);
  final monthStart = DateTime(day.year, day.month, 1);
  final monthEnd = DateTime(day.year, day.month + 1, 0);
  final visibleStart = start.isBefore(monthStart) ? monthStart : start;
  if (!_sameDay(visibleStart, day)) {
    return null;
  }
  final caption = captionForMonth(
    spanStart: start.millisecondsSinceEpoch,
    spanEnd: end.millisecondsSinceEpoch,
    monthStart: monthStart.millisecondsSinceEpoch,
    monthEnd: monthEnd.millisecondsSinceEpoch,
    startDayLabel: '${start.day}',
    endDayLabel: '${end.day}',
  );
  return switch (caption.edge) {
    FeedSpanEdge.inside => '${event.title} ${caption.dayLabel}',
    FeedSpanEdge.continuesAfter => '${event.title} ${caption.dayLabel} →',
    FeedSpanEdge.continuedFrom => '→ ${event.title}',
    FeedSpanEdge.both => '${event.title} →',
  };
}
