#!/usr/bin/env bash
#
# Build a release IPA for TestFlight (Vrijdag, iOS).
#
# Usage:
#   bash scripts/ios_build.sh              # build + open Xcode Organizer
#   bash scripts/ios_build.sh --upload     # build + upload via App Store Connect API key
#   bash scripts/ios_build.sh --dry-run    # plan only; no file changes, no build
#   bash scripts/ios_build.sh --help
#
# Secrets (never commit):
#   app/dart_defines.json
#   app/asc_api.json                         (required only for --upload)
#   ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
#
# See docs/IOS_RELEASE.md
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/app"
PUBSPEC="$APP_DIR/pubspec.yaml"
DEFINES_FILE="$APP_DIR/dart_defines.json"
ASC_API_FILE="$APP_DIR/asc_api.json"
ICON_1024="$APP_DIR/ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png"
ENTITLEMENTS="$APP_DIR/ios/Runner/Runner.entitlements"
INFO_PLIST="$APP_DIR/ios/Runner/Info.plist"
BUNDLE_ID="nl.vrijdag.vrijdag"
ASC_APPS_URL="https://appstoreconnect.apple.com/apps"

# ---------------------------------------------------------------------------
# Args
# ---------------------------------------------------------------------------

DO_UPLOAD=false
DRY_RUN=false
SHOW_HELP=false

usage() {
  cat <<'EOF'
Build a release IPA for TestFlight.

Usage:
  bash scripts/ios_build.sh              Build IPA and open Xcode Organizer
  bash scripts/ios_build.sh --upload     Build IPA and upload with altool
  bash scripts/ios_build.sh --dry-run    Print the plan; change nothing
  bash scripts/ios_build.sh --help       Show this help

Prerequisites:
  app/dart_defines.json     copy of app/dart_defines.example.json, filled
  Xcode + signing           Team set on ios/Runner.xcworkspace
  --upload also needs:
    app/asc_api.json
    ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8

Full checklist: docs/IOS_RELEASE.md
EOF
}

for arg in "$@"; do
  case "$arg" in
    --upload) DO_UPLOAD=true ;;
    --dry-run) DRY_RUN=true ;;
    --help|-h) SHOW_HELP=true ;;
    *)
      echo "Unknown argument: $arg" >&2
      echo "Try: bash scripts/ios_build.sh --help" >&2
      exit 1
      ;;
  esac
done

if [[ "$SHOW_HELP" == true ]]; then
  usage
  exit 0
fi

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_DIM=$'\033[2m'
  C_RED=$'\033[31m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
  C_CYAN=$'\033[36m'
else
  C_RESET="" C_BOLD="" C_DIM="" C_RED="" C_GREEN="" C_YELLOW="" C_CYAN=""
fi

LOG_DIR="$REPO_ROOT/logs"
STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_FILE="$LOG_DIR/ios_build_${STAMP}.log"
mkdir -p "$LOG_DIR"

log() {
  printf '%s\n' "$*" | tee -a "$LOG_FILE"
}

section() {
  local n="$1"
  local title="$2"
  log ""
  log "${C_BOLD}${C_CYAN}[$n/6] ${title}${C_RESET}"
  log "${C_DIM}----------------------------------------------------------------${C_RESET}"
}

ok() {
  log "${C_GREEN}  OK${C_RESET}  $*"
}

warn() {
  log "${C_YELLOW}  !!${C_RESET}  $*"
}

fail() {
  log "${C_RED}  ERR${C_RESET} $*"
}

die() {
  fail "$*"
  log ""
  log "Log: $LOG_FILE"
  exit 1
}

run_logged() {
  log "${C_DIM}+ $*${C_RESET}"
  if [[ "$DRY_RUN" == true ]]; then
    log "    (dry-run: skipped)"
    return 0
  fi
  if "$@" >>"$LOG_FILE" 2>&1; then
    return 0
  fi
  return 1
}

# Portable in-place sed (macOS BSD vs GNU).
sed_inplace() {
  local expr="$1"
  local file="$2"
  if sed --version >/dev/null 2>&1; then
    sed -i -E "$expr" "$file"
  else
    sed -i '' -E "$expr" "$file"
  fi
}

# ---------------------------------------------------------------------------
# 1/6 Validation
# ---------------------------------------------------------------------------

section "1" "Validation"

if [[ ! -f "$PUBSPEC" ]]; then
  die "Flutter root not found. Expected pubspec.yaml at $PUBSPEC"
fi
ok "Flutter root: $APP_DIR"

if [[ "$(uname -s)" != "Darwin" ]]; then
  die "iOS IPA builds require macOS with Xcode. This host is $(uname -s)."
