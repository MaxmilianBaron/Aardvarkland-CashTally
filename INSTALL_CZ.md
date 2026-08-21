# Výčetka — rychlé předání projektu

## Co dostáváte

Zdrojový Flutter MVP 0.4.0+19 pro Android a iOS, ruční počítání 32 měn,
oblíbené měny a profesionální uzávěrku s podpisy, PDF/CSV a finálním textem s
hlavičkou. OCR, kamera a QR nejsou součástí této verze. Free má všechny funkce a reklamy; jednorázové Ad-free navždy má
stejné funkce bez reklam. Android a iOS se vydávají ze stejného zdrojového
kódu.

## První spuštění

Na počítači s Flutter 3.44 stable:

```bash
flutter pub get
python3 scripts/apply_native_patches.py
flutter run
```

Interní Ad-free QA bez nákupu:

```bash
flutter run --dart-define=FORCE_AD_FREE=true
```

`FORCE_AD_FREE=true` nikdy nepoužívejte ve veřejném store buildu.

## Co vytvořit v obchodech

V App Store Connect a Google Play Console založte jednorázový non-consumable
nákup se shodným ID a výchozí evropskou cenou 4,99 EUR:

```text
vycetka_full_unlock
```

Veřejně se distribuuje jedna aplikace. Free má bez limitu historii, podpisy i
export. Jednorázový nákup pouze odstraní reklamy. Vyřazený
`vycetka_ad_free_monthly` se už nenabízí a slouží jen jako migrační ID pro
případný dřívější nárok.

## Povinné před produkčním vydáním

1. Nastavit vlastní bundle/application ID, podpisy a store účty.
2. Spustit `flutter analyze`, `flutter test` a oba fyzické buildy.
3. Otestovat každý nominál na reálných bankovkách a několika telefonech.
4. Nastavit vlastní AdMob ID, reklamní jednotky, UMP a ověřit Free bez souhlasu
   i s povoleným reklamním požadavkem.
5. Otestovat nákup, pending, zrušení, refundaci, reinstalaci a obnovu v
   Sandbox/TestFlight/Internal testing.
6. Doplnit screenshoty, kontakty, veřejnou privacy policy a podmínky.

Vlastní receipt server není pro potvrzený jednorázový model vyžadován.

Podrobnosti jsou v `README.md`, `docs/QA_REPORT.md` a `docs/STORE_RELEASE.md`.
