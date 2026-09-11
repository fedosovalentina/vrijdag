import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vrijdag/l10n/app_localizations.dart';

/// Spoken-form dates for DateHeader (F-007). Uses [intl], not ARB templates,
/// so Dutch and English inflect independently.
abstract final class SpokenDate {
  static String weekday(DateTime date, Locale locale) {
    final raw = DateFormat.EEEE(locale.toLanguageTag()).format(date);
    if (locale.languageCode == 'nl') {
      return raw.toLowerCase();
    }
    return raw;
  }

  static String dayMonth(DateTime date, Locale locale) {
    return DateFormat('d MMMM', locale.toLanguageTag()).format(date);
  }

  static String monthName(DateTime date, Locale locale) {
    final raw = DateFormat.MMMM(locale.toLanguageTag()).format(date);
    if (locale.languageCode == 'nl') {
      return raw.toLowerCase();
    }
    return raw;
  }

  static String monthShort(DateTime date, Locale locale) {
    return DateFormat.MMM(
      locale.toLanguageTag(),
    ).format(date).replaceAll('.', '');
  }

  static String weekRange(DateTime weekStart, Locale locale) {
    final end = weekStart.add(const Duration(days: 6));
    final startLabel = DateFormat(
      'd MMM',
      locale.toLanguageTag(),
    ).format(weekStart);
    final endLabel = DateFormat('d MMM', locale.toLanguageTag()).format(end);
    return '$startLabel – $endLabel';
  }

  static String seasonName(int month, AppLocalizations l10n) {
    if (month == 12 || month <= 2) {
      return l10n.seasonWinter;
    }
    if (month <= 5) {
      return l10n.seasonSpring;
    }
    if (month <= 8) {
      return l10n.seasonSummer;
    }
    return l10n.seasonAutumn;
  }
}
