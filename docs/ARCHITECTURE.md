# Architektura (historická poznámka)

> Aktuální architektura je popsána v [`V0.4_RELEASE_NOTES.md`](V0.4_RELEASE_NOTES.md).
> Tento soubor zachovává rozhodnutí z 0.3.x; OCR, kamera, nativní ML mosty a QR
> byly v 0.4.0 odstraněny a starší odstavce níže nejsou runtime kontrakt.

Aktuální runtime tok je Flutter UI → `AppController` → lokální `LocalStore` a
`ClosingReportService`. Peníze se ukládají v celých minor units, hmotnost jen
pro doložené nominály, nákup je klientský non-consumable a reporty obsahují
SHA-256 bez QR. Nativní obaly slouží jen ke spuštění platformy a systémovému
zámku; nemají kamerový, OCR ani ML kanál. Aktivní schéma relací je v5 a migrace
z v1–v4 vytváří `.pre-v5-backup`.

## Volba technologie

Flutter drží UI, měnový katalog, výpočty, historii, uzávěrky, POS import i licenci v jednom Dart kódu. Nativní kód je omezený na OCR mosty a systémové ověření zařízení:

```text
Flutter camera → dočasný JPEG → MethodChannel cz.vycetka/ocr
  Android → Google ML Kit Latin text recognizer
  iOS     → Apple Vision VNRecognizeTextRequest
→ text → BanknoteClassifier → kandidáti → potvrzení uživatele

Uzávěrka se při uložení kanonicky serializuje a získá SHA-256 důkazní hash.
PDF obsahuje QR payload s číslem dokladu a hashem; CSV i finální text obsahují
stejný hash. QR není vzdálené ověření pravosti, ale umožňuje porovnat export s
lokálně uloženými daty.
```

Tím se vyhýbáme komunitní OCR závislosti, která může mít jinou minimální verzi iOS než Flutter/camera. Apple Vision je součást systému a Android používá bundlovaný model, takže samotné rozpoznání funguje bez připojení.

## Datový model

Peníze jsou vždy uloženy jako celé minor units:

- 1 Kč = 100,
- 1 EUR = 100,
- 5 centů = 5.

Tím nevznikají chyby s desetinnými čísly. Denominace má ID složené z typu a hodnoty (`banknote_100`, `coin_100`), protože například USD může mít bankovku i minci stejné hodnoty.

Historie se zapisuje jako JSON do aplikačního Documents adresáře. Zápis je atomický: nejprve do dočasného souboru a až poté přejmenování. Při poškození se vytvoří záloha `.corrupt-*`.

`PosReconciliation` ukládá pouze strukturovaný POS/EFTPOS souhrn, měnu,
částky v minor units, název zdrojového souboru a jeho SHA-256. CSV se parsuje
lokálně; import vyžaduje explicitní očekávanou hotovost a nikdy nezamění hrubé
tržby nebo platby kartou za stav hotovosti.

## OCR klasifikace

OCR engine vrací text, nikoli bezpečné rozhodnutí o nominálu. `BanknoteClassifier` proto kombinuje:

1. marker měny (`BANK OF CANADA`, `CESKA NARODNI BANKA`, ...),
2. samostatně vytištěný číselný nominál,
3. slovní nominál (`TWENTY DOLLARS`, `DVA TISICE`, ...),
4. opakovaný výskyt nominálu.

Sériové číslo se nesmí zaměnit za nominál: číselný výraz musí být oddělený od dalších číslic. I výsledek s vysokým skóre vyžaduje lidské potvrzení.

## Plány, reklamy a nákup

Jedna veřejná aplikace má dva plány se stejnými funkcemi. `Free` umožňuje bez
limitu OCR, historii, podpisy i PDF/CSV a může zobrazit banner na dashboardu,
historii a v nastavení. `Ad-free` reklamní službu při startu vůbec
neinicializuje. Reklama se nikdy nevkládá do počítání, kamery/OCR, podpisu,
detailu uzávěrky ani exportu.

`EntitlementService` drží trvalý příznak nároku v secure storage.
`PurchaseService` používá Flutter `in_app_purchase` a jednorázový
non-consumable produkt `vycetka_full_unlock`. Vyřazený
`vycetka_ad_free_monthly` se nenabízí; případný dřívější platný nárok se při
obnově povýší na lifetime, aby kupující nic neztratil.

`AdService` před každým požadavkem na reklamu obnoví Google UMP stav a reklamu
načte jen tehdy, když SDK potvrdí `canRequestAds`. Produkční build vyžaduje
vlastní AdMob ID a veřejné právní URL. Nákup používá klientské store ověření
bez vlastního receipt serveru; je proto méně odolný proti upravené aplikaci a
zpožděným refundacím než serverová varianta.

## Aktualizace a migrace

Aplikace používá běžné verzované aktualizace App Store a Google Play. Aktivní
schéma relací je v5. Volitelná pole `posReport`, `closingHash` a
`closingTitle` byla přidána explicitní migrací z v1–v4; zdrojový soubor se
před převodem zachová jako `.pre-v5-backup`. Stejné package/bundle ID a podpis zachovávají data i
entitlement při aktualizaci.

Zámek aplikace (`AppLockGate`) používá Android/iOS systémovou biometrii nebo
PIN/heslo zařízení přes `local_auth`; vlastní PIN aplikace se nikde neukládá.
Po zapnutí se ověří ihned, při dalším spuštění a návratu z pozadí se znovu
vyžádá ověření.
