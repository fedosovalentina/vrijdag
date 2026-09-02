import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vrijdag/core/config/app_config.dart';

/// Root configuration, set once at startup via [ProviderScope.overrides].
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider must be overridden before runApp',
  ),
);
