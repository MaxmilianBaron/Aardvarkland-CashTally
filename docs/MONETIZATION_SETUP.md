# Monetizace — Free + jednorázové Bez reklam navždy

## První veřejné vydání 0.4.1

- všechny funkce jsou zdarma,
- reklamy se neinicializují ani nevyžadují,
- nákupní obrazovka, obnova nákupu a licenční nabídka nejsou dostupné,
- tento režim je výchozí `ENABLE_MONETIZATION=false`.

Budoucí podepsaný update může zapnout níže připravený model pomocí
`ENABLE_MONETIZATION=true` a `ENABLE_ADS=true`. Package ID, podpis a lokální
data se nemění. Před zapnutím musí být hotové vlastní AdMob ID, UMP, aktivní
produkt obchodu, právní texty a živé testy.

## Připravený budoucí model

- **Free:** všechny funkce, reklamní banner pouze na dashboardu, historii a v
  nastavení.
- **Bez reklam navždy:** stejné funkce, žádné reklamní požadavky, jeden
  neobnovovaný nákup.
- výchozí evropská cena: **4,99 EUR jednorázově**,
- aplikace zobrazuje pouze lokalizovanou cenu vrácenou obchodem,
- jedna aplikace a jedno package/bundle ID na platformu.

## Produkt v obchodech

Aktivní product ID na Google Play i App Storu:

```text
vycetka_full_unlock
```

- Google Play: **one-time product**, non-consumable; nákup se nikdy
  nekonzumuje.
- App Store Connect: **Non-Consumable In-App Purchase**.
- referenční název: `Výčetka — bez reklam navždy`,
- český zobrazovaný název: `Bez reklam navždy`,
- anglický zobrazovaný název: `Ad-free forever`.

Vyřazený Alpha produkt `vycetka_ad_free_monthly` se novým uživatelům
nenabízí. Pokud jej obchod někdy vrátí jako platný dřívější nárok, aplikace ho
jednorázově povýší na trvalé Ad-free, aby nikdo nepřišel o zaplacený přístup.

## Proč není potřeba vlastní server

Nákup hlásí oficiální Google Play Billing nebo Apple StoreKit přes Flutter
plugin `in_app_purchase`. Aplikace přijme pouze stav `purchased` nebo
`restored` a známé product ID, uloží trvalý nárok do bezpečného úložiště a
dokončí transakci v obchodě. Tlačítko **Obnovit nákup** znovu načte vlastněný
non-consumable produkt ze stejného store účtu.

Tato varianta nepoužívá projektový receipt endpoint a neposílá na server
výčetky, podpisy ani profil pokladny. Aplikace nemá kameru ani OCR.

Klientské ověření je vědomý kompromis: je slabší proti upravenému APK a změna
pozdější refundace nebo revokace se může projevit až při další komunikaci s
obchodem. Protože nákup pouze odstraňuje reklamy a žádná pracovní funkce ani
data nejsou uzamčené, je dopad omezený.

## Google Play Console

1. Nahrajte veřejnou binárku do Internal testing. Musí mít package
   `cz.vycetka.vycetka` a produkční podpisový řetězec.
2. V Monetize > Products > In-app products založte aktivní one-time product
   `vycetka_full_unlock`.
3. Nastavte referenční cenu na nejbližší dostupný bod k 4,99 EUR a zkontrolujte
   automaticky navržené místní ceny.
4. Přidejte licenční testery a ověřte úspěch, pending platbu, zrušení,
   reinstalaci, obnovu a refundaci.
5. Ověřte, že nákup je potvrzen do tří dnů; `completePurchase` v aplikaci
   provede klientské acknowledgement.

## App Store Connect

1. U stejného bundle ID založte Non-Consumable In-App Purchase
   `vycetka_full_unlock`.
2. Doplňte lokalizované názvy/popisy, cenu odpovídající 4,99 EUR a povinné
   podklady pro App Review.
3. Na Macu sestavte Free veřejnou binárku bez `FORCE_AD_FREE`.
4. V Sandbox/TestFlight ověřte nákup, Ask to Buy/deferred, obnovu na novém
   zařízení a refundaci/revokaci.

## Produkční konfigurace reklam

```text
VYCETKA_ADMOB_ANDROID_APP_ID=ca-app-pub-...~...
VYCETKA_ADMOB_IOS_APP_ID=ca-app-pub-...~...
ADMOB_ANDROID_BANNER_ID=ca-app-pub-.../...
ADMOB_IOS_BANNER_ID=ca-app-pub-.../...
PRIVACY_POLICY_URL=https://...
TERMS_URL=https://...
```

`PURCHASE_VERIFICATION_URL` už neexistuje. `scripts/build_release.sh` nejprve
spustí `scripts/verify_monetization_config.py`; veřejný build zablokuje při
testovacích AdMob ID, chybějících právních URL nebo aktivním QA override.

## Povinná testovací matice

1. Free bez souhlasu s personalizací: všechny funkce fungují, reklama se řídí
   UMP.
2. Úspěšný jednorázový nákup: Ad-free se aktivuje a aktuální banner zmizí.
3. Pending/deferred: Ad-free se neodemkne před stavem `purchased`.
4. Restart offline: již potvrzený trvalý nárok zůstane.
5. Reinstalace/nové zařízení: ruční **Obnovit nákup** vrátí Ad-free.
6. Refundace/revokace: zaznamenat skutečné chování obou obchodů bez backendu.
7. Ad-free nesmí inicializovat ani žádat reklamu.
8. Android i iOS: Free a Ad-free mají stejné počítání, historii, podpisy a
   PDF/CSV.

## Co stále blokuje budoucí zapnutí monetizace

- skutečné AdMob App ID/ad unit ID a publikovaná UMP zpráva,
- aktivní non-consumable produkt v obou obchodech,
- veřejné zásady soukromí a podmínky,
- Google Play Internal testing a Apple Sandbox/TestFlight nákupní matice,
- macOS/Xcode build, podpis a fyzický iPhone test.

Oficiální podklady:

- <https://developer.android.com/google/play/billing/integrate>
- <https://developer.apple.com/in-app-purchase/>
- <https://developer.apple.com/documentation/storekit/transaction/currententitlements>
- <https://developers.google.com/admob/flutter/privacy>
