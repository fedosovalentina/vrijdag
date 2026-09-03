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
