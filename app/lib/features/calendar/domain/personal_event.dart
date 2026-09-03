import 'package:vrijdag/features/calendar/domain/event_time.dart';

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
  final EventSource source;
  final SourceOfTruth sourceOfTruth;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAllDay => allDay != null;
  bool get isDeleted => deletedAt != null;
  bool get hasLocation => location != null && location!.trim().isNotEmpty;

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
  }) : endsAt = startsAt.add(duration ?? defaultTimedEventDuration);

  final String title;
  final DateTime startsAt;
  final DateTime endsAt;
  final String timezone;
  final String? notes;
  final String? location;
}
