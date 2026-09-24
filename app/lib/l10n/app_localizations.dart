import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
  ];

  /// Application name shown in the shell and system UI.
  ///
  /// In nl, this message translates to:
  /// **'Vrijdag'**
  String get commonAppName;

  /// Label for the current day.
  ///
  /// In nl, this message translates to:
  /// **'Vandaag'**
  String get commonToday;

  /// Label for the next day.
  ///
  /// In nl, this message translates to:
  /// **'Morgen'**
  String get commonTomorrow;

  /// Label for the previous day.
  ///
  /// In nl, this message translates to:
  /// **'Gisteren'**
  String get commonYesterday;

  /// Dismiss an action without saving.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get commonCancel;

  /// Confirm and persist changes.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get commonSave;

  /// Remove an item after explicit confirmation.
  ///
  /// In nl, this message translates to:
  /// **'Verwijderen'**
  String get commonDelete;

  /// Try a failed action again.
  ///
  /// In nl, this message translates to:
  /// **'Opnieuw'**
  String get commonRetry;

  /// Placeholder copy on the bootstrap screen while the app shell is being built.
  ///
  /// In nl, this message translates to:
  /// **'Technische basis voor F-001. Dag-scherm en data volgen in latere features.'**
  String get bootstrapFoundationMessage;

  /// Status line on the bootstrap screen when the scaffold is ready.
  ///
  /// In nl, this message translates to:
  /// **'Omgevingsskelet gereed.'**
  String get bootstrapStatusReady;

  /// Shows the active build-time environment on the bootstrap screen.
  ///
  /// In nl, this message translates to:
  /// **'Omgeving: {environment}'**
  String bootstrapEnvironment(String environment);

  /// Supabase initialized successfully at startup.
  ///
  /// In nl, this message translates to:
  /// **'Supabase-client gereed.'**
  String get bootstrapSupabaseConnected;

  /// Supabase URL or publishable key missing for this build.
  ///
  /// In nl, this message translates to:
  /// **'Supabase niet geconfigureerd.'**
  String get bootstrapSupabaseUnavailable;

  /// Debug control that sends a deliberate crash to error reporting.
  ///
  /// In nl, this message translates to:
  /// **'Testcrash'**
  String get bootstrapTestCrash;

  /// Sentry DSN present and telemetry allowed for this build.
  ///
  /// In nl, this message translates to:
  /// **'Sentry gereed.'**
  String get bootstrapSentryReady;

  /// Sentry DSN missing — test crash is unavailable.
  ///
  /// In nl, this message translates to:
  /// **'Sentry niet geconfigureerd.'**
  String get bootstrapSentryUnavailable;

  /// Title of the sign-in screen.
  ///
  /// In nl, this message translates to:
  /// **'Inloggen'**
  String get authSignInTitle;

  /// Dry one-line product description on sign-in. Independently written Dutch.
  ///
  /// In nl, this message translates to:
  /// **'Je eigen tijd, en wat eromheen gebeurt.'**
  String get authTagline;

  /// Return from check-email state to the magic-link form.
  ///
  /// In nl, this message translates to:
  /// **'Ander e-mailadres'**
  String get authUseDifferentEmail;

  /// Label for the email field on magic-link sign-in.
  ///
  /// In nl, this message translates to:
  /// **'E-mailadres'**
  String get authEmailLabel;

  /// Primary button that sends the magic link email.
  ///
  /// In nl, this message translates to:
  /// **'Stuur inloglink'**
  String get authSendMagicLink;

  /// Shown after a magic link has been sent successfully.
  ///
  /// In nl, this message translates to:
  /// **'Open de link in je e-mail om verder te gaan.'**
  String get authCheckEmail;

  /// Validation error when the email field is empty or malformed.
  ///
  /// In nl, this message translates to:
  /// **'Voer een geldig e-mailadres in.'**
  String get authInvalidEmail;

  /// Generic failure when magic link send fails.
  ///
  /// In nl, this message translates to:
  /// **'De inloglink kon niet worden gestuurd. Probeer het later opnieuw.'**
  String get authSendFailed;

  /// Supabase built-in email rate limit (over_email_send_rate_limit).
  ///
  /// In nl, this message translates to:
  /// **'Te veel inlogmails. Wacht ongeveer een uur, of kijk in spam.'**
  String get authSendRateLimited;

  /// Sign out action.
  ///
  /// In nl, this message translates to:
  /// **'Uitloggen'**
  String get authSignOut;

  /// Status line showing the signed-in email.
  ///
  /// In nl, this message translates to:
  /// **'Ingelogd als {email}'**
  String authSignedInAs(String email);

  /// Shown when auth UI is opened without a configured Supabase client.
  ///
  /// In nl, this message translates to:
  /// **'Supabase is nodig om in te loggen.'**
  String get authSupabaseRequired;

  /// Sign in with Apple button label.
  ///
  /// In nl, this message translates to:
  /// **'Log in met Apple'**
  String get authSignInWithApple;

  /// Shown when Sign in with Apple fails (capability/provider missing).
  ///
  /// In nl, this message translates to:
  /// **'Inloggen met Apple is mislukt. Controleer of Apple Sign In is geconfigureerd.'**
  String get authAppleFailed;

  /// Divider label between Apple and magic-link options.
  ///
  /// In nl, this message translates to:
  /// **'Of met e-mail'**
  String get authOrEmail;

  /// Opens the two-step account deletion flow.
  ///
  /// In nl, this message translates to:
  /// **'Account verwijderen'**
  String get authDeleteAccount;

  /// First confirmation title for account deletion.
  ///
  /// In nl, this message translates to:
  /// **'Account verwijderen?'**
  String get authDeleteConfirmTitle;

  /// First confirmation body — factual, no drama.
  ///
  /// In nl, this message translates to:
  /// **'Dit verwijdert je account en alle persoonlijke gegevens. Wereldgegevens blijven onaangetast. Dit is niet terug te draaien.'**
  String get authDeleteConfirmBody;

  /// Proceed from first deletion confirmation to the final step.
  ///
  /// In nl, this message translates to:
  /// **'Doorgaan'**
  String get authDeleteConfirmContinue;

  /// Second confirmation title for account deletion.
  ///
  /// In nl, this message translates to:
  /// **'Definitief verwijderen'**
  String get authDeleteFinalTitle;

  /// Second confirmation body for account deletion.
  ///
  /// In nl, this message translates to:
  /// **'Bevestig dat je dit account definitief wilt verwijderen.'**
  String get authDeleteFinalBody;

  /// Final destructive button that calls the delete-account function.
  ///
  /// In nl, this message translates to:
  /// **'Account definitief verwijderen'**
  String get authDeleteFinalAction;

  /// Shown when the delete-account Edge Function fails.
  ///
  /// In nl, this message translates to:
  /// **'Het account kon niet worden verwijderd. Probeer het later opnieuw.'**
  String get authDeleteFailed;

  /// Title when signing out while the write queue still has intents.
  ///
  /// In nl, this message translates to:
  /// **'Niet-gesynchroniseerde wijzigingen'**
  String get authSignOutPendingTitle;

  /// Warns that signing out does not discard the local write queue.
  ///
  /// In nl, this message translates to:
  /// **'Er staan wijzigingen klaar die nog niet met de server zijn gesynchroniseerd. Als je nu uitlogt, blijven ze op dit apparaat tot de volgende keer.'**
  String get authSignOutPendingBody;

  /// Confirm sign-out despite pending offline intents.
  ///
  /// In nl, this message translates to:
  /// **'Toch uitloggen'**
  String get authSignOutPendingContinue;

  /// Heading for the utilitarian today event list.
  ///
  /// In nl, this message translates to:
  /// **'Vandaag'**
  String get calendarTodayTitle;

  /// Empty state when there are no personal events today.
  ///
  /// In nl, this message translates to:
  /// **'Geen afspraken vandaag.'**
  String get calendarEmptyToday;

  /// Button / screen title to create a timed event.
  ///
  /// In nl, this message translates to:
  /// **'Nieuwe afspraak'**
  String get calendarNewEvent;

  /// Screen title when editing an existing personal event.
  ///
  /// In nl, this message translates to:
  /// **'Afspraak bewerken'**
  String get calendarEditEvent;

  /// Event title field label.
  ///
  /// In nl, this message translates to:
  /// **'Titel'**
  String get calendarTitleLabel;

  /// Optional free-text location field.
  ///
  /// In nl, this message translates to:
  /// **'Locatie'**
  String get calendarLocationLabel;

  /// Optional notes field.
  ///
  /// In nl, this message translates to:
  /// **'Notities'**
  String get calendarNotesLabel;

  /// Label for the event start date/time field.
  ///
  /// In nl, this message translates to:
  /// **'Begint'**
  String get calendarStartsLabel;

  /// Label for the event end date/time field.
  ///
  /// In nl, this message translates to:
  /// **'Eindigt'**
  String get calendarEndsLabel;

  /// Validation when title is empty.
  ///
  /// In nl, this message translates to:
  /// **'Voer een titel in.'**
  String get calendarTitleRequired;

  /// Validation when end is before start.
  ///
  /// In nl, this message translates to:
  /// **'Het einde moet op of na het begin liggen.'**
  String get calendarInvalidRange;

  /// Generic save failure for personal events.
  ///
  /// In nl, this message translates to:
  /// **'De afspraak kon niet worden opgeslagen.'**
  String get calendarSaveFailed;

  /// Snack after soft-delete.
  ///
  /// In nl, this message translates to:
  /// **'Afspraak verwijderd.'**
  String get calendarDeleted;

  /// Undo soft-delete within the undo window.
  ///
  /// In nl, this message translates to:
  /// **'Ongedaan maken'**
  String get calendarUndo;

  /// Shown when today's event list fails to load.
  ///
  /// In nl, this message translates to:
  /// **'Afspraken konden niet worden geladen.'**
  String get calendarLoadFailed;

  /// Toggle / badge for all-day events.
  ///
  /// In nl, this message translates to:
  /// **'Hele dag'**
  String get calendarAllDay;

  /// Label for the recurrence frequency field on the event editor.
  ///
  /// In nl, this message translates to:
  /// **'Herhaling'**
  String get calendarRecurrenceLabel;

  /// Recurrence option: event does not repeat.
  ///
  /// In nl, this message translates to:
  /// **'Herhaalt niet'**
  String get calendarRecurrenceDoesNotRepeat;

  /// Recurrence option: every day.
  ///
  /// In nl, this message translates to:
  /// **'Dagelijks'**
  String get calendarRecurrenceDaily;

  /// Recurrence option: every week on the start weekday.
  ///
  /// In nl, this message translates to:
  /// **'Wekelijks'**
  String get calendarRecurrenceWeekly;

  /// Recurrence option: every month.
  ///
  /// In nl, this message translates to:
  /// **'Maandelijks'**
  String get calendarRecurrenceMonthly;

  /// Recurrence option: every year.
  ///
  /// In nl, this message translates to:
  /// **'Jaarlijks'**
  String get calendarRecurrenceYearly;

  /// Recurrence end option: no until date.
  ///
  /// In nl, this message translates to:
  /// **'Eindigt nooit'**
  String get calendarRecurrenceEndsNever;

  /// Recurrence end option: series ends on a chosen date.
  ///
  /// In nl, this message translates to:
  /// **'Eindigt op een datum'**
  String get calendarRecurrenceEndsOnDate;

  /// Title for edit/delete scope of a recurring series.
  ///
  /// In nl, this message translates to:
  /// **'Welke gebeurtenissen?'**
  String get calendarRecurrenceScopeTitle;

  /// Scope: only this occurrence (V1 unused for delete).
  ///
  /// In nl, this message translates to:
  /// **'Deze gebeurtenis'**
  String get calendarRecurrenceThisOccurrence;

  /// Scope: this and following occurrences (V1 unused for delete).
  ///
  /// In nl, this message translates to:
  /// **'Deze en volgende'**
  String get calendarRecurrenceThisAndFollowing;

  /// Scope: entire recurring series.
  ///
  /// In nl, this message translates to:
  /// **'Alle gebeurtenissen'**
  String get calendarRecurrenceAllEvents;

  /// Short offline/pending sync banner title.
  ///
  /// In nl, this message translates to:
  /// **'Wijzigingen wachten op synchronisatie'**
  String get syncPendingChanges;

  /// Pending write-queue count for the offline banner.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, one{{count} wijziging wacht op synchronisatie} other{{count} wijzigingen wachten op synchronisatie}}'**
  String syncPendingCount(int count);

  /// Explains that offline edits remain local until reconnect.
  ///
  /// In nl, this message translates to:
  /// **'Je bent offline. Wijzigingen blijven op dit apparaat tot de verbinding terug is.'**
  String get errorsOfflineBody;

  /// Debug-only gallery of shared UI components.
  ///
  /// In nl, this message translates to:
  /// **'Componentgalerij'**
  String get designGalleryTitle;

  /// Light theme tab in the component gallery.
  ///
  /// In nl, this message translates to:
  /// **'Licht'**
  String get designGalleryLight;

  /// Dark theme tab in the component gallery.
  ///
  /// In nl, this message translates to:
  /// **'Donker'**
  String get designGalleryDark;

  /// Sample weekday for DateHeader in the gallery.
  ///
  /// In nl, this message translates to:
  /// **'woensdag'**
  String get designGalleryWeekdaySample;

  /// Sample date for DateHeader in the gallery.
  ///
  /// In nl, this message translates to:
  /// **'3 september'**
  String get designGalleryDateSample;

  /// Sample event title in the gallery.
  ///
  /// In nl, this message translates to:
  /// **'Werkoverleg'**
  String get designGalleryEventTitle;

  /// Sample event meta line in the gallery.
  ///
  /// In nl, this message translates to:
  /// **'60 min'**
  String get designGalleryEventMeta;

  /// Sample opening row in the gallery.
  ///
  /// In nl, this message translates to:
  /// **'Vrij tot 16:00'**
  String get designGalleryOpeningTitle;

  /// Sample stale badge copy in the gallery.
  ///
  /// In nl, this message translates to:
  /// **'Wereldlaag bijgewerkt 3 uur geleden'**
  String get designGalleryStaleSample;

  /// Sample birthday name for gallery / fixtures.
  ///
  /// In nl, this message translates to:
  /// **'Ada'**
  String get birthdaySampleName;

  /// Heading for the utilitarian birthday list.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardagen'**
  String get birthdaySectionTitle;

  /// Button / screen title to create a birthday.
  ///
  /// In nl, this message translates to:
  /// **'Nieuwe verjaardag'**
  String get birthdayNew;

  /// Screen title when editing a birthday.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag bewerken'**
  String get birthdayEdit;

  /// Birthday name field label.
  ///
  /// In nl, this message translates to:
  /// **'Naam'**
  String get birthdayNameLabel;

  /// Birthday month field label.
  ///
  /// In nl, this message translates to:
  /// **'Maand'**
  String get birthdayMonthLabel;

  /// Birthday day field label.
  ///
  /// In nl, this message translates to:
  /// **'Dag'**
  String get birthdayDayLabel;

  /// Optional birth year field.
  ///
  /// In nl, this message translates to:
  /// **'Jaar (optioneel)'**
  String get birthdayYearLabel;

  /// Optional birthday notes field.
  ///
  /// In nl, this message translates to:
  /// **'Notities'**
  String get birthdayNotesLabel;

  /// Validation when birthday name is empty.
  ///
  /// In nl, this message translates to:
  /// **'Voer een naam in.'**
  String get birthdayNameRequired;

  /// Validation for impossible month/day combinations.
  ///
  /// In nl, this message translates to:
  /// **'Voer een geldige maand en dag in.'**
  String get birthdayInvalidDate;

  /// Generic save failure for birthdays.
  ///
  /// In nl, this message translates to:
  /// **'De verjaardag kon niet worden opgeslagen.'**
  String get birthdaySaveFailed;

  /// Snack after birthday delete.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardag verwijderd.'**
  String get birthdayDeleted;

  /// Empty state for the birthday list.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen verjaardagen.'**
  String get birthdayEmpty;

  /// Age on Day/Settings. Locked form: 32 jaar (DEC-025).
  ///
  /// In nl, this message translates to:
  /// **'{age} jaar'**
  String birthdayAge(int age);

  /// Shown when the birthday list fails to load.
  ///
  /// In nl, this message translates to:
  /// **'Verjaardagen konden niet worden geladen.'**
  String get birthdayLoadFailed;

  /// Scale jump: Day view.
  ///
  /// In nl, this message translates to:
  /// **'Dag'**
  String get navDay;

  /// Scale jump: Week view.
  ///
  /// In nl, this message translates to:
  /// **'Week'**
  String get navWeek;

  /// Scale jump: Month view.
  ///
  /// In nl, this message translates to:
  /// **'Maand'**
  String get navMonth;

  /// Scale jump: Year view.
  ///
  /// In nl, this message translates to:
  /// **'Jaar'**
  String get navYear;

  /// Scale jump: Season view. Disabled until F-035.
  ///
  /// In nl, this message translates to:
  /// **'Seizoen'**
  String get navSeason;

  /// Utility row: open the event editor. Word, not a FAB.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw'**
  String get chromeNew;

  /// Utility row: open Settings.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get chromeSettings;

  /// Accessibility label for the weekday zoom strip on Day.
  ///
  /// In nl, this message translates to:
  /// **'Dagen van de week'**
  String get navZoomWeekdays;

  /// Accessibility label for the week-number zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'Weken van de maand'**
  String get navZoomWeeks;

  /// Accessibility label for the season-month zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'Maanden van het seizoen'**
  String get navZoomMonths;

  /// Accessibility label for Day Week Month Year Season.
  ///
  /// In nl, this message translates to:
  /// **'Tijdschaal'**
  String get navScaleJump;

  /// Short Monday on the Day zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'ma'**
  String get zoomMonday;

  /// Short Tuesday on the Day zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'di'**
  String get zoomTuesday;

  /// Short Wednesday on the Day zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'wo'**
  String get zoomWednesday;

  /// Short Thursday on the Day zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'do'**
  String get zoomThursday;

  /// Short Friday on the Day zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'vr'**
  String get zoomFriday;

  /// Short Saturday on the Day zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'za'**
  String get zoomSaturday;

  /// Short Sunday on the Day zoom strip.
  ///
  /// In nl, this message translates to:
  /// **'zo'**
  String get zoomSunday;

  /// Spoken week number above the week range.
  ///
  /// In nl, this message translates to:
  /// **'week {week}'**
  String weekHeading(int week);

  /// Eyebrow above the year number on Year.
  ///
  /// In nl, this message translates to:
  /// **'overzicht'**
  String get yearOverview;

  /// Year map legend: filled tick is a personal event.
  ///
  /// In nl, this message translates to:
  /// **'afspraak'**
  String get yearLegendEvent;

  /// Year map legend: ring tick is a birthday.
  ///
  /// In nl, this message translates to:
  /// **'verjaardag'**
  String get yearLegendBirthday;

  /// Meteorological spring (Mar–May). Independently written Dutch.
  ///
  /// In nl, this message translates to:
  /// **'lente'**
  String get seasonSpring;

  /// Meteorological summer (Jun–Aug).
  ///
  /// In nl, this message translates to:
  /// **'zomer'**
  String get seasonSummer;

  /// Meteorological autumn (Sep–Nov).
  ///
  /// In nl, this message translates to:
  /// **'herfst'**
  String get seasonAutumn;

  /// Meteorological winter (Dec–Feb).
  ///
  /// In nl, this message translates to:
  /// **'winter'**
  String get seasonWinter;

  /// Settings screen title. Same word as the chrome action.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get settingsTitle;

  /// Settings row: app language preference.
  ///
  /// In nl, this message translates to:
  /// **'Taal'**
  String get settingsLanguage;

  /// Settings row: optional home city.
  ///
  /// In nl, this message translates to:
  /// **'Woonplaats'**
  String get settingsHomeCity;

  /// Settings row: Dutch school holiday region.
  ///
  /// In nl, this message translates to:
  /// **'Schoolvakantieregio'**
  String get settingsSchoolRegion;

  /// Dutch language option label (shown in its own name).
  ///
  /// In nl, this message translates to:
  /// **'Nederlands'**
  String get languageNameNl;

  /// English language option label (shown in its own name).
  ///
  /// In nl, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// Onboarding screen 1 title.
  ///
  /// In nl, this message translates to:
  /// **'Welke taal'**
  String get onboardingLanguageTitle;

  /// Onboarding screen 1 body. Confirm, do not quiz.
  ///
  /// In nl, this message translates to:
  /// **'Gekozen uit de taal van je telefoon. Je kunt dit later wijzigen.'**
  String get onboardingLanguageBody;

  /// Onboarding screen 2 title.
  ///
  /// In nl, this message translates to:
  /// **'Waar woon je'**
  String get onboardingCityTitle;

  /// Onboarding screen 2 hint. Skip is legitimate.
  ///
  /// In nl, this message translates to:
  /// **'Optioneel. Zonder stad blijft de kalender werken; de wereldlaag is dunner.'**
  String get onboardingCityHint;

  /// Skip control on the home-city onboarding screen.
  ///
  /// In nl, this message translates to:
  /// **'Overslaan'**
  String get onboardingCitySkip;

  /// Onboarding screen 3 title.
  ///
  /// In nl, this message translates to:
  /// **'Welke schoolvakantieregio'**
  String get onboardingRegionTitle;

  /// School holiday region: North.
  ///
  /// In nl, this message translates to:
  /// **'Noord'**
  String get onboardingRegionNoord;

  /// School holiday region: Central (not Midden).
  ///
  /// In nl, this message translates to:
  /// **'Centraal'**
  String get onboardingRegionCentraal;

  /// School holiday region: South.
  ///
  /// In nl, this message translates to:
  /// **'Zuid'**
  String get onboardingRegionZuid;

  /// Explicit unknown region; turns school-holiday layer off.
  ///
  /// In nl, this message translates to:
  /// **'Weet ik niet'**
  String get onboardingRegionUnknown;

  /// Primary continue on onboarding screens.
  ///
  /// In nl, this message translates to:
  /// **'Doorgaan'**
  String get onboardingContinue;

  /// First-class skip on onboarding screens.
  ///
  /// In nl, this message translates to:
  /// **'Overslaan'**
  String get onboardingSkip;

  /// All-day band tag for a birthday on Day.
  ///
  /// In nl, this message translates to:
  /// **'verjaardag'**
  String get dayTagBirthday;

  /// All-day band tag for an all-day personal event.
  ///
  /// In nl, this message translates to:
  /// **'hele dag'**
  String get dayTagAllDay;

  /// Timed event meta duration on Day (mockup: 60 min).
  ///
  /// In nl, this message translates to:
  /// **'{minutes} min'**
  String dayDurationMinutes(int minutes);

  /// Empty day fragment on Week. A dash, not a sentence.
  ///
  /// In nl, this message translates to:
  /// **'—'**
  String get weekDayEmpty;

  /// Settings list of labels the person created for events.
  ///
  /// In nl, this message translates to:
  /// **'Categorieën'**
  String get categoryTitle;

  /// Add a category. Same word as the calendar chrome.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw'**
  String get categoryAdd;

  /// Field label for a category name.
  ///
  /// In nl, this message translates to:
  /// **'Naam'**
  String get categoryName;

  /// Quiet state when the person has created no categories.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen categorieën.'**
  String get categoryEmpty;

  /// Inline sentence when a ninth category is refused.
  ///
  /// In nl, this message translates to:
  /// **'Hooguit acht categorieën.'**
  String get categoryFull;

  /// Remove a category. Its events keep no label.
  ///
  /// In nl, this message translates to:
  /// **'Verwijder'**
  String get categoryDelete;

  /// Event screen row for choosing a label.
  ///
  /// In nl, this message translates to:
  /// **'Categorie'**
  String get categoryEvent;

  /// Feed control that brings today into the upper third.
  ///
  /// In nl, this message translates to:
  /// **'Vandaag'**
  String get feedBackToToday;

  /// Label on the current-time mark in the month feed.
  ///
  /// In nl, this message translates to:
  /// **'nu'**
  String get feedNow;

  /// Collapsed overflow on a month-feed day.
  ///
  /// In nl, this message translates to:
  /// **'+{count} meer'**
  String feedMore(int count);

  /// Collapse an expanded overflow row in the month feed.
  ///
  /// In nl, this message translates to:
  /// **'minder'**
  String get feedShowLess;

  /// Day mark when local midnight-to-midnight is 25 hours.
  ///
  /// In nl, this message translates to:
  /// **'+1u'**
  String get feedDstPlus;

  /// Day mark when local midnight-to-midnight is 23 hours.
  ///
  /// In nl, this message translates to:
  /// **'−1u'**
  String get feedDstMinus;

  /// Saved title when the event name was left empty.
  ///
  /// In nl, this message translates to:
  /// **'Zonder titel'**
  String get eventUntitled;

  /// Switch the event screen from view to edit.
  ///
  /// In nl, this message translates to:
  /// **'Wijzig'**
  String get eventEdit;

  /// Leave edit. Existing event returns to view.
  ///
  /// In nl, this message translates to:
  /// **'Annuleer'**
  String get eventCancel;

  /// Reveal the end date for a one-day event.
  ///
  /// In nl, this message translates to:
  /// **'Meerdere dagen'**
  String get eventMakeMultiDay;

  /// Inline hint when a date range is longer than 30 days.
  ///
  /// In nl, this message translates to:
  /// **'Een afspraak duurt hier hoogstens 30 dagen.'**
  String get eventRangeTooLong;

  /// Expand location, recurrence, and notes.
  ///
  /// In nl, this message translates to:
  /// **'Meer'**
  String get eventMoreDetails;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
