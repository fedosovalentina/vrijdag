import 'package:vrijdag/core/config/vrijdag_env.dart';

/// Client-safe configuration loaded at build time from `--dart-define`.
///
/// SERVER-ONLY values (service role, OAuth secrets, provider API keys) must
/// never appear here.
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.sentryDsn,
    required this.posthogApiKey,
    required this.posthogHost,
    required this.appVersion,
  });

  final VrijdagEnv environment;
  final String supabaseUrl;
  final String supabasePublishableKey;
  final String? sentryDsn;
  final String? posthogApiKey;
  final String posthogHost;
  final String appVersion;

  bool get isProduction => environment == VrijdagEnv.production;

  /// F-001: local and staging may emit telemetry when keys are present.
  /// Production waits for explicit consent (DEC-016).
  bool get telemetryAllowedWithoutConsent => !isProduction;

  bool get hasSentry => isUsableSentryDsn(sentryDsn);

  bool get hasPosthog => posthogApiKey != null && posthogApiKey!.isNotEmpty;

  /// Default local API URL from `supabase/config.toml` (safe to ship — not a secret).
  /// Offset from CLI defaults so another local Supabase project can keep 54321.
  static const defaultLocalSupabaseUrl = 'http://127.0.0.1:54421';

  static const defaultLocalSupabasePublishableKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
      'eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.'
      'CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0';

  static const defaultPosthogHost = 'https://eu.i.posthog.com';

  /// Rejects empty values and README placeholders like YOUR_KEY / YOUR_ORG / PROJECT.
  static bool isUsableSentryDsn(String? dsn) {
    if (dsn == null || dsn.isEmpty) {
      return false;
    }
    final lower = dsn.toLowerCase();
    if (lower.contains('your_key') ||
        lower.contains('your_org') ||
        lower.contains('/project') ||
        lower.contains('…') ||
        lower.contains('...')) {
      return false;
    }
    final uri = Uri.tryParse(dsn);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return false;
    }
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return false;
    }
    // Real Sentry DSNs look like https://<key>@<host>/<projectId>
    if (uri.userInfo.isEmpty || uri.pathSegments.isEmpty) {
      return false;
    }
    final projectId = uri.pathSegments.last;
    if (int.tryParse(projectId) == null) {
      return false;
    }
    return true;
  }

  factory AppConfig.fromEnvironment({String appVersion = '0.1.0+1'}) {
    const envRaw = String.fromEnvironment('VRIJDAG_ENV');
    const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
    const supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const sentryDsn = String.fromEnvironment('SENTRY_DSN');
    const posthogApiKey = String.fromEnvironment('POSTHOG_API_KEY');
    const posthogHost = String.fromEnvironment('POSTHOG_HOST');
    const versionDefine = String.fromEnvironment('APP_VERSION');

    final environment = VrijdagEnv.parse(envRaw.isEmpty ? null : envRaw);
    final resolvedSentryDsn = isUsableSentryDsn(sentryDsn) ? sentryDsn : null;

    return AppConfig(
      environment: environment,
      supabaseUrl: supabaseUrl.isNotEmpty
          ? supabaseUrl
          : (environment == VrijdagEnv.local ? defaultLocalSupabaseUrl : ''),
      supabasePublishableKey: supabaseKey.isNotEmpty
          ? supabaseKey
          : (environment == VrijdagEnv.local
                ? defaultLocalSupabasePublishableKey
                : ''),
      sentryDsn: resolvedSentryDsn,
      posthogApiKey: posthogApiKey.isEmpty ? null : posthogApiKey,
      posthogHost: posthogHost.isNotEmpty ? posthogHost : defaultPosthogHost,
      appVersion: versionDefine.isNotEmpty ? versionDefine : appVersion,
    );
  }
}