fi
ok "Host: macOS"

if ! command -v flutter >/dev/null 2>&1; then
  die "flutter is not on PATH. Install Flutter, then retry."
fi
ok "flutter: $(command -v flutter)"

if ! command -v xcrun >/dev/null 2>&1; then
  die "xcrun is not on PATH. Install Xcode + command-line tools."
fi
ok "xcrun: $(command -v xcrun)"

if ! command -v python3 >/dev/null 2>&1; then
  die "python3 is not on PATH (needed for preflight)."
fi
ok "python3: $(command -v python3)"

if [[ ! -d "$APP_DIR/ios" ]]; then
  die "Missing iOS project at $APP_DIR/ios"
fi
ok "iOS project: $APP_DIR/ios"

log "Log file: $LOG_FILE"
if [[ "$DRY_RUN" == true ]]; then
  warn "Dry-run: no files will be changed, no IPA will be built."
fi

# ---------------------------------------------------------------------------
# 2/6 Preflight
# ---------------------------------------------------------------------------

section "2" "Preflight"

PREFLIGHT_ARGS=(
  --defines "$DEFINES_FILE"
  --example "$APP_DIR/dart_defines.example.json"
  --icon "$ICON_1024"
  --entitlements "$ENTITLEMENTS"
  --info-plist "$INFO_PLIST"
  --bundle-id "$BUNDLE_ID"
  --pubspec "$PUBSPEC"
)

if [[ "$DO_UPLOAD" == true ]]; then
  PREFLIGHT_ARGS+=(--upload --asc-api "$ASC_API_FILE")
fi

set +e
PREFLIGHT_OUT="$(python3 - "$APP_DIR" "${PREFLIGHT_ARGS[@]}" <<'PY'
import json
import os
import re
import struct
import sys

app_dir = sys.argv[1]
args = sys.argv[2:]

def take(flag):
    if flag in args:
        i = args.index(flag)
        if i + 1 >= len(args):
            return None
        return args[i + 1]
    return None

defines_path = take("--defines")
example_path = take("--example")
icon_path = take("--icon")
entitlements_path = take("--entitlements")
info_plist_path = take("--info-plist")
bundle_id = take("--bundle-id")
pubspec_path = take("--pubspec")
asc_api_path = take("--asc-api")
want_upload = "--upload" in args

errors = []
warnings = []

REQUIRED = ("VRIJDAG_ENV", "SUPABASE_URL", "SUPABASE_PUBLISHABLE_KEY")
OPTIONAL = ("SENTRY_DSN", "POSTHOG_API_KEY", "POSTHOG_HOST")
FORBIDDEN = (
    "SUPABASE_SERVICE_ROLE_KEY",
    "GOOGLE_OAUTH_CLIENT_SECRET",
    "WEATHER_API_KEY",
    "APPLE_APP_SPECIFIC_PASSWORD",
    "APP_STORE_CONNECT_API_KEY_PATH",
)
LOCAL_DEMO_ANON = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9."
    "CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
)
PLACEHOLDER_RE = re.compile(r"YOUR_|YOUR_PROJECT|YOUR_KEY|YOUR_REF|example\.com", re.I)


def is_placeholder(value: str) -> bool:
    if not value.strip():
        return True
    if PLACEHOLDER_RE.search(value):
        return True
    if "…" in value or "..." in value:
        return True
    return False


def png_size(path: str):
    with open(path, "rb") as handle:
        header = handle.read(24)
    if header[:8] != b"\x89PNG\r\n\x1a\n":
        return None
    return struct.unpack(">II", header[16:24])


# --- dart_defines.json -------------------------------------------------------
if not defines_path or not os.path.isfile(defines_path):
    errors.append(
        f"Missing {defines_path or 'dart_defines.json'}. "
        f"Copy {example_path or 'dart_defines.example.json'} and fill the staging keys "
        "(client-safe values only: URL + publishable/anon key). "
        "Do not copy service-role keys from .env."
    )
