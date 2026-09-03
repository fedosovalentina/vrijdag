// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get commonAppName => 'Vrijdag';

  @override
  String get commonToday => 'Vandaag';

  @override
  String get commonTomorrow => 'Morgen';

  @override
  String get commonYesterday => 'Gisteren';

  @override
  String get commonCancel => 'Annuleren';

  @override
  String get commonSave => 'Opslaan';

  @override
  String get commonDelete => 'Verwijderen';

  @override
  String get commonRetry => 'Opnieuw';

  @override
  String get bootstrapFoundationMessage =>
      'Technische basis voor F-001. Dag-scherm en data volgen in latere features.';

  @override
  String get bootstrapStatusReady => 'Omgevingsskelet gereed.';

  @override
  String bootstrapEnvironment(String environment) {
    return 'Omgeving: $environment';
  }

  @override
  String get bootstrapSupabaseConnected => 'Supabase-client gereed.';

  @override
  String get bootstrapSupabaseUnavailable => 'Supabase niet geconfigureerd.';

  @override
  String get bootstrapTestCrash => 'Testcrash';

  @override
  String get bootstrapSentryReady => 'Sentry gereed.';

  @override
  String get bootstrapSentryUnavailable => 'Sentry niet geconfigureerd.';
}
