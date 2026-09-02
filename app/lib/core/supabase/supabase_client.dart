import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vrijdag/core/config/app_config.dart';

/// Whether Supabase was initialized successfully at startup.
final supabaseReadyProvider = Provider<bool>(
  (ref) => throw UnimplementedError(
    'supabaseReadyProvider must be overridden before runApp',
  ),
);

Future<void> initializeSupabase(AppConfig config) async {
  if (config.supabaseUrl.isEmpty || config.supabasePublishableKey.isEmpty) {
    return;
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    publishableKey: config.supabasePublishableKey,
  );
}

SupabaseClient? get supabaseClient {
  if (!Supabase.instance.isInitialized) {
    return null;
  }
  return Supabase.instance.client;
}