else:
    try:
        with open(defines_path, encoding="utf-8") as handle:
            defines = json.load(handle)
    except json.JSONDecodeError as exc:
        errors.append(f"{defines_path} is not valid JSON: {exc}")
        defines = None
    if not isinstance(defines, dict):
        if defines is not None:
            errors.append(f"{defines_path} must be a JSON object of string values.")
    else:
        for key in FORBIDDEN:
            if key in defines:
                errors.append(
                    f"{defines_path} contains forbidden key {key}. "
                    "Server-only secrets must never be passed as dart-defines."
                )
        for key, value in defines.items():
            if not isinstance(value, str):
                errors.append(f"{key} must be a string, not {type(value).__name__}.")
                continue
            lowered = key.lower()
            if any(part in lowered for part in ("service_role", "client_secret", "password")):
                errors.append(
                    f"{defines_path} contains server-only key {key}. Remove it."
                )

        for key in REQUIRED:
            value = defines.get(key, "")
            if not isinstance(value, str) or is_placeholder(value):
                errors.append(
                    f"{key} is missing or still a placeholder in {defines_path}."
                )

        env = str(defines.get("VRIJDAG_ENV", "")).strip().lower()
        if env and env not in ("staging", "production"):
            errors.append(
                f"VRIJDAG_ENV={env!r} is not allowed for TestFlight. Use staging or production."
            )

        url = str(defines.get("SUPABASE_URL", "")).strip()
        if url and not is_placeholder(url):
            if not url.startswith("https://"):
                errors.append("SUPABASE_URL must be https:// for a TestFlight build.")
            if "127.0.0.1" in url or "localhost" in url:
                errors.append("SUPABASE_URL points at localhost. Use the staging (or production) project.")

        anon = str(defines.get("SUPABASE_PUBLISHABLE_KEY", "")).strip()
        if anon == LOCAL_DEMO_ANON:
            errors.append(
                "SUPABASE_PUBLISHABLE_KEY is the local demo anon key. "
                "Use the staging (or production) publishable key."
            )

        for key in OPTIONAL:
            value = defines.get(key, "")
            if isinstance(value, str) and value.strip() and PLACEHOLDER_RE.search(value):
                errors.append(f"{key} looks like a placeholder. Leave it empty or put a real value.")

# --- assets ------------------------------------------------------------------
if not icon_path or not os.path.isfile(icon_path):
    errors.append(f"Missing App Store icon: {icon_path}")
else:
    try:
        size = png_size(icon_path)
    except OSError as exc:
        errors.append(f"Cannot read icon {icon_path}: {exc}")
        size = None
    if size is None:
        errors.append(f"App Store icon is not a PNG: {icon_path}")
    elif size != (1024, 1024):
        errors.append(
            f"App Store icon is {size[0]}×{size[1]}, need 1024×1024: {icon_path}"
        )

if not entitlements_path or not os.path.isfile(entitlements_path):
    errors.append(f"Missing entitlements: {entitlements_path}")
else:
    with open(entitlements_path, encoding="utf-8") as handle:
        text = handle.read()
    if "com.apple.developer.applesignin" not in text:
        warnings.append(
            "Runner.entitlements does not list Sign in with Apple. "
            "The Apple button will fail on device until the capability is restored."
        )

if not info_plist_path or not os.path.isfile(info_plist_path):
    errors.append(f"Missing Info.plist: {info_plist_path}")
else:
    with open(info_plist_path, encoding="utf-8") as handle:
        plist = handle.read()
    if bundle_id and bundle_id not in plist:
        errors.append(
            f"Info.plist URL scheme should include {bundle_id} "
            "(magic-link redirect {bundle_id}://login-callback/)."
        )

if pubspec_path and os.path.isfile(pubspec_path):
    with open(pubspec_path, encoding="utf-8") as handle:
        pubspec = handle.read()
    match = re.search(r"^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$", pubspec, re.M)
    if not match:
        errors.append(
            f"{pubspec_path} version: must be exactly 'X.Y.Z+N' (semver + integer build)."
        )

# --- upload credentials ------------------------------------------------------
if want_upload:
    if not asc_api_path or not os.path.isfile(asc_api_path):
        errors.append(
            f"Missing {asc_api_path or 'asc_api.json'} (required for --upload). "
            "Copy asc_api.example.json and fill api_key_id + issuer_id."
        )
    else:
        try:
            with open(asc_api_path, encoding="utf-8") as handle:
                asc = json.load(handle)
        except json.JSONDecodeError as exc:
            errors.append(f"{asc_api_path} is not valid JSON: {exc}")
            asc = None
        if isinstance(asc, dict):
            key_id = str(asc.get("api_key_id", "")).strip()
            issuer = str(asc.get("issuer_id", "")).strip()
            if not key_id or PLACEHOLDER_RE.search(key_id):
                errors.append(f"api_key_id is missing or still a placeholder in {asc_api_path}.")
            if not issuer or PLACEHOLDER_RE.search(issuer):
                errors.append(f"issuer_id is missing or still a placeholder in {asc_api_path}.")
            if key_id and not PLACEHOLDER_RE.search(key_id):
                p8 = os.path.expanduser(
                    f"~/.appstoreconnect/private_keys/AuthKey_{key_id}.p8"
                )
                if not os.path.isfile(p8):
                    errors.append(
                        f"App Store Connect API key not found at {p8}. "
                        "Download the .p8 from ASC → Users and Access → Integrations "
                        "and keep the original filename."
                    )

