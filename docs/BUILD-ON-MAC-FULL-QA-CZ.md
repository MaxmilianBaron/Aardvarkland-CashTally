# Výčetka Apple Ad-free QA 0.4.0+19 (zdrojový handoff)

- Bundle ID: `cz.vycetka.vycetka`
- Minimální iOS: 13.0
- Distribuční podsložka `Full` nyní znamená Ad-free QA
- Varianta: pouze interní QA (`FORCE_AD_FREE=true`)

Na macOS s Flutter 3.44.7 a aktuálním Xcode spusťte v kořeni balíčku:

```sh
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build ipa --release --dart-define=FORCE_AD_FREE=true
```

Tuto binárku nezveřejňujte v App Store. Veřejná aplikace musí být sestavena
bez `FORCE_AD_FREE`; reklamy odstraňuje jednorázový non-consumable
`vycetka_full_unlock`.
Před interní instalací zkontrolujte Apple Team, provisioning profile,
bundle ID, verzi 0.4.0, build 19 a podpis. Windows tento build ani podpis
neověřilo.
