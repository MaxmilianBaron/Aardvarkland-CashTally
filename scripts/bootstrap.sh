#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK nebyl nalezen. Nainstalujte aktuální stable Flutter a spusťte skript znovu." >&2
  exit 1
fi
if ! command -v python3 >/dev/null 2>&1; then
  echo "Python 3 je potřeba pro bezpečnou úpravu platformních souborů." >&2
  exit 1
fi

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

flutter create \
  --platforms=android,ios \
  --org cz.vycetka \
  --project-name vycetka \
  "$TEMP_DIR/vycetka"

rm -rf android ios
cp -R "$TEMP_DIR/vycetka/android" ./android
cp -R "$TEMP_DIR/vycetka/ios" ./ios

python3 scripts/apply_native_patches.py
flutter pub get
dart format lib test

if [[ "${1:-}" != "--no-check" ]]; then
  flutter analyze
  flutter test
fi

echo
printf 'Hotovo. Spuštění: flutter run\n'
printf 'QA Ad-free build: flutter run --dart-define=FORCE_AD_FREE=true\n'
