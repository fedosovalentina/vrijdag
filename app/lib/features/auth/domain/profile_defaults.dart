import 'dart:ui';

import 'package:flutter_timezone/flutter_timezone.dart';

/// Maps device locale to supported app language (`nl` or `en`).
String resolveProfileLanguage(Locale locale) {
  return locale.languageCode == 'nl' ? 'nl' : 'en';
}

/// IANA timezone id when the platform provides one; otherwise a safe fallback.
Future<String> resolveDeviceTimezoneId() async {
  try {
    final id = (await FlutterTimezone.getLocalTimezone()).trim();
    if (id.isNotEmpty) {
      return id;
    }
  } on Object {
    // Fall through.
  }
  return resolveDeviceTimezoneFallback();
}

/// Synchronous fallback when async IANA lookup is unavailable.
String resolveDeviceTimezoneFallback() {
  final hours = DateTime.now().timeZoneOffset.inHours;
  if (hours == 1 || hours == 2) {
    return 'Europe/Amsterdam';
  }
  return 'UTC';
}

/// @Deprecated Prefer [resolveDeviceTimezoneId]. Kept for call-site migration.
String resolveDeviceTimezone() => resolveDeviceTimezoneFallback();
