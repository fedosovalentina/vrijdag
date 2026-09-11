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
