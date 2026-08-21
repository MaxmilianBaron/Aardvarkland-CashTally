# App Store a Google Play release

## Identita aplikace

Před prvním store buildem změňte výchozí ID `cz.vycetka.vycetka` na finální identifikátor, který vlastníte. Po publikaci už se ID nemění.

## Apple

1. V Apple Developer vytvořte App ID.
2. V App Store Connect založte Non-Consumable In-App Purchase
   `vycetka_full_unlock` s výchozí cenou 4,99 EUR.
3. Vyřazený `vycetka_ad_free_monthly` už nenabízejte; aplikace ho zná pouze
   jako migrační ID.
4. V Xcode nastavte Team, signing a vlastní iOS AdMob App ID.
5. Přidejte privacy policy, podmínky, App Privacy odpovědi a
   screenshoty. UMP consent message musí odpovídat skutečnému použití reklam.
6. Vytvořte Sandbox testery a otestujte nákup, Ask to Buy/deferred, obnovu,
   reinstalaci, refundaci a revokaci.
7. Sestavte `flutter build ipa --release` nebo archivujte v Xcode.
8. Nejprve použijte TestFlight, potom phased release.

Jednorázový nákup odstraňuje pouze reklamy; všechny funkce zůstávají zdarma. Cena v
UI musí vždy pocházet ze StoreKit, nikoli z pevně zapsaného přepočtu.

## Google Play

První veřejná verze 0.4.1 se vydává zdarma se všemi funkcemi, bez reklam a bez
nákupní nabídky (`ENABLE_MONETIZATION=false`). Produkt a AdMob nejsou pro toto
první vydání aktivní. Níže uvedené monetizační kroky jsou povinné až před
budoucím zapnutím reklam a nákupu; právní URL, Data Safety a store podklady jsou
povinné už pro první vydání.

1. Založte aplikaci se stejným application ID jako release build.
2. Nastavte výchozí store listing na `en-US` a nahrajte lokalizované názvy z
   `fastlane/metadata/android/`; postup a fallbacky jsou v
   `docs/STORE_TITLES_ALL_LANGUAGES.md`.
3. Založte one-time non-consumable product `vycetka_full_unlock` s výchozí
   cenou 4,99 EUR; zkontrolujte automatické místní ceny.
4. Nakonfigurujte vlastní Android AdMob App ID/banner ID, UMP consent message,
   Data Safety a veřejné právní URL.
5. Vytvořte upload key a bezpečně ho uložte mimo repozitář. Produkční signing
   key zůstává mimo repozitář a musí mít šifrovanou off-device zálohu.
6. Sestavte jediný veřejný `flutter build appbundle --release` bez
   `FORCE_AD_FREE` nebo `FORCE_FULL`.
7. Nahrajte do Internal testing a otestujte přes licencovaný testovací účet.
8. Poté použijte Closed/Open testing a staged production rollout.

## Verze

V `pubspec.yaml`:

```yaml
version: 1.2.0+42
```

- `1.2.0` je marketingová verze,
- `42` je rostoucí build number / version code.

Každé nahrání do obchodů musí mít vyšší build number.

## CI/CD

`.github/workflows/ci.yml` analyzuje a testuje projekt na každý push. Produkční podepisování nepřidávejte do veřejného repozitáře. Použijte GitHub Environments, šifrované secrets a oddělený release workflow.

## Povinné před produkcí

- aktivní non-consumable produkt a úplné sandboxové testy nákupu/obnovy,
- vlastní AdMob App ID/ad unit ID a UMP consent message,
- veřejné zásady ochrany osobních údajů a podmínky,
- proces žádosti o smazání cloudového účtu, pokud cloud později přibude,
- accessibility audit,
- crash reporting bez sběru obsahu výčetek a podpisů,
- zálohování klíčů a recovery postup.

Před uploadem musí projít `py scripts/verify_monetization_config.py`. Podrobná
konfigurace a sandbox matice jsou v `docs/MONETIZATION_SETUP.md`.
