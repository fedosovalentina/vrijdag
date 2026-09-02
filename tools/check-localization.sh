#!/usr/bin/env bash
#
# Localization CI checks (F-090, DEC-023).
#
# 1. ARB key parity — every locale file has the same keys as the template ARB.
# 2. Hardcoded UI strings — enforced by hardcoded_strings_lint via `dart analyze`
#    in the Flutter CI job (not flutter analyze — plugins do not run there).
#
# See docs/backlog/features/F-090-localization-foundation.md

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
L10N_DIR="$ROOT/app/lib/l10n"
TEMPLATE_ARB="$L10N_DIR/app_nl.arb"

if [[ ! -f "$ROOT/app/pubspec.yaml" ]]; then
  echo "check-localization.sh: no Flutter app yet — nothing to check."
  exit 0
fi

if [[ ! -f "$TEMPLATE_ARB" ]]; then
  echo "check-localization.sh: missing template ARB at $TEMPLATE_ARB"
  exit 1
fi

extract_keys() {
  python3 - "$1" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, encoding="utf-8") as handle:
    data = json.load(handle)

for key in sorted(k for k in data if not k.startswith("@")):
    print(key)
PY
}

template_keys="$(mktemp)"
trap 'rm -f "$template_keys"' EXIT
extract_keys "$TEMPLATE_ARB" >"$template_keys"

shopt -s nullglob
arb_files=("$L10N_DIR"/app_*.arb)
shopt -u nullglob

if ((${#arb_files[@]} < 2)); then
  echo "check-localization.sh: expected at least two locale ARB files in $L10N_DIR"
  exit 1
fi

failed=0
for arb in "${arb_files[@]}"; do
  locale_keys="$(mktemp)"
  extract_keys "$arb" >"$locale_keys"

  missing="$(comm -23 "$template_keys" "$locale_keys" || true)"
  extra="$(comm -13 "$template_keys" "$locale_keys" || true)"
  rm -f "$locale_keys"

  if [[ -n "$missing" || -n "$extra" ]]; then
    echo "ARB key mismatch in $(basename "$arb"):"
    if [[ -n "$missing" ]]; then
      echo "  missing keys (present in app_nl.arb only):"
      sed 's/^/    /' <<<"$missing"
    fi
    if [[ -n "$extra" ]]; then
      echo "  extra keys (not in app_nl.arb):"
      sed 's/^/    /' <<<"$extra"
    fi
    failed=1
  fi
done

if ((failed)); then
  exit 1
fi

echo "check-localization.sh: ARB key parity OK (${#arb_files[@]} locales)."
