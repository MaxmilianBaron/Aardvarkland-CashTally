# Výčetka Apple Free QA 0.4.0+19 (zdrojový handoff)

- Bundle ID: `cz.vycetka.vycetka`
- Minimální iOS: 13.0
- Distribuční podsložka `Trial` nyní znamená Free QA
- Varianta: všechny funkce, testovací reklamy, možnost jednorázového Ad-free

Na macOS s Flutter 3.44.7 a aktuálním Xcode spusťte v kořeni balíčku:

```sh
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build ipa --release
```

Před distribucí zkontrolujte Apple Team, provisioning profile, bundle ID,
verzi 0.4.0, build 19 a podpis. Výchozí AdMob ID jsou testovací, takže tuto
binárku nezveřejňujte. Veřejný build potřebuje vlastní AdMob ID, UMP, StoreKit
non-consumable `vycetka_full_unlock` a právní URL podle
`MONETIZATION_SETUP.md`. Windows tento build ani podpis neověřilo.
