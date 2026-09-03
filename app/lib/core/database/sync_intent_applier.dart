import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vrijdag/core/database/write_queue.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';

/// Applies queued sync intents against Supabase (F-009 replay).
class SyncIntentApplier {
  SyncIntentApplier({SupabaseClient? client})
    : _client = client ?? supabaseClient;

  final SupabaseClient? _client;

  Future<void> apply(SyncIntent intent) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase is not initialized');
    }

    final payload = jsonDecode(intent.payloadJson) as Map<String, dynamic>;
    final table = client.schema('app').from('personal_events');

    switch (intent.type) {
      case 'personal_event.create':
        await table.upsert(payload);
      case 'personal_event.update':
        final id = payload['id'] as String;
        final body = Map<String, dynamic>.from(payload)..remove('id');
        await table.update(body).eq('id', id);
      case 'personal_event.soft_delete':
        await table
            .update({'deleted_at': payload['deleted_at']})
            .eq('id', payload['id'] as String);
      case 'personal_event.undo_soft_delete':
        await table
            .update({'deleted_at': null})
            .eq('id', payload['id'] as String);
      default:
        throw UnsupportedError('Unknown sync intent: ${intent.type}');
    }
  }
}
