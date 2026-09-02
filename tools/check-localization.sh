#!/usr/bin/env bash
#
# Localization completeness check.
#
# Two things must fail CI:
#   1. a localization key present in one language and missing in the other
#   2. a hardcoded user-visible string in Flutter code
#
# Implemented as part of F-090 (docs/backlog/features/F-090-localization-foundation.md).
# Until then this script fails loudly rather than passing silently — a check that quietly
# does nothing is worse than no check, because everyone believes it is running.

set -euo pipefail

echo "check-localization.sh is not implemented yet."
echo "It is part of F-090 — localization foundation."
echo "See docs/backlog/features/F-090-localization-foundation.md"
exit 1
