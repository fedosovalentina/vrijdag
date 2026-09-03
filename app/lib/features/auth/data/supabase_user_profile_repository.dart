import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';
import 'package:vrijdag/features/auth/domain/user_profile.dart';
import 'package:vrijdag/features/auth/domain/user_profile_repository.dart';

class SupabaseUserProfileRepository implements UserProfileRepository {
  SupabaseUserProfileRepository({SupabaseClient? client})
    : _client = client ?? supabaseClient;

  final SupabaseClient? _client;

  @override
  Future<UserProfile> ensureProfile({
    required String userId,
    required String language,
    required String timezone,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized');
    }

    final existing = await client
        .schema('app')
        .from('users')
        .select('id, language, timezone')
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      return UserProfile(
        id: existing['id'] as String,
        language: existing['language'] as String,
        timezone: existing['timezone'] as String,
      );
    }

    final inserted = await client
        .schema('app')
        .from('users')
        .insert({'id': userId, 'language': language, 'timezone': timezone})
        .select('id, language, timezone')
        .single();

    return UserProfile(
      id: inserted['id'] as String,
      language: inserted['language'] as String,
      timezone: inserted['timezone'] as String,
    );
  }
}
