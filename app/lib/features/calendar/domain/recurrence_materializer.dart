import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_expander.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

/// Expands recurring masters into occurrence views for a visible range.
abstract final class RecurrenceMaterializer {
  static List<PersonalEvent> materialize(
    List<PersonalEvent> events, {
    required DateTime from,
    required DateTime to,
  }) {
    const expander = RecurrenceExpander();
    final out = <PersonalEvent>[];

    for (final event in events) {
      final rule = event.recurrenceRule;
      if (rule == null) {
        out.add(event);
        continue;
      }

      final seriesStart =
          event.timed?.startsAt.toUtc() ??
          DateTime.utc(
            event.allDay!.startDate.year,
            event.allDay!.startDate.month,
            event.allDay!.startDate.day,
          );

      final effective = RecurrenceRule(
        frequency: rule.frequency,
        interval: rule.interval,
        count: rule.count,
        until: event.recurrenceUntil?.toUtc() ?? rule.until,
        byDay: rule.byDay,
      );

      final occurrences = expander.expand(
        rule: effective,
        seriesStart: seriesStart,
        from: from.toUtc(),
        to: to.toUtc(),
        exdates: event.recurrenceExdates,
      );

      final duration = event.timed == null
          ? Duration.zero
          : event.timed!.endsAt.difference(event.timed!.startsAt);
      final allDayLength = event.allDay == null
          ? 0
          : event.allDay!.endDate
                .difference(
                  DateTime(
                    event.allDay!.startDate.year,
                    event.allDay!.startDate.month,
                    event.allDay!.startDate.day,
                  ),
                )
                .inDays;

      for (final occ in occurrences) {
        if (event.timed != null) {
          out.add(
            event.copyWith(
              timed: TimedEventSpan(
                startsAt: occ.startsAt,
                endsAt: occ.startsAt.add(duration),
                timezone: event.timed!.timezone,
              ),
              clearRecurrence: true,
              seriesMaster: event,
            ),
          );
        } else {
          final start = DateTime(
            occ.startsAt.year,
            occ.startsAt.month,
            occ.startsAt.day,
          );
          out.add(
            event.copyWith(
              allDay: AllDayEventSpan(
                startDate: start,
                endDate: start.add(Duration(days: allDayLength)),
              ),
              clearRecurrence: true,
              seriesMaster: event,
            ),
          );
        }
      }
    }

    return out;
  }
}
