import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:vrijdag/core/database/app_database.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';

/// Local SQLite mirror of personal events for offline reads (F-004 / DEC-019).
class DriftPersonalEventsCache {
  DriftPersonalEventsCache(this._db);

  final AppDatabase _db;

  Future<void> upsertAll(Iterable<PersonalEvent> events) async {
    await _db.batch((batch) {
      for (final event in events) {
        batch.insert(
          _db.cachedPersonalEvents,
          CachedPersonalEventsCompanion.insert(
            id: event.id,
            userId: event.userId,
            payloadJson: jsonEncode(_toJson(event)),
            cachedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> upsert(PersonalEvent event) => upsertAll([event]);

  Future<void> remove(String eventId) {
    return (_db.delete(
      _db.cachedPersonalEvents,
    )..where((t) => t.id.equals(eventId))).go();
  }

  Future<List<PersonalEvent>> listForUser(String userId) async {
    final rows = await (_db.select(
      _db.cachedPersonalEvents,
    )..where((t) => t.userId.equals(userId))).get();
    return [
      for (final row in rows)
        _fromJson(jsonDecode(row.payloadJson) as Map<String, dynamic>),
    ];
  }

  Map<String, dynamic> _toJson(PersonalEvent event) {
    return {
      'id': event.id,
      'user_id': event.userId,
      'title': event.title,
      'notes': event.notes,
      'location': event.location,
      'all_day': event.isAllDay,
      'starts_at': event.timed?.startsAt.toUtc().toIso8601String(),
      'ends_at': event.timed?.endsAt.toUtc().toIso8601String(),
      'timezone': event.timed?.timezone,
      'start_date': event.allDay == null
          ? null
          : _dateOnly(event.allDay!.startDate),
      'end_date': event.allDay == null
          ? null
          : _dateOnly(event.allDay!.endDate),
      'source': event.source.name,
      'source_of_truth': event.sourceOfTruth.name,
      'deleted_at': event.deletedAt?.toUtc().toIso8601String(),
      'created_at': event.createdAt.toUtc().toIso8601String(),
      'updated_at': event.updatedAt.toUtc().toIso8601String(),
    };
  }

  PersonalEvent _fromJson(Map<String, dynamic> row) {
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
      source: switch (row['source'] as String?) {
        'google' => EventSource.google,
        'imported' => EventSource.imported,
        _ => EventSource.vrijdag,
      },
      sourceOfTruth: switch (row['source_of_truth'] as String?) {
        'google' => SourceOfTruth.google,
        _ => SourceOfTruth.vrijdag,
      },
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String).toUtc(),
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
  }

  String _dateOnly(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
