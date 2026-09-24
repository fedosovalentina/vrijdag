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
  String get authTagline => 'Je eigen tijd, en wat eromheen gebeurt.';

  @override
  String get authUseDifferentEmail => 'Ander e-mailadres';

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
  String get authSendRateLimited =>
      'Te veel inlogmails. Wacht ongeveer een uur, of kijk in spam.';

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
      'Dit verwijdert je account en alle persoonlijke gegevens. Wereldgegevens blijven onaangetast. Dit is niet terug te draaien.';

  @override
  String get authDeleteConfirmContinue => 'Doorgaan';

  @override
  String get authDeleteFinalTitle => 'Definitief verwijderen';

  @override
  String get authDeleteFinalBody =>
      'Bevestig dat je dit account definitief wilt verwijderen.';

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

  @override
  String get calendarTodayTitle => 'Vandaag';

  @override
  String get calendarEmptyToday => 'Geen afspraken vandaag.';

  @override
  String get calendarNewEvent => 'Nieuwe afspraak';

  @override
  String get calendarEditEvent => 'Afspraak bewerken';

  @override
  String get calendarTitleLabel => 'Titel';

  @override
  String get calendarLocationLabel => 'Locatie';

  @override
  String get calendarNotesLabel => 'Notities';

  @override
  String get calendarStartsLabel => 'Begint';

  @override
  String get calendarEndsLabel => 'Eindigt';

  @override
  String get calendarTitleRequired => 'Voer een titel in.';

  @override
  String get calendarInvalidRange =>
      'Het einde moet op of na het begin liggen.';

  @override
  String get calendarSaveFailed => 'De afspraak kon niet worden opgeslagen.';

  @override
  String get calendarDeleted => 'Afspraak verwijderd.';

  @override
  String get calendarUndo => 'Ongedaan maken';

  @override
  String get calendarLoadFailed => 'Afspraken konden niet worden geladen.';

  @override
  String get calendarAllDay => 'Hele dag';

  @override
  String get calendarRecurrenceLabel => 'Herhaling';

  @override
  String get calendarRecurrenceDoesNotRepeat => 'Herhaalt niet';

  @override
  String get calendarRecurrenceDaily => 'Dagelijks';

  @override
  String get calendarRecurrenceWeekly => 'Wekelijks';

  @override
  String get calendarRecurrenceMonthly => 'Maandelijks';

  @override
  String get calendarRecurrenceYearly => 'Jaarlijks';

  @override
  String get calendarRecurrenceEndsNever => 'Eindigt nooit';

  @override
  String get calendarRecurrenceEndsOnDate => 'Eindigt op een datum';

  @override
  String get calendarRecurrenceScopeTitle => 'Welke gebeurtenissen?';

  @override
  String get calendarRecurrenceThisOccurrence => 'Deze gebeurtenis';

  @override
  String get calendarRecurrenceThisAndFollowing => 'Deze en volgende';

  @override
  String get calendarRecurrenceAllEvents => 'Alle gebeurtenissen';

  @override
  String get syncPendingChanges => 'Wijzigingen wachten op synchronisatie';

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wijzigingen wachten op synchronisatie',
      one: '$count wijziging wacht op synchronisatie',
    );
    return '$_temp0';
  }

  @override
  String get errorsOfflineBody =>
      'Je bent offline. Wijzigingen blijven op dit apparaat tot de verbinding terug is.';

  @override
  String get designGalleryTitle => 'Componentgalerij';

  @override
  String get designGalleryLight => 'Licht';

  @override
  String get designGalleryDark => 'Donker';

  @override
  String get designGalleryWeekdaySample => 'woensdag';

  @override
  String get designGalleryDateSample => '3 september';

  @override
  String get designGalleryEventTitle => 'Werkoverleg';

  @override
  String get designGalleryEventMeta => '60 min';

  @override
  String get designGalleryOpeningTitle => 'Vrij tot 16:00';

  @override
  String get designGalleryStaleSample => 'Wereldlaag bijgewerkt 3 uur geleden';

  @override
  String get birthdaySampleName => 'Ada';

  @override
  String get birthdaySectionTitle => 'Verjaardagen';

  @override
  String get birthdayNew => 'Nieuwe verjaardag';

  @override
  String get birthdayEdit => 'Verjaardag bewerken';

  @override
  String get birthdayNameLabel => 'Naam';

  @override
  String get birthdayMonthLabel => 'Maand';

  @override
  String get birthdayDayLabel => 'Dag';

  @override
  String get birthdayYearLabel => 'Jaar (optioneel)';

  @override
  String get birthdayNotesLabel => 'Notities';

  @override
  String get birthdayNameRequired => 'Voer een naam in.';

  @override
  String get birthdayInvalidDate => 'Voer een geldige maand en dag in.';

  @override
  String get birthdaySaveFailed => 'De verjaardag kon niet worden opgeslagen.';

  @override
  String get birthdayDeleted => 'Verjaardag verwijderd.';

  @override
  String get birthdayEmpty => 'Nog geen verjaardagen.';

  @override
  String birthdayAge(int age) {
    return '$age jaar';
  }

  @override
  String get birthdayLoadFailed => 'Verjaardagen konden niet worden geladen.';

  @override
  String get navDay => 'Dag';

  @override
  String get navWeek => 'Week';

  @override
  String get navMonth => 'Maand';

  @override
  String get navYear => 'Jaar';

  @override
  String get navSeason => 'Seizoen';

  @override
  String get chromeNew => 'Nieuw';

  @override
  String get chromeSettings => 'Instellingen';

  @override
  String get navZoomWeekdays => 'Dagen van de week';

  @override
  String get navZoomWeeks => 'Weken van de maand';

  @override
  String get navZoomMonths => 'Maanden van het seizoen';

  @override
  String get navScaleJump => 'Tijdschaal';

  @override
  String get zoomMonday => 'ma';

  @override
  String get zoomTuesday => 'di';

  @override
  String get zoomWednesday => 'wo';

  @override
  String get zoomThursday => 'do';

  @override
  String get zoomFriday => 'vr';

  @override
  String get zoomSaturday => 'za';

  @override
  String get zoomSunday => 'zo';

  @override
  String weekHeading(int week) {
    return 'week $week';
  }

  @override
  String get yearOverview => 'overzicht';

  @override
  String get yearLegendEvent => 'afspraak';

  @override
  String get yearLegendBirthday => 'verjaardag';

  @override
  String get seasonSpring => 'lente';

  @override
  String get seasonSummer => 'zomer';

  @override
  String get seasonAutumn => 'herfst';

  @override
  String get seasonWinter => 'winter';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get settingsLanguage => 'Taal';

  @override
  String get settingsHomeCity => 'Woonplaats';

  @override
  String get settingsSchoolRegion => 'Schoolvakantieregio';

  @override
  String get languageNameNl => 'Nederlands';

  @override
  String get languageNameEn => 'English';

  @override
  String get onboardingLanguageTitle => 'Welke taal';

  @override
  String get onboardingLanguageBody =>
      'Gekozen uit de taal van je telefoon. Je kunt dit later wijzigen.';

  @override
  String get onboardingCityTitle => 'Waar woon je';

  @override
  String get onboardingCityHint =>
      'Optioneel. Zonder stad blijft de kalender werken; de wereldlaag is dunner.';

  @override
  String get onboardingCitySkip => 'Overslaan';

  @override
  String get onboardingRegionTitle => 'Welke schoolvakantieregio';

  @override
  String get onboardingRegionNoord => 'Noord';

  @override
  String get onboardingRegionCentraal => 'Centraal';

  @override
  String get onboardingRegionZuid => 'Zuid';

  @override
  String get onboardingRegionUnknown => 'Weet ik niet';

  @override
  String get onboardingContinue => 'Doorgaan';

  @override
  String get onboardingSkip => 'Overslaan';

  @override
  String get dayTagBirthday => 'verjaardag';

  @override
  String get dayTagAllDay => 'hele dag';

  @override
  String dayDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get weekDayEmpty => '—';

  @override
  String get eventShare => 'Deel';

  @override
  String get searchOpen => 'Zoeken';

  @override
  String get searchHint => 'Titel of notitie';

  @override
  String get searchEmpty => 'Niets gevonden.';

  @override
  String get feedEmptyDays => 'Lege dagen';

  @override
  String get feedEmptyCompact => 'Compact';

  @override
  String get feedEmptyCollapsed => 'Ingeklapt';

  @override
  String get feedEmptyHidden => 'Verborgen';

  @override
  String feedEmptyGroup(int count) {
    return '$count lege dagen';
  }

  @override
  String get categoryTitle => 'Categorieën';

  @override
  String get categoryAdd => 'Nieuw';

  @override
  String get categoryName => 'Naam';

  @override
  String get categoryEmpty => 'Nog geen categorieën.';

  @override
  String get categoryFull => 'Hooguit acht categorieën.';

  @override
  String get categoryDelete => 'Verwijder';

  @override
  String get categoryEvent => 'Categorie';

  @override
  String get feedBackToToday => 'Vandaag';

  @override
  String get feedNow => 'nu';

  @override
  String feedMore(int count) {
    return '+$count meer';
  }

  @override
  String get feedShowLess => 'minder';

  @override
  String get feedDstPlus => '+1u';

  @override
  String get feedDstMinus => '−1u';

  @override
  String get eventUntitled => 'Zonder titel';

  @override
  String get eventEdit => 'Wijzig';

  @override
  String get eventCancel => 'Annuleer';

  @override
  String get eventMakeMultiDay => 'Meerdere dagen';

  @override
  String get eventRangeTooLong => 'Een afspraak duurt hier hoogstens 30 dagen.';

  @override
  String get eventMoreDetails => 'Meer';
}
