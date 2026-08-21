#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK nebyl nalezen." >&2
  exit 1
fi

if [[ ! -d android || ! -d ios ]]; then
  bash scripts/bootstrap.sh --no-check
else
  flutter pub get
fi

python3 scripts/verify_monetization_config.py
python3 scripts/apply_native_patches.py
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test

DART_DEFINES=(
  "--dart-define=ENABLE_MONETIZATION=${ENABLE_MONETIZATION:-false}"
  "--dart-define=ENABLE_ADS=${ENABLE_ADS:-false}"
  "--dart-define=ADMOB_ANDROID_BANNER_ID=${ADMOB_ANDROID_BANNER_ID:-}"
  "--dart-define=ADMOB_IOS_BANNER_ID=${ADMOB_IOS_BANNER_ID:-}"
  "--dart-define=PRIVACY_POLICY_URL=${PRIVACY_POLICY_URL}"
  "--dart-define=TERMS_URL=${TERMS_URL}"
)

flutter build appbundle --release "${DART_DEFINES[@]}"

if [[ "$(uname -s)" == "Darwin" ]]; then
  flutter build ipa --release "${DART_DEFINES[@]}"
else
  echo "iOS IPA lze sestavit pouze na macOS s Xcode; Android AAB je hotový."
fi

printf '\nRelease výstupy:\n'
printf '  Android: build/app/outputs/bundle/release/app-release.aab\n'
printf '  iOS:     build/ios/ipa/ (jen macOS)\n'
