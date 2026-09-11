import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/auth/domain/user_profile.dart';
import 'package:vrijdag/features/auth/domain/user_profile_repository.dart';

class SupabaseUserProfileRepository implements UserProfileRepository {
  SupabaseUserProfileRepository({SupabaseClient? client})
    : _client = client ?? supabaseClient;

  final SupabaseClient? _client;

  static const _columns =
      'id, language, timezone, home_city, school_holiday_region';

  @override
  Future<UserProfile> ensureProfile({
    required String userId,
    required String language,
    required String timezone,
  }) async {
    final client = _requireClient();

    final existing = await client
        .schema('app')
        .from('users')
        .select(_columns)
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      return _fromRow(existing);
    }

    final inserted = await client
        .schema('app')
        .from('users')
        .insert({'id': userId, 'language': language, 'timezone': timezone})
        .select(_columns)
        .single();

    return _fromRow(inserted);
  }

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    final client = _requireClient();

    final row = await client
        .schema('app')
        .from('users')
        .select(_columns)
        .eq('id', userId)
        .maybeSingle();

    if (row == null) {
      return null;
    }
    return _fromRow(row);
  }

  @override
  Future<UserProfile> updatePreferences({
    required String userId,
    required String language,
    String? homeCity,
    String? schoolHolidayRegion,
  }) async {
    final client = _requireClient();

    final trimmedCity = homeCity?.trim();
    final updated = await client
        .schema('app')
        .from('users')
        .update({
          'language': language,
          'home_city': (trimmedCity == null || trimmedCity.isEmpty)
              ? null
              : trimmedCity,
          'school_holiday_region': schoolHolidayRegion,
        })
        .eq('id', userId)
        .select(_columns)
        .single();

    return _fromRow(updated);
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized');
    }
    return client;
  }

  UserProfile _fromRow(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      language: row['language'] as String,
      timezone: row['timezone'] as String,
      homeCity: row['home_city'] as String?,
      schoolHolidayRegion: row['school_holiday_region'] as String?,
    );
  }
}
