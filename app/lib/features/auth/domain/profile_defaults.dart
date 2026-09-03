import 'dart:ui';

/// Prefer IANA timezone id when available; fall back to abbreviation.
String resolveDeviceTimezone() {
  return DateTime.now().timeZoneName;
}

/// Maps device locale to supported app language (`nl` or `en`).
String resolveProfileLanguage(Locale locale) {
  return locale.languageCode == 'nl' ? 'nl' : 'en';
}
