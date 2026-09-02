import 'package:flutter/material.dart';

/// Resolves the device locale against [supportedLocales], falling back to English.
Locale? resolveAppLocale(Locale? locale, Iterable<Locale> supportedLocales) {
  if (locale == null) {
    return const Locale('en');
  }

  for (final supported in supportedLocales) {
    if (supported.languageCode == locale.languageCode) {
      return supported;
    }
  }

  return const Locale('en');
}
