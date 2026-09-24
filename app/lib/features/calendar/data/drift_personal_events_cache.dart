import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:vrijdag/core/database/app_database.dart';
import 'package:vrijdag/features/calendar/domain/event_category.dart';
import 'package:vrijdag/features/calendar/domain/event_time.dart';
import 'package:vrijdag/features/calendar/domain/personal_event.dart';
import 'package:vrijdag/features/calendar/domain/recurrence_rule.dart';

/// Local SQLite mirror of personal events for offline reads (F-004 / DEC-019).
class DriftPersonalEventsCache {
  DriftPersonalEventsCache(this._db);

  static const categoriesRowId = 'categories';

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

  Future<DateTime?> latestCachedAt(String userId) async {
    final newest = _db.cachedPersonalEvents.cachedAt.max();
    final query = _db.selectOnly(_db.cachedPersonalEvents)
      ..addColumns([newest])
      ..where(
        _db.cachedPersonalEvents.userId.equals(userId) &
            _db.cachedPersonalEvents.id.equals(categoriesRowId).not(),
      );
    final row = await query.getSingleOrNull();
    return row?.read(newest);
  }

  Future<List<PersonalEvent>> listForUser(String userId) async {
    final rows = await (_db.select(
      _db.cachedPersonalEvents,
    )..where((t) => t.userId.equals(userId))).get();
    return [
      for (final row in rows)
        if (row.id != categoriesRowId)
          _fromJson(jsonDecode(row.payloadJson) as Map<String, dynamic>),
    ];
  }

  Future<List<EventCategory>> loadCategories(String userId) async {
    final row =
        await (_db.select(_db.cachedPersonalEvents)..where(
              (t) => t.id.equals(categoriesRowId) & t.userId.equals(userId),
            ))
            .getSingleOrNull();
    if (row == null) {
      return const [];
    }
    final raw = jsonDecode(row.payloadJson);
    if (raw is! List) {
      return const [];
    }
    return [
      for (final item in raw)
        if (item is Map)
          EventCategory(
            id: item['id'] as String,
            name: item['name'] as String,
            colorIndex: item['color'] as int? ?? 0,
            patternIndex: item['pattern'] as int? ?? 0,
          ),
    ];
  }

  Future<void> saveCategories(String userId, List<EventCategory> items) {
    final payload = [
      for (final item in items)
        {
          'id': item.id,
          'name': item.name,
          'color': item.colorIndex,
          'pattern': item.patternIndex,
        },
    ];
    return _db
        .into(_db.cachedPersonalEvents)
        .insert(
          CachedPersonalEventsCompanion.insert(
            id: categoriesRowId,
            userId: userId,
            payloadJson: jsonEncode(payload),
            cachedAt: DateTime.now().toUtc(),
          ),
          mode: InsertMode.insertOrReplace,
        );
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
      'recurrence_rule': encodeStoredRecurrence(
        event.recurrenceRule,
        event.recurrenceExdates,
      ),
      'recurrence_until': event.recurrenceUntil == null
          ? null
          : _dateOnly(event.recurrenceUntil!),
      'deleted_at': event.deletedAt?.toUtc().toIso8601String(),
      'created_at': event.createdAt.toUtc().toIso8601String(),
      'updated_at': event.updatedAt.toUtc().toIso8601String(),
      'category_id': event.categoryId,
      'reminder_minutes': event.reminderMinutes,
      'guests': event.guests,
    };
  }

  PersonalEvent _fromJson(Map<String, dynamic> row) {
    final allDay = row['all_day'] as bool? ?? false;
    final stored = decodeStoredRecurrence(row['recurrence_rule'] as String?);
    DateTime? until;
    final untilRaw = row['recurrence_until'];
    if (untilRaw is String && untilRaw.isNotEmpty) {
      until = DateTime.parse(untilRaw);
    }
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
      recurrenceRule: stored.rule,
      recurrenceUntil: until,
      recurrenceExdates: stored.exdates,
      categoryId: row['category_id'] as String?,
      reminderMinutes: [
        for (final item in (row['reminder_minutes'] as List? ?? const []))
          if (item is int) item else if (item is num) item.toInt(),
      ],
      guests: [
        for (final item in (row['guests'] as List? ?? const []))
          if (item is String && item.trim().isNotEmpty) item,
      ],
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
