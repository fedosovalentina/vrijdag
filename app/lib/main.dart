import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/app.dart';
import 'package:vrijdag/core/config/app_config.dart';
import 'package:vrijdag/core/config/config_providers.dart';
import 'package:vrijdag/core/supabase/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  var supabaseReady = false;

  if (config.supabaseUrl.isNotEmpty &&
      config.supabasePublishableKey.isNotEmpty) {
    try {
      await initializeSupabase(config);
      supabaseReady = true;
    } on Object {
      supabaseReady = false;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        supabaseReadyProvider.overrideWithValue(supabaseReady),
      ],
      child: const VrijdagApp(),
    ),
  );
}
