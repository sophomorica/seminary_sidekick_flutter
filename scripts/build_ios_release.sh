#!/usr/bin/env bash
# Release iOS build for Seminary Sidekick.
#
# ALWAYS use this script for App Store builds — never run `flutter build ipa`
# by hand. Build 3 (1.0.0+3) shipped without --dart-define=REVENUECAT_IOS_KEY,
# which made every Subscribe tap fail and got the app rejected under
# Guideline 2.1(b) on 2026-07-10. This script hard-fails if required keys
# are missing so that can't happen again.
#
# Usage:  ./scripts/build_ios_release.sh
# Reads secrets from the gitignored .env at the repo root.

set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo "❌ .env not found at repo root. It must define REVENUECAT_IOS_KEY,"
  echo "   SUPABASE_URL, SUPABASE_ANON_KEY (and ideally SENTRY_DSN)."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

missing=()
for var in REVENUECAT_IOS_KEY SUPABASE_URL SUPABASE_ANON_KEY; do
  if [ -z "${!var:-}" ]; then
    missing+=("$var")
  fi
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "❌ Missing required variable(s) in .env: ${missing[*]}"
  echo "   Refusing to build — a release without these ships broken purchases"
  echo "   and/or Group Play. See REVENUECAT_SETUP.md and SUPABASE_SETUP.md."
  exit 1
fi

if [ -z "${SENTRY_DSN:-}" ]; then
  echo "⚠️  SENTRY_DSN not set — release will ship WITHOUT crash reporting."
  read -r -p "   Continue anyway? [y/N] " answer
  [[ "$answer" =~ ^[Yy]$ ]] || exit 1
fi

VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
echo "▶ Building seminary_sidekick $VERSION (ipa, release)…"

flutter build ipa \
  --dart-define=REVENUECAT_IOS_KEY="$REVENUECAT_IOS_KEY" \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_ANON_KEY="$SUPABASE_ANON_KEY" \
  ${SENTRY_DSN:+--dart-define=SENTRY_DSN="$SENTRY_DSN"} \
  --dart-define=APP_RELEASE="seminary_sidekick@$VERSION"

echo "✅ Done: build/ios/ipa — seminary_sidekick $VERSION with all dart-defines."
