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
import 'package:vrijdag/shared/widgets/quiet_state.dart';
import 'package:vrijdag/shared/widgets/sync_pending_banner.dart';

/// Year shell: vertical stack of years, each as twelve mini month grids.
///
/// Today is circled; presence is quiet. Product override of Task 02
/// “ticks only” Year map (dogfood 2026-09-25).
class YearView extends ConsumerStatefulWidget {
  const YearView({
    super.key,
    required this.isActive,
    required this.onSelectMonth,
    required this.onSelectDay,
  });

  /// Whether the Year shell is the visible PageView page.
  final bool isActive;
  final ValueChanged<DateTime> onSelectMonth;
  final ValueChanged<DateTime> onSelectDay;

  @override
  ConsumerState<YearView> createState() => _YearViewState();
}

class _YearViewState extends ConsumerState<YearView> {
  static const _estimatedYearHeight = 680.0;

  final _scroll = ScrollController();
  final _yearKeys = <int, GlobalKey>{};
  late int _fromYear;
  late int _toYear;
  late int _focusedYear;
  var _extendingPast = false;
  var _extendingFuture = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().year;
    // Open on the current year; neighbours grow as the user scrolls.
    _fromYear = now;
    _toYear = now;
    _focusedYear = now;
    _scroll.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(YearView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _rememberLeave();
        }
      });
    } else if (!oldWidget.isActive && widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _restoreOnEnter();
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  GlobalKey _keyFor(int year) => _yearKeys.putIfAbsent(year, GlobalKey.new);

  void _rememberLeave() {
    _sampleFocusedYear();
    ref.read(yearShellMemoryProvider.notifier).state = YearShellMemory(
      year: _focusedYear,
      leftAt: DateTime.now(),
    );
  }

  void _restoreOnEnter() {
    final memory = ref.read(yearShellMemoryProvider);
    if (memory != null && memory.isFresh) {
      _showYear(memory.year);
      return;
    }
    ref.read(yearShellMemoryProvider.notifier).state = null;
    _showYear(DateTime.now().year);
  }

  void _showYear(int year) {
    setState(() {
      if (year < _fromYear) {
        _fromYear = year;
      }
      if (year > _toYear) {
        _toYear = year;
      }
      _focusedYear = year;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _scrollToYear(year);
    });
  }

  void _scrollToYear(int year) {
    if (!_scroll.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _scrollToYear(year);
        }
      });
      return;
    }
    final index = year - _fromYear;
    final target = (index * _estimatedYearHeight).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.jumpTo(target);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ctx = _keyFor(year).currentContext;
      final renderObject = ctx?.findRenderObject();
      if (ctx == null || renderObject == null) {
        return;
      }
      final scrollable = Scrollable.maybeOf(ctx);
      scrollable?.position.ensureVisible(
        renderObject,
        alignment: 0.0,
        duration: Duration.zero,
      );
    });
  }

  void _sampleFocusedYear() {
    if (!mounted) {
      return;
    }
    int? found;
    for (var y = _fromYear; y <= _toYear; y++) {
      final ctx = _keyFor(y).currentContext;
      if (ctx == null) {
        continue;
      }
      final box = ctx.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        continue;
      }
      final top = box.localToGlobal(Offset.zero).dy;
      // Last year whose header has reached the upper band is the focused one.
      if (top <= 180) {
        found = y;
      }
    }
    if (found != null) {
      _focusedYear = found;
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients) {
      return;
    }
    _sampleFocusedYear();
    final max = _scroll.position.maxScrollExtent;
    final offset = _scroll.offset;
    // Near the bottom → load a later year.
    if (max > 0 && offset >= max - 50) {
      if (!_extendingFuture) {
        _extendingFuture = true;
        setState(() => _toYear += 1);
      }
    } else {
      _extendingFuture = false;
    }
  }

  void _prependPastYear() {
    if (_extendingPast) {
      return;
    }
    _extendingPast = true;
    final before = _scroll.hasClients ? _scroll.position.pixels : 0.0;
    setState(() => _fromYear -= 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.jumpTo(before + _estimatedYearHeight);
      _extendingPast = false;
    });
  }

  void _appendFutureYear() {
    if (_extendingFuture) {
      return;
    }
    _extendingFuture = true;
    setState(() => _toYear += 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _extendingFuture = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context);
    final today = CalendarRange.dateOnly(DateTime.now());
    final birthdaysAsync = ref.watch(birthdaysListProvider);
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

    ref.listen<int?>(yearJumpToProvider, (_, next) {
      if (next == null) {
        return;
      }
      final year = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _showYear(year);
        ref.read(yearJumpToProvider.notifier).state = null;
      });
    });

    final years = [for (var y = _fromYear; y <= _toYear; y++) y];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SyncPendingBanner(),
        const CalendarLegend(),
        Expanded(
          child: NotificationListener<OverscrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis != Axis.vertical) {
                return false;
              }
              // Pull past the top → previous year.
              if (notification.overscroll < 0 &&
                  notification.metrics.pixels <= 0) {
                _prependPastYear();
                return false;
              }
              // Push past the bottom → next year.
              if (notification.overscroll > 0 &&
                  notification.metrics.pixels >=
                      notification.metrics.maxScrollExtent) {
                _appendFutureYear();
                return false;
              }
              return false;
            },
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                VrijdagSpacing.sm,
                VrijdagSpacing.xs,
                VrijdagSpacing.sm,
                VrijdagSpacing.page,
              ),
              itemCount: years.length,
              itemBuilder: (context, index) {
                final year = years[index];
                return KeyedSubtree(
                  key: _keyFor(year),
                  child: _YearBlock(
                    year: year,
                    locale: locale,
                    weekdayLabels: weekdayLabels,
                    today: today,
                    birthdays: birthdays,
                    onSelectMonth: widget.onSelectMonth,
                    onSelectDay: widget.onSelectDay,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _YearBlock extends ConsumerWidget {
  const _YearBlock({
    required this.year,
    required this.locale,
    required this.weekdayLabels,
    required this.today,
    required this.birthdays,
    required this.onSelectMonth,
    required this.onSelectDay,
  });

  final int year;
  final Locale locale;
  final List<String> weekdayLabels;
  final DateTime today;
  final List<Birthday> birthdays;
  final ValueChanged<DateTime> onSelectMonth;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = Theme.of(context).vrijdagColors;
    final eventsAsync = ref.watch(yearEventsProvider(year));

    return eventsAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: VrijdagSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _YearTitle(year: year, color: colors.ink),
            const SizedBox(
              height: 48,
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: VrijdagSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _YearTitle(year: year, color: colors.ink),
            QuietState(message: l10n.calendarLoadFailed),
          ],
        ),
      ),
      data: (events) {
        return Padding(
          padding: const EdgeInsets.only(bottom: VrijdagSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _YearTitle(year: year, color: colors.ink),
              const SizedBox(height: VrijdagSpacing.sm),
              LayoutBuilder(
                builder: (context, constraints) {
                  final gap = VrijdagSpacing.sm;
                  final cellWidth = (constraints.maxWidth - gap * 2) / 3;
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
            ],
          ),
        );
      },
    );
  }
}

class _YearTitle extends StatelessWidget {
  const _YearTitle({required this.year, required this.color});

  final int year;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        VrijdagSpacing.xs,
        VrijdagSpacing.sm,
        VrijdagSpacing.xs,
        0,
      ),
      child: Text(
        '$year',
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontSize: 29,
          height: 1.1,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
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
