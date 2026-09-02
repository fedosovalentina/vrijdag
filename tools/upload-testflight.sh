#!/usr/bin/env bash
#
# Build a staging IPA and upload to TestFlight via Apple's Transporter.
#
# Requires (from environment or a local .env file — never committed):
#   SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY          — staging Supabase
#   SENTRY_DSN, POSTHOG_API_KEY                     — optional observability
#   APP_STORE_CONNECT_API_KEY_ID                    — preferred auth path
#   APP_STORE_CONNECT_API_ISSUER_ID
#   APP_STORE_CONNECT_API_KEY_PATH                  — path to AuthKey_XXXX.p8
#
# Fallback (legacy):
#   APPLE_ID, APPLE_APP_SPECIFIC_PASSWORD
#
# Usage:
#   ./tools/upload-testflight.sh
#   ./tools/upload-testflight.sh --skip-upload   # build only

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT/app"
SKIP_UPLOAD=false

for arg in "$@"; do
  case "$arg" in
    --skip-upload) SKIP_UPLOAD=true ;;
    *)
      echo "Unknown argument: $arg"
      exit 1
      ;;
  esac
done

if [[ -f "$ROOT/.env" ]]; then
  # shellcheck disable=SC1091
  set -a
  source "$ROOT/.env"
  set +a
fi

: "${SUPABASE_URL:?SUPABASE_URL is required for staging builds}"
: "${SUPABASE_PUBLISHABLE_KEY:?SUPABASE_PUBLISHABLE_KEY is required}"

DART_DEFINES=(
  "--dart-define=VRIJDAG_ENV=staging"
  "--dart-define=SUPABASE_URL=${SUPABASE_URL}"
  "--dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}"
)

if [[ -n "${SENTRY_DSN:-}" ]]; then
  DART_DEFINES+=("--dart-define=SENTRY_DSN=${SENTRY_DSN}")
fi

if [[ -n "${POSTHOG_API_KEY:-}" ]]; then
  DART_DEFINES+=("--dart-define=POSTHOG_API_KEY=${POSTHOG_API_KEY}")
fi

if [[ -n "${POSTHOG_HOST:-}" ]]; then
  DART_DEFINES+=("--dart-define=POSTHOG_HOST=${POSTHOG_HOST}")
fi

echo "upload-testflight.sh: building staging IPA…"
cd "$APP_DIR"
flutter pub get
flutter build ipa --release "${DART_DEFINES[@]}"

IPA_PATH="$(find build/ios/ipa -name '*.ipa' -print -quit)"
if [[ -z "$IPA_PATH" ]]; then
  echo "upload-testflight.sh: IPA not found under build/ios/ipa"
  exit 1
fi

echo "upload-testflight.sh: IPA at $IPA_PATH"

if [[ "$SKIP_UPLOAD" == true ]]; then
  echo "upload-testflight.sh: --skip-upload set; done."
  exit 0
fi

if [[ -n "${APP_STORE_CONNECT_API_KEY_ID:-}" &&
  -n "${APP_STORE_CONNECT_API_ISSUER_ID:-}" &&
  -n "${APP_STORE_CONNECT_API_KEY_PATH:-}" ]]; then
  echo "upload-testflight.sh: uploading via App Store Connect API key…"
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --apiKey "$APP_STORE_CONNECT_API_KEY_ID" \
    --apiIssuer "$APP_STORE_CONNECT_API_ISSUER_ID" \
    --apiKeyPath "$APP_STORE_CONNECT_API_KEY_PATH"
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" ]]; then
  echo "upload-testflight.sh: uploading via Apple ID + app-specific password…"
  xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH" \
    --username "$APPLE_ID" \
    --password "$APPLE_APP_SPECIFIC_PASSWORD"
else
  echo "upload-testflight.sh: no upload credentials found."
  echo "Set App Store Connect API key vars or APPLE_ID + APPLE_APP_SPECIFIC_PASSWORD."
  echo "IPA built successfully — upload manually with Transporter if needed."
  exit 1
fi

echo "upload-testflight.sh: upload complete."
