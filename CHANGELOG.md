# Changelog

## 0.4.0+19 — licence, jednodušší počítání a nové uzávěrky

- Free a Ad-free mají stejné funkce; `vycetka_full_unlock` je trvalý
  jednorázový nákup. Obnova se jednou zkusí při startu a ručně zůstává v
  Nastavení. Velká plánová lišta byla nahrazena odznakem Free/Full.
- Výchozí jazyk, výchozí měna a pořadí oblíbených měn se ukládají nezávisle;
  první výběr země nastaví obě hodnoty.
- OCR, kamera, nativní ML kanály a QR byly odstraněny z produkčního běhu.
  Staré `ocrScans` se pouze ignorují při načtení starších dat.
- Schéma relací je v5 s migrací a zálohou; přibyl vlastní nadpis uzávěrky,
  jednotný Rozdíl, červené záporné hodnoty, identita pod poznámkami a souhrny
  Celkem/Součet částek v PDF, CSV i prostém textu.
- Opraveny kroky 1×/10×/50×/100×, nulové minimum, zarovnání počtu a mezisoučtu,
  větná kapitalizace a celoobrazovkový zvětšený náhled PDF.

## 0.3.0+18 — důkazní uzávěrka, POS import a zámek aplikace

- Uzávěrka se při uložení kanonicky otiskne SHA-256 hashem; PDF obsahuje QR
  payload s dokladem a hashem, CSV i finální text obsahují stejný důkaz.
- Přidán lokální import POS/EFTPOS CSV. Import vyžaduje měnu a očekávanou
  hotovost, zachová SHA-256 zdrojového souboru a páruje report s uzávěrkou.
- Přidán volitelný zámek aplikace přes systémový PIN/heslo nebo biometriku;
  vlastní PIN se neukládá. Android používá `FlutterFragmentActivity` a iOS
  Face ID usage popis.
- Datové schéma relací se explicitně migruje na v4 s `.pre-v4-backup`.
- Aktualizováno na 516 automatických testů; Android versionCode 18 byl ověřen
  přes `adb install -r` bez změny `firstInstallTime`.

## 0.2.0+17 — rychlé počítání a provozní nastavení

- Přidán samostatný rychlý režim a profesionální uzávěrka; uložená historie
  eviduje, kterým režimem záznam vznikl.
- Zadávání nominálů zrychlují násobiče ×1, ×10, ×50 a ×100, klepnutí na kartu
  přičítá a dlouhé podržení odečítá.
- Přidány pojmenované šablony pokladen s měnou, počáteční hotovostí a výchozími
  počty nominálů.
- Nominály lze skrýt a doplnit vlastní; historické záznamy si jejich definici
  ukládají, aby se později nezměnil výsledek.
- Historii lze hledat a filtrovat podle měny, data a rozdílu.
- Kompletní lokální data lze exportovat a bezpečně sloučit zpět ze šifrované
  zálohy chráněné heslem (AES-256-GCM, PBKDF2).
- Obchodní režim zůstává Free se všemi funkcemi a reklamami a jednorázový
  `vycetka_full_unlock` bez reklam; produkční aktivace vyžaduje skutečné
  AdMob/store údaje a sandboxové ověření.

## 0.1.15+16 — úplné jazykové katalogy

- Doplněno všech 5 581 dosavadních anglických fallbacků; všech 36 jazyků nyní
  obsahuje všech 260 uživatelských textů.
- Chyby kamery, OCR a uložení země se překládají ve Flutteru podle stabilních
  nativních chybových kódů. Android ani iOS už nevracejí pevně české texty.
- Opraveno poškození znaků z překladového transportu a jisté terminologické a
  gramatické chyby včetně významu pokladny, podpisu, PDF a názvů měn.
- Zastaralé tvrzení o devíti OCR měnách bylo změněno na aktuálních 32 měn ve
  všech jazycích.
- UI test nyní vykreslí obrazovku počítání ve všech 36 jazycích pro všech 32
  měn, tedy 1 152 kombinací.

## 0.1.14+15 — pouze oficiální hmotnosti bankovek

