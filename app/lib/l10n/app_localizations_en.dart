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
}
