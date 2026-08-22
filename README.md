# Aardvarkland CashTally

Offline cash-counting app for Android and iOS. Count by denomination, compare expected cash and export closing reports.

[Live Preview](https://maxmilianbaron.github.io/Aardvarkland-CashTally/) · [Releases](https://github.com/MaxmilianBaron/Aardvarkland-CashTally/releases)

The preview uses sample data in the browser. Native file sharing, printing, app locking and platform storage are represented by browser alternatives.

## What it does

- quick counts and full till closings
- 32 currencies and 36 interface languages
- denomination multipliers, custom denominations and till templates
- expected cash, variance, deposit and retained cash
- POS/EFTPOS CSV import and reconciliation
- local history with search and filters
- PDF, CSV and text reports with signatures and SHA-256 fingerprints
- encrypted backup and optional device app lock
- no ads, subscriptions or purchases in the default public build

## Run it

Requires Flutter 3.44+ with Dart 3.12+.

```bash
git clone https://github.com/MaxmilianBaron/Aardvarkland-CashTally.git
cd Aardvarkland-CashTally
flutter pub get
flutter run
```

## Checks

```bash
python scripts/verify_source.py
python scripts/test_native_patcher.py
flutter analyze
flutter test
```

## Builds

```bash
flutter build apk --debug
flutter build appbundle --release
flutter build ios --release --no-codesign
```

Sign release builds with your own Android keystore or Apple signing certificate; signing files are not included. Store transactions, biometrics, file pickers and printing need platform or device testing.

## Data

Amounts are stored as integer minor units. Reports, history and encrypted backups are created locally; the app does not require a server. Do not attach real till exports, signatures or business records to public issues.

- Security reports: [SECURITY.md](SECURITY.md)
- Contributing: [CONTRIBUTING.md](CONTRIBUTING.md)

## License

[MIT](LICENSE)
