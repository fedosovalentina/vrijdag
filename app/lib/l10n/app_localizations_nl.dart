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

  @override
  String get authSignInTitle => 'Inloggen';

  @override
  String get authEmailLabel => 'E-mailadres';

  @override
  String get authSendMagicLink => 'Stuur inloglink';

  @override
  String get authCheckEmail => 'Open de link in je e-mail om verder te gaan.';

  @override
  String get authInvalidEmail => 'Voer een geldig e-mailadres in.';

  @override
  String get authSendFailed =>
      'De inloglink kon niet worden gestuurd. Probeer het later opnieuw.';

  @override
  String get authSignOut => 'Uitloggen';

  @override
  String authSignedInAs(String email) {
    return 'Ingelogd als $email';
  }

  @override
  String get authSupabaseRequired => 'Supabase is nodig om in te loggen.';

  @override
  String get authSignInWithApple => 'Log in met Apple';

  @override
  String get authAppleFailed =>
      'Inloggen met Apple is mislukt. Controleer of Apple Sign In is geconfigureerd.';

  @override
  String get authOrEmail => 'Of met e-mail';

  @override
  String get authDeleteAccount => 'Account verwijderen';

  @override
  String get authDeleteConfirmTitle => 'Account verwijderen?';

  @override
  String get authDeleteConfirmBody =>
      'Dit verwijdert je account en alle persoonlijke gegevens. World-data blijft onaangetast. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get authDeleteConfirmContinue => 'Doorgaan';

  @override
  String get authDeleteFinalTitle => 'Definitief verwijderen';

  @override
  String get authDeleteFinalBody =>
      'Bevestig dat je dit account permanent wilt verwijderen.';

  @override
  String get authDeleteFinalAction => 'Account definitief verwijderen';

  @override
  String get authDeleteFailed =>
      'Het account kon niet worden verwijderd. Probeer het later opnieuw.';

  @override
  String get authSignOutPendingTitle => 'Niet-gesynchroniseerde wijzigingen';

  @override
  String get authSignOutPendingBody =>
      'Er staan wijzigingen klaar die nog niet met de server zijn gesynchroniseerd. Als je nu uitlogt, blijven ze op dit apparaat tot de volgende keer.';

  @override
  String get authSignOutPendingContinue => 'Toch uitloggen';
}