if errors:
    print("PREFLIGHT_FAIL")
    for item in errors:
        print(f"E:{item}")
    for item in warnings:
        print(f"W:{item}")
    sys.exit(1)

print("PREFLIGHT_OK")
for item in warnings:
    print(f"W:{item}")
sys.exit(0)
PY
)"
PREFLIGHT_STATUS=$?
set -e

while IFS= read -r line; do
  [[ -z "$line" ]] && continue
  case "$line" in
    PREFLIGHT_OK|PREFLIGHT_FAIL) ;;
    E:*) fail "${line#E:}" ;;
    W:*) warn "${line#W:}" ;;
    *) log "  $line" ;;
  esac
done <<<"$PREFLIGHT_OUT"

if [[ "$PREFLIGHT_STATUS" -ne 0 ]]; then
  log ""
  die "Preflight failed. Fix the errors above, then retry."
fi
ok "dart_defines.json, App Store icon (1024×1024), entitlements, Info.plist"
if [[ "$DO_UPLOAD" == true ]]; then
  ok "App Store Connect API key files present"
fi

# ---------------------------------------------------------------------------
# 3/6 Build number
# ---------------------------------------------------------------------------

section "3" "Build number"

VERSION_LINE="$(grep -E '^version:' "$PUBSPEC" | head -n 1 | tr -d '\r')"
if [[ ! "$VERSION_LINE" =~ ^version:[[:space:]]*([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)[[:space:]]*$ ]]; then
  die "Could not parse version from pubspec.yaml (need X.Y.Z+N). Saw: $VERSION_LINE"
fi
MARKETING_VERSION="${BASH_REMATCH[1]}"
OLD_BUILD="${BASH_REMATCH[2]}"
NEW_BUILD=$((OLD_BUILD + 1))
OLD_FULL="${MARKETING_VERSION}+${OLD_BUILD}"
NEW_FULL="${MARKETING_VERSION}+${NEW_BUILD}"
ESCAPED_MARKETING="${MARKETING_VERSION//./\\.}"

log "  Current: ${C_BOLD}${OLD_FULL}${C_RESET}"
log "  Next:    ${C_BOLD}${NEW_FULL}${C_RESET}"

if [[ "$DRY_RUN" == true ]]; then
  warn "Dry-run: pubspec.yaml left at ${OLD_FULL}"
  FINAL_VERSION="$OLD_FULL"
else
  sed_inplace "s/^version:[[:space:]]*${ESCAPED_MARKETING}\\+${OLD_BUILD}[[:space:]]*$/version: ${NEW_FULL}/" "$PUBSPEC"
  CONFIRM="$(grep -E '^version:' "$PUBSPEC" | head -n 1 | tr -d '\r')"
  if [[ "$CONFIRM" != "version: ${NEW_FULL}" ]]; then
    die "Failed to bump pubspec.yaml (still: $CONFIRM)"
  fi
  ok "pubspec.yaml → ${NEW_FULL}"
  FINAL_VERSION="$NEW_FULL"
fi

# ---------------------------------------------------------------------------
# 4/6 Clean & deps
# ---------------------------------------------------------------------------

section "4" "Clean and dependencies"

cd "$APP_DIR"

if [[ "$DRY_RUN" == true ]]; then
  warn "Would run: flutter clean && flutter pub get"
  if [[ -f "$APP_DIR/ios/Podfile" ]]; then
    warn "Would run: pod install (ios/)"
  fi
else
  log "  flutter clean…"
  run_logged flutter clean || die "flutter clean failed. See $LOG_FILE"
  ok "flutter clean"

  log "  flutter pub get…"
  run_logged flutter pub get || die "flutter pub get failed. See $LOG_FILE"
  ok "flutter pub get"

  if [[ -f "$APP_DIR/ios/Podfile" ]]; then
    if command -v pod >/dev/null 2>&1; then
      log "  pod install…"
      (
        cd "$APP_DIR/ios"
        run_logged pod install
      ) || die "pod install failed. See $LOG_FILE"
      ok "pod install"
    else
      warn "CocoaPods (pod) is not on PATH. flutter build ipa will run it if it can."
    fi
  fi
fi

# ---------------------------------------------------------------------------
# 5/6 Build IPA
# ---------------------------------------------------------------------------

section "5" "Build IPA"

IPA_DIR="$APP_DIR/build/ios/ipa"
ARCHIVE_PATH="$APP_DIR/build/ios/archive/Runner.xcarchive"
BUILD_ARGS=(build ipa --release "--dart-define-from-file=$DEFINES_FILE")

log "  Command: flutter ${BUILD_ARGS[*]}"

if [[ "$DRY_RUN" == true ]]; then
  warn "Would build the IPA (skipped)."
  IPA_PATH="$IPA_DIR/vrijdag.ipa"
else
  log "  This takes several minutes…"
  if ! flutter "${BUILD_ARGS[@]}" 2>&1 | tee -a "$LOG_FILE"; then
    die "flutter build ipa failed. See $LOG_FILE"
  fi
  ok "flutter build ipa"

  IPA_PATH="$(find "$IPA_DIR" -name '*.ipa' 2>/dev/null | head -n 1 || true)"
  if [[ -z "$IPA_PATH" ]]; then
    die "IPA not found under $IPA_DIR"
  fi
  ok "IPA: $IPA_PATH"
  if [[ -d "$ARCHIVE_PATH" ]]; then
    ok "Archive: $ARCHIVE_PATH"
  else
    warn "Archive not at $ARCHIVE_PATH (IPA is still usable in Transporter)."
  fi
fi

# ---------------------------------------------------------------------------
# 6/6 Upload or Organizer
# ---------------------------------------------------------------------------

section "6" "Distribute"

if [[ "$DRY_RUN" == true ]]; then
  if [[ "$DO_UPLOAD" == true ]]; then
    warn "Would upload with: xcrun altool --upload-app --type ios --file <ipa> --apiKey … --apiIssuer …"
  else
    warn "Would open the archive in Xcode Organizer."
  fi
else
  if [[ "$DO_UPLOAD" == true ]]; then
    API_KEY_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1],encoding="utf-8"))["api_key_id"].strip())' "$ASC_API_FILE")"
    ISSUER_ID="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1],encoding="utf-8"))["issuer_id"].strip())' "$ASC_API_FILE")"
    P8_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8"
    log "  Uploading via App Store Connect API key ${API_KEY_ID}…"
    if xcrun altool --upload-app \
      --type ios \
      --file "$IPA_PATH" \
      --apiKey "$API_KEY_ID" \
      --apiIssuer "$ISSUER_ID" >>"$LOG_FILE" 2>&1; then
      ok "Upload accepted by App Store Connect"
    else
      fail "altool upload failed. See $LOG_FILE"
      log ""
      log "Fallback: open Transporter (or Xcode → Open Developer Tool → Transporter)"
      log "and drop this IPA onto it:"
      log "  $IPA_PATH"
      log "Key file expected at: $P8_PATH"
      exit 1
    fi
  else
    if [[ -d "$ARCHIVE_PATH" ]]; then
      log "  Opening archive in Xcode Organizer…"
      open "$ARCHIVE_PATH" || warn "Could not open $ARCHIVE_PATH automatically."
    fi
    log ""
    log "${C_BOLD}Upload from Organizer${C_RESET}"
    log "  1. Window → Organizer (if it did not open)."
    log "  2. Select this archive → Distribute App."
    log "  3. App Store Connect → Upload → next through the defaults."
    log "  4. Wait for processing at ${ASC_APPS_URL}"
    log ""
    log "${C_BOLD}Or Transporter${C_RESET}"
    log "  Open Transporter and drop:"
    log "  $IPA_PATH"
  fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------

log ""
log "${C_BOLD}${C_GREEN}Done.${C_RESET} IPA ready for TestFlight."
log "  App:      Vrijdag"
log "  Bundle:   ${BUNDLE_ID}"
log "  Version:  ${FINAL_VERSION}"
log "  IPA:      ${IPA_PATH}"
if [[ -d "$ARCHIVE_PATH" || "$DRY_RUN" == true ]]; then
  log "  Archive:  ${ARCHIVE_PATH}"
fi
log "  Defines:  ${DEFINES_FILE}"
log "  Log:      ${LOG_FILE}"
log "  ASC:      ${ASC_APPS_URL}"
log ""
if [[ "$DRY_RUN" == true ]]; then
  log "Dry-run complete. Re-run without --dry-run to bump ${OLD_FULL} → ${NEW_FULL} and build."
elif [[ "$DO_UPLOAD" == true ]]; then
  log "Next: App Store Connect → TestFlight → wait for Processing → Ready to Test."
  log "Internal Testing does not need screenshots. Add your Apple ID to the internal group."
else
  log "Next: finish the Organizer/Transporter upload, then TestFlight → Internal Testing."
fi
log "Checklist: docs/IOS_RELEASE.md"
