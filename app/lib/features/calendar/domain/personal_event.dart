import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

enum EventSource { vrijdag, google, imported }

enum SourceOfTruth { vrijdag, google }

/// Personal calendar event owned by one user.
class PersonalEvent {
  const PersonalEvent({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    this.location,
    this.timed,
    this.allDay,
    this.recurrenceRule,
    this.recurrenceUntil,
    this.recurrenceExdates = const [],
    this.seriesMaster,
    required this.source,
    required this.sourceOfTruth,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String? notes;
  final String? location;
  final TimedEventSpan? timed;
  final AllDayEventSpan? allDay;
  final RecurrenceRule? recurrenceRule;
  final DateTime? recurrenceUntil;
  final List<DateTime> recurrenceExdates;

  /// The stored series row, when this object is one expanded occurrence.
  final PersonalEvent? seriesMaster;
  final EventSource source;
  final SourceOfTruth sourceOfTruth;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAllDay => allDay != null;
  bool get isDeleted => deletedAt != null;
  bool get hasLocation => location != null && location!.trim().isNotEmpty;
  bool get isRecurring => recurrenceRule != null;

  PersonalEvent copyWith({
    String? title,
    String? notes,
    String? location,
    TimedEventSpan? timed,
    AllDayEventSpan? allDay,
    RecurrenceRule? recurrenceRule,
    DateTime? recurrenceUntil,
    List<DateTime>? recurrenceExdates,
    PersonalEvent? seriesMaster,
    bool clearRecurrence = false,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    DateTime? updatedAt,
  }) {
    return PersonalEvent(
      id: id,
      userId: userId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      location: location ?? this.location,
      timed: timed ?? this.timed,
      allDay: allDay ?? this.allDay,
      recurrenceRule: clearRecurrence
          ? null
          : (recurrenceRule ?? this.recurrenceRule),
      recurrenceUntil: clearRecurrence
          ? null
          : (recurrenceUntil ?? this.recurrenceUntil),
      recurrenceExdates: recurrenceExdates ?? this.recurrenceExdates,
      seriesMaster: seriesMaster ?? this.seriesMaster,
      source: source,
      sourceOfTruth: sourceOfTruth,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  void validate() {
    if (title.trim().isEmpty) {
      throw ArgumentError('title must not be empty');
    }
    if (timed == null && allDay == null) {
      throw ArgumentError('event must be timed or all-day');
    }
    if (timed != null && allDay != null) {
      throw ArgumentError('event cannot be both timed and all-day');
    }
    timed?.validate();
    allDay?.validate();
    recurrenceRule?.validate();
  }

  /// Whether this row can produce an occurrence inside [from, to).
  ///
  /// A repeating series overlaps the window when it has started and has not
  /// ended, even if the stored start sits before [from].
  bool overlaps(DateTime from, DateTime to) {
    if (!rangeStart.isBefore(to)) {
      return false;
    }
    if (isRecurring) {
      final until = recurrenceUntil ?? recurrenceRule?.until;
      if (until == null) {
        return true;
      }
      final inclusiveEnd = DateTime.utc(
        until.year,
        until.month,
        until.day,
      ).add(const Duration(days: 1));
      return inclusiveEnd.isAfter(from);
    }
    return rangeEnd.isAfter(from);
  }

  DateTime get rangeStart {
    if (timed != null) {
      return timed!.startsAt;
    }
    final span = allDay!;
    return DateTime.utc(
      span.startDate.year,
      span.startDate.month,
      span.startDate.day,
    );
  }

  DateTime get rangeEnd {
    if (timed != null) {
      return timed!.endsAt;
    }
    final span = allDay!;
    return DateTime.utc(
      span.endDate.year,
      span.endDate.month,
      span.endDate.day,
    ).add(const Duration(days: 1));
  }
}

/// Draft used when creating a new timed event (defaults to 60 minutes).
class NewTimedEventDraft {
  NewTimedEventDraft({
    required this.title,
    required this.startsAt,
    required this.timezone,
    Duration? duration,
    this.notes,
    this.location,
    this.recurrenceRule,
    this.recurrenceUntil,
  }) : endsAt = startsAt.add(duration ?? defaultTimedEventDuration);

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String timezone;
  final String? notes;
  final String? location;
  final RecurrenceRule? recurrenceRule;
  final DateTime? recurrenceUntil;
}
