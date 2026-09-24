// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonAppName => 'Vrijdag';

  @override
  String get commonToday => 'Today';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonRetry => 'Retry';

  @override
  String get bootstrapFoundationMessage =>
      'Technical foundation for F-001. Day screen and data follow in later features.';

  @override
  String get bootstrapStatusReady => 'Environment scaffold ready.';

  @override
  String bootstrapEnvironment(String environment) {
    return 'Environment: $environment';
  }

  @override
  String get bootstrapSupabaseConnected => 'Supabase client ready.';

  @override
  String get bootstrapSupabaseUnavailable => 'Supabase not configured.';

  @override
  String get bootstrapTestCrash => 'Test crash';

  @override
  String get bootstrapSentryReady => 'Sentry ready.';

  @override
  String get bootstrapSentryUnavailable => 'Sentry not configured.';

  @override
  String get authSignInTitle => 'Sign in';

  @override
  String get authTagline => 'Your own time, and what sits around it.';

  @override
  String get authUseDifferentEmail => 'Use a different email';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authSendMagicLink => 'Send sign-in link';

  @override
  String get authCheckEmail => 'Open the link in your email to continue.';

  @override
  String get authInvalidEmail => 'Enter a valid email address.';

  @override
  String get authSendFailed =>
      'The sign-in link could not be sent. Try again later.';

  @override
  String get authSendRateLimited =>
      'Too many sign-in emails. Wait about an hour, or check spam.';

  @override
  String get authSignOut => 'Sign out';

  @override
  String authSignedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get authSupabaseRequired => 'Supabase is required to sign in.';

  @override
  String get authSignInWithApple => 'Sign in with Apple';

  @override
  String get authAppleFailed =>
      'Sign in with Apple failed. Check that Apple Sign In is configured.';

  @override
  String get authOrEmail => 'Or with email';

  @override
  String get authDeleteAccount => 'Delete account';

  @override
  String get authDeleteConfirmTitle => 'Delete account?';

  @override
  String get authDeleteConfirmBody =>
      'This removes your account and all personal data. World data is unaffected. This cannot be undone.';

  @override
  String get authDeleteConfirmContinue => 'Continue';

  @override
  String get authDeleteFinalTitle => 'Delete permanently';

  @override
  String get authDeleteFinalBody =>
      'Confirm that you want to permanently delete this account.';

  @override
  String get authDeleteFinalAction => 'Delete account permanently';

  @override
  String get authDeleteFailed =>
      'The account could not be deleted. Try again later.';

  @override
  String get authSignOutPendingTitle => 'Unsynced changes';

  @override
  String get authSignOutPendingBody =>
      'Some changes are still waiting to sync with the server. Signing out leaves them on this device until next time.';

  @override
  String get authSignOutPendingContinue => 'Sign out anyway';

  @override
  String get calendarTodayTitle => 'Today';

  @override
  String get calendarEmptyToday => 'No events today.';

  @override
  String get calendarNewEvent => 'New event';

  @override
  String get calendarEditEvent => 'Edit event';

  @override
  String get calendarTitleLabel => 'Title';

  @override
  String get calendarLocationLabel => 'Location';

  @override
  String get calendarNotesLabel => 'Notes';

  @override
  String get calendarStartsLabel => 'Starts';

  @override
  String get calendarEndsLabel => 'Ends';

  @override
  String get calendarTitleRequired => 'Enter a title.';

  @override
  String get calendarInvalidRange => 'The end must be on or after the start.';

  @override
  String get calendarSaveFailed => 'The event could not be saved.';

  @override
  String get calendarDeleted => 'Event deleted.';

  @override
  String get calendarUndo => 'Undo';

  @override
  String get calendarLoadFailed => 'Events could not be loaded.';

  @override
  String get calendarAllDay => 'All day';

  @override
  String get calendarRecurrenceLabel => 'Repeat';

  @override
  String get calendarRecurrenceDoesNotRepeat => 'Does not repeat';

  @override
  String get calendarRecurrenceDaily => 'Daily';

  @override
  String get calendarRecurrenceWeekly => 'Weekly';

  @override
  String get calendarRecurrenceMonthly => 'Monthly';

  @override
  String get calendarRecurrenceYearly => 'Yearly';

  @override
  String get calendarRecurrenceEndsNever => 'Ends never';

  @override
  String get calendarRecurrenceEndsOnDate => 'Ends on a date';

  @override
  String get calendarRecurrenceScopeTitle => 'Which events?';

  @override
  String get calendarRecurrenceThisOccurrence => 'This event';

  @override
  String get calendarRecurrenceThisAndFollowing => 'This and following';

  @override
  String get calendarRecurrenceAllEvents => 'All events';

  @override
  String get syncPendingChanges => 'Changes waiting to sync';

  @override
  String syncPendingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes waiting to sync',
      one: '$count change waiting to sync',
    );
    return '$_temp0';
  }

  @override
  String get errorsOfflineBody =>
      'You are offline. Changes stay on this device until the connection returns.';

  @override
  String get designGalleryTitle => 'Component gallery';

  @override
  String get designGalleryLight => 'Light';

  @override
  String get designGalleryDark => 'Dark';

  @override
  String get designGalleryWeekdaySample => 'Wednesday';

  @override
  String get designGalleryDateSample => '3 September';

  @override
  String get designGalleryEventTitle => 'Planning conversation';

  @override
  String get designGalleryEventMeta => '60 min';

  @override
  String get designGalleryOpeningTitle => 'Free until 16:00';

  @override
  String get designGalleryStaleSample => 'World layer updated 3 hours ago';

  @override
  String get birthdaySampleName => 'Ada';

  @override
  String get birthdaySectionTitle => 'Birthdays';

  @override
  String get birthdayNew => 'New birthday';

  @override
  String get birthdayEdit => 'Edit birthday';

  @override
  String get birthdayNameLabel => 'Name';

  @override
  String get birthdayMonthLabel => 'Month';

  @override
  String get birthdayDayLabel => 'Day';

  @override
  String get birthdayYearLabel => 'Year (optional)';

  @override
  String get birthdayNotesLabel => 'Notes';

  @override
  String get birthdayNameRequired => 'Enter a name.';

  @override
  String get birthdayInvalidDate => 'Enter a valid month and day.';

  @override
  String get birthdaySaveFailed => 'The birthday could not be saved.';

  @override
  String get birthdayDeleted => 'Birthday deleted.';

  @override
  String get birthdayEmpty => 'No birthdays yet.';

  @override
  String birthdayAge(int age) {
    return '$age years';
  }

  @override
  String get birthdayLoadFailed => 'Birthdays could not be loaded.';

  @override
  String get navDay => 'Day';

  @override
  String get navWeek => 'Week';

  @override
  String get navMonth => 'Month';

  @override
  String get navYear => 'Year';

  @override
  String get navSeason => 'Season';

  @override
  String get chromeNew => 'New';

  @override
  String get chromeSettings => 'Settings';

  @override
  String get navZoomWeekdays => 'Days of the week';

  @override
  String get navZoomWeeks => 'Weeks of the month';

  @override
  String get navZoomMonths => 'Months of the season';

  @override
  String get navScaleJump => 'Time scale';

  @override
  String get zoomMonday => 'Mo';

  @override
  String get zoomTuesday => 'Tu';

  @override
  String get zoomWednesday => 'We';

  @override
  String get zoomThursday => 'Th';

  @override
  String get zoomFriday => 'Fr';

  @override
  String get zoomSaturday => 'Sa';

  @override
  String get zoomSunday => 'Su';

  @override
  String weekHeading(int week) {
    return 'week $week';
  }

  @override
  String get yearOverview => 'overview';

  @override
  String get yearLegendEvent => 'event';

  @override
  String get yearLegendBirthday => 'birthday';

  @override
  String get seasonSpring => 'spring';

  @override
  String get seasonSummer => 'summer';

  @override
  String get seasonAutumn => 'autumn';

  @override
  String get seasonWinter => 'winter';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsHomeCity => 'Home city';

  @override
  String get settingsSchoolRegion => 'School holiday region';

  @override
  String get languageNameNl => 'Nederlands';

  @override
  String get languageNameEn => 'English';

  @override
  String get onboardingLanguageTitle => 'Which language';

  @override
  String get onboardingLanguageBody =>
      'Taken from your phone language. You can change this later.';

  @override
  String get onboardingCityTitle => 'Where do you live';

  @override
  String get onboardingCityHint =>
      'Optional. Without a city the calendar still works; the world layer is thinner.';

  @override
  String get onboardingCitySkip => 'Skip';

  @override
  String get onboardingRegionTitle => 'Which school holiday region';

  @override
  String get onboardingRegionNoord => 'North';

  @override
  String get onboardingRegionCentraal => 'Central';

  @override
  String get onboardingRegionZuid => 'South';

  @override
  String get onboardingRegionUnknown => 'I don\'t know';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get dayTagBirthday => 'birthday';

  @override
  String get dayTagAllDay => 'all day';

  @override
  String dayDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get weekDayEmpty => '—';

  @override
  String get categoryTitle => 'Categories';

  @override
  String get categoryAdd => 'New';

  @override
  String get categoryName => 'Name';

  @override
  String get categoryEmpty => 'No categories yet.';

  @override
  String get categoryFull => 'At most eight categories.';

  @override
  String get categoryDelete => 'Delete';

  @override
  String get categoryEvent => 'Category';

  @override
  String get feedBackToToday => 'Today';

  @override
  String get feedNow => 'now';

  @override
  String feedMore(int count) {
    return '+$count more';
  }

  @override
  String get feedShowLess => 'show less';

  @override
  String get feedDstPlus => '+1h';

  @override
  String get feedDstMinus => '−1h';

  @override
  String get eventUntitled => 'Untitled';

  @override
  String get eventEdit => 'Edit';

  @override
  String get eventCancel => 'Cancel';

  @override
  String get eventMakeMultiDay => 'Several days';

  @override
  String get eventRangeTooLong => 'An event here lasts at most 30 days.';

  @override
  String get eventMoreDetails => 'More';
}
