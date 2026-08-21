# Contributing

Thank you for helping improve Aardvarkland CashTally.

## Development setup

1. Fork and clone the repository.
2. Install Flutter 3.44+ with Dart 3.12+.
3. Run `flutter pub get` and `flutter run`.

Before submitting a pull request, run `python scripts/verify_source.py`, `python scripts/test_native_patcher.py`, `flutter analyze`, and `flutter test`. Preserve integer minor-unit money calculations and add migrations for persisted schema changes.

Do not include signing material, credentials, store keys, real till records, signatures, business identities, backups, or personal data. Use fictional sample data. State separately what was source-tested, built, and verified on physical Android or iOS hardware.
