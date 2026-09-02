import 'package:vrijdag/core/config/app_config.dart';

/// Whether telemetry SDKs may initialize for this session (DEC-016).
///
/// F-001: local and staging bypass consent when keys are present.
/// Production returns false until the consent UI ships in F-002.
bool resolveTelemetryConsent(AppConfig config) {
  if (config.telemetryAllowedWithoutConsent) {
    return true;
  }
  return false;
}
