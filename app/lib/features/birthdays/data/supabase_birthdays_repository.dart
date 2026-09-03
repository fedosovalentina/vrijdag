import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/birthdays/domain/birthday.dart';
import 'package:vrijdag/features/birthdays/domain/birthdays_repository.dart';

class SupabaseBirthdaysRepository implements BirthdaysRepository {
  SupabaseBirthdaysRepository({SupabaseClient? client, Uuid? uuid})
    : _client = client ?? supabaseClient,
      _uuid = uuid ?? const Uuid();

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
  Future<List<Birthday>> listAll() async {
    final rows = await _db
        .schema('app')
        .from('birthdays')
        .select()
        .eq('user_id', _userId)
        .isFilter('deleted_at', null)
        .order('month')
        .order('day');
    return [
      for (final row in rows as List<dynamic>)
        _fromRow(Map<String, dynamic>.from(row as Map)),
    ];
  }

  @override
  Future<Birthday> create({
    required String name,
    required int month,
    required int day,
    int? year,
    String? notes,
  }) async {
    final draft = Birthday(
      id: _uuid.v4(),
      userId: _userId,
      name: name.trim(),
      month: month,
      day: day,
      year: year,
      notes: notes,
      createdAt: DateTime.now().toUtc(),
      updatedAt: DateTime.now().toUtc(),
    );
    draft.validate();

    final inserted = await _db
        .schema('app')
        .from('birthdays')
        .insert({
          'id': draft.id,
          'user_id': draft.userId,
          'name': draft.name,
          'month': draft.month,
          'day': draft.day,
          'year': draft.year,
          'notes': draft.notes,
        })
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(inserted));
  }

  @override
  Future<Birthday> update(Birthday birthday) async {
    birthday.validate();
    final updated = await _db
        .schema('app')
        .from('birthdays')
        .update({
          'name': birthday.name.trim(),
          'month': birthday.month,
          'day': birthday.day,
          'year': birthday.year,
          'notes': birthday.notes,
        })
        .eq('id', birthday.id)
        .select()
        .single();
    return _fromRow(Map<String, dynamic>.from(updated));
  }

  @override
  Future<void> softDelete(String id) async {
    await _db
        .schema('app')
        .from('birthdays')
        .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
        .eq('id', id);
  }

  Birthday _fromRow(Map<String, dynamic> row) {
    return Birthday(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      name: row['name'] as String,
      month: row['month'] as int,
      day: row['day'] as int,
      year: row['year'] as int?,
      notes: row['notes'] as String?,
      deletedAt: row['deleted_at'] == null
          ? null
          : DateTime.parse(row['deleted_at'] as String).toUtc(),
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
    );
  }
}