- Odstraněn plošný odhad 1 g pro bankovky.
- Auditováno všech 201 bankovek; 32 nominálů má dohledatelnou oficiální
  nominální hmotnost a 169 zůstává bez číselné hodnoty.
- EUR používá samostatné hmotnosti podle nominálu; doplněny doložené USD, JPY,
  CAD, HUF, GBP 5/10 a CZK 1 000.
- Pokud započítaná bankovka nemá oficiální hmotnost, UI, historie i export
  zobrazí hmotnost jako nedostupnou místo zavádějícího odhadu či částečného
  součtu.
- Přidán audit zdrojů a automatické pojistky proti návratu 1g fallbacku.

## 0.1.13+14 — oblíbené měny a finální text

- Měny lze označit hvězdičkou jako oblíbené. Volba se bezpečně ukládá a
  oblíbené měny se řadí hned za právě vybranou měnu.
- Stejné pořadí měn používá dashboard i obrazovka počítání.
- Náhled uzávěrky umí zkopírovat nebo systémově sdílet finální text.
- Finální text začíná lokalizovanou hlavičkou aplikace a protokolu a obsahuje
  identitu uzávěrky, souhrn, rozpis nominálů a poznámku.
- Přidány testy perzistence oblíbených měn, jejich pořadí a finálního textu ve
  všech 36 jazykových volbách.

## 0.1.12+13 — jednorázové Bez reklam navždy

- Měsíční předplatné nahradil non-consumable `vycetka_full_unlock` s výchozí
  jednorázovou cenou 4,99 EUR; UI vždy zobrazuje lokalizovanou cenu obchodu.
- Vlastní receipt backend ani expirační cache už nejsou součástí nákupního
  toku. Nákup a obnova používají klientské hlášení Google Play/StoreKitu.
- Aktivní stará Alpha subscription cache a případný obnovený
  `vycetka_ad_free_monthly` se migrují na trvalé Ad-free, aby se nárok neztratil.
- Nabídka jednorázového nákupu a obnovení byla aktualizována ve všech 36
  jazycích. Free nadále obsahuje všechny produktové funkce.
- Přidány deterministické testy nabídky produktu, pending/unknown nákupu,
  dokončení transakce, obnovy a migrace starého nároku.

## 0.1.11+12 — Free / Ad-free monetizace

- Free má bez omezení OCR, historii, podpisy, PDF/CSV a všechny měny.
- Měsíční Ad-free `vycetka_ad_free_monthly` pouze odstraní reklamy; startovní
  evropská cena je 0,99 EUR a UI zobrazuje lokalizovanou cenu obchodu.
- Starý `vycetka_full_unlock` zůstává obnovitelný jako trvalý legacy nárok.
- Přidány Google Mobile Ads, UMP souhlas a adaptivní banner jen na hlavních
  kartách; počítání, OCR, podpis a export zůstávají bez reklam.
- Přidána sedmidenní Alpha cache a rozhraní HTTPS serverového ověření účtenek.
- Přidán audit konkurence a kontrola produkční monetizační konfigurace.
- Verze používá testovací reklamní ID a je QA, nikoli veřejný store release.

## 0.1.10+11 — profesionální uzávěrka

- Identita firmy, provozovny, pokladny, směny a odpovědných osob.
- Slepé počítání, +5/+10, podpisy, PDF/CSV, tisk a systémové sdílení.
- Verzované schéma relace v2 s migrací a zálohou starých dat.

## 0.1.9+10 — jazyky, měny a OCR audit

- 32 měn, 36 jazyků, 52 zemí, 201 bankovek a 191 mincí.
- Rozšířené Android OCR modely a samostatný optický proxy benchmark.

## 0.1.0+1 — MVP source

- CZK, EUR, USD, GBP, CHF, CAD a AUD.
- Ruční počítání bankovek a mincí.
- Lokální bankovkové OCR přes ML Kit a Apple Vision.
- Potvrzení OCR výsledku, zobrazení jistoty a bezpečné porovnání celých slov.
- Očekávaný stav, rozdíl, float a odvod.
- Lokální historie s atomickým zápisem a obnovou zálohy.
- Trial a jednorázové Full odemčení.
- Release bootstrap a automatické testy.
