import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vrijdag/core/database/write_queue.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/personal_events_repository.dart';

class SupabasePersonalEventsRepository implements PersonalEventsRepository {
  SupabasePersonalEventsRepository({
    required WriteQueue writeQueue,
    SupabaseClient? client,
    Uuid? uuid,
  }) : _writeQueue = writeQueue,
       _client = client ?? supabaseClient,
       _uuid = uuid ?? const Uuid();

  final WriteQueue _writeQueue;
  final SupabaseClient? _client;
  final Uuid _uuid;

  SupabaseClient get _db {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized');
    }
    return client;
  }

  String get _userId {
    final id = _db.auth.currentUser?.id;
    if (id == null) {
      throw StateError('Not signed in');
    }
    return id;
  }

  @override
  Future<List<PersonalEvent>> listOverlapping({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await _db
        .schema('app')
        .from('personal_events')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null);

    final events = <PersonalEvent>[];
    for (final row in rows as List<dynamic>) {
      final event = _fromRow(Map<String, dynamic>.from(row as Map));
      if (_overlaps(event, from, to)) {
        events.add(event);
      }
    }
    events.sort(_compare);
    return events;
  }

  @override
  Future<PersonalEvent> createTimed(NewTimedEventDraft draft) async {
    if (draft.endsAt.isBefore(draft.startsAt)) {
      throw ArgumentError('endsAt must be >= startsAt');
    }

    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'title': draft.title.trim(),
      'notes': draft.notes,
      'location': draft.location,
      'starts_at': draft.startsAt.toUtc().toIso8601String(),
      'ends_at': draft.endsAt.toUtc().toIso8601String(),
      'timezone': draft.timezone,
      'all_day': false,
      'source': 'vrijdag',
      'source_of_truth': 'vrijdag',
    };

    await _enqueue(
      'personal_event.create.$id',
      'personal_event.create',
      payload,
      now,
    );

    final inserted = await _db
        .schema('app')
        .from('personal_events')
        .insert(payload)
        .select()
        .single();

    return _fromRow(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<PersonalEvent> createAllDay({
    required String title,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? location,
  }) async {
    AllDayEventSpan(startDate: startDate, endDate: endDate).validate();

    final id = _uuid.v4();
    final now = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'id': id,
      'user_id': _userId,
      'title': title.trim(),
      'notes': notes,
      'location': location,
      'start_date': _dateOnly(startDate),
      'end_date': _dateOnly(endDate),
      'timezone': 'Europe/Amsterdam',
      'all_day': true,
      'source': 'vrijdag',
      'source_of_truth': 'vrijdag',
    };

    await _enqueue(
      'personal_event.create.$id',
      'personal_event.create',
      payload,
      now,
    );

    final inserted = await _db
        .schema('app')
        .from('personal_events')
        .insert(payload)
        .select()
        .single();

    return _fromRow(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<PersonalEvent> update(PersonalEvent event) async {
    event.validate();
    final payload = _toRow(event);
    await _enqueue(
      'personal_event.update.${event.id}',
      'personal_event.update',
      {'id': event.id, ...payload},
      DateTime.now().toUtc(),
    );

    final updated = await _db
        .schema('app')
        .from('personal_events')
        .update(payload)
        .eq('id', event.id)
        .select()
        .single();

    return _fromRow(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> softDelete(String eventId) async {
    final deletedAt = DateTime.now().toUtc().toIso8601String();
    await _enqueue(
      'personal_event.delete.$eventId',
      'personal_event.soft_delete',
      {'id': eventId, 'deleted_at': deletedAt},
      DateTime.now().toUtc(),
    );

    await _db
        .schema('app')
        .from('personal_events')
        .update({'deleted_at': deletedAt})
        .eq('id', eventId);
  }

  @override
  Future<void> undoSoftDelete(String eventId) async {
    await _enqueue(
      'personal_event.undelete.$eventId',
      'personal_event.undo_soft_delete',
      {'id': eventId},
      DateTime.now().toUtc(),
    );

    await _db
        .schema('app')
        .from('personal_events')
        .update({'deleted_at': null})
        .eq('id', eventId);
  }

  Future<void> _enqueue(
    String id,
    String type,
    Map<String, dynamic> payload,
    DateTime createdAt,
  ) {
    return _writeQueue.enqueue(
      SyncIntent(
        id: id,
        type: type,
        payloadJson: jsonEncode(payload),
        createdAt: createdAt,
      ),
    );
  }

  Map<String, dynamic> _toRow(PersonalEvent event) {
    return {
      'title': event.title.trim(),
      'notes': event.notes,
      'location': event.location,
      'starts_at': event.timed?.startsAt.toUtc().toIso8601String(),
      'ends_at': event.timed?.endsAt.toUtc().toIso8601String(),
      'start_date': event.allDay == null
          ? null
          : _dateOnly(event.allDay!.startDate),
      'end_date': event.allDay == null
          ? null
          : _dateOnly(event.allDay!.endDate),
      'timezone': event.timed?.timezone ?? 'Europe/Amsterdam',
      'all_day': event.isAllDay,
      'deleted_at': event.deletedAt?.toUtc().toIso8601String(),
    };
  }

  PersonalEvent _fromRow(Map<String, dynamic> row) {
    final allDay = row['all_day'] as bool? ?? false;
    return PersonalEvent(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      title: row['title'] as String,
      notes: row['notes'] as String?,
      location: row['location'] as String?,
      timed: allDay
          ? null
          : TimedEventSpan(
              startsAt: DateTime.parse(row['starts_at'] as String).toUtc(),
              endsAt: DateTime.parse(row['ends_at'] as String).toUtc(),
              timezone: row['timezone'] as String? ?? 'Europe/Amsterdam',
            ),
      allDay: allDay
          ? AllDayEventSpan(
              startDate: DateTime.parse(row['start_date'] as String),
              endDate: DateTime.parse(row['end_date'] as String),
            )
          : null,
      source: EventSource.vrijdag,
      sourceOfTruth: SourceOfTruth.vrijdag,
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String).toUtc(),
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
  }

  bool _overlaps(PersonalEvent event, DateTime from, DateTime to) {
    if (event.timed != null) {
      return event.timed!.startsAt.isBefore(to) &&
          event.timed!.endsAt.isAfter(from);
    }
    final span = event.allDay!;
    final start = DateTime.utc(
      span.startDate.year,
      span.startDate.month,
      span.startDate.day,
    );
    final endExclusive = DateTime.utc(
      span.endDate.year,
      span.endDate.month,
      span.endDate.day,
    ).add(const Duration(days: 1));
    return start.isBefore(to) && endExclusive.isAfter(from);
  }

  int _compare(PersonalEvent a, PersonalEvent b) {
    final aStart =
        a.timed?.startsAt ??
        DateTime.utc(
          a.allDay!.startDate.year,
          a.allDay!.startDate.month,
          a.allDay!.startDate.day,
        );
    final bStart =
        b.timed?.startsAt ??
        DateTime.utc(
          b.allDay!.startDate.year,
          b.allDay!.startDate.month,
          b.allDay!.startDate.day,
        );
    return aStart.compareTo(bStart);
  }

  String _dateOnly(DateTime value) {
    final d = DateTime(value.year, value.month, value.day);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
