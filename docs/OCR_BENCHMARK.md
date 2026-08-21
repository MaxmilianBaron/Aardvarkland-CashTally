# OCR benchmark — 22. 7. 2026

## Závěr

OCR zatím nelze označit za produkčně spolehlivé pro všechny bankovky. Čistý
desktopový proxy test skončil po opravách na 140/375 správných výsledků Top‑1
(37,3 %) a 146/375 Top‑3 (38,9 %). Produkční Android používá Google ML Kit a
iOS Apple Vision, zatímco tento test používá Tesseract 5.4; jeho čísla jsou
zátěžový signál pro dataset a classifier, nikoli akceptace ML Kitu nebo Vision.

## Korpus a dohledatelnost

Nástroj `scripts/build_ocr_corpus.py` prošel všech 201 bankovek katalogu a
vyhledával licenčně popsané snímky přes Wikimedia Commons API. Každý přijatý
soubor má v `sources.json` stránku zdroje, autora, licenci, URL a SHA‑256.

Výsledek po automatickém a ručním auditu:

- 25 přijatých snímků v 7 měnách,
- 167 nenalezených,
- 5 neúspěšně stažených,
- 4 ručně odmítnuté (výřez bezpečnostního prvku nebo specimen),
- 176 katalogových bankovek a 25 měn tedy nemá čistý optický vzorek.

Přijaté pokrytí je CZK 6, EUR 7, USD 1, UAH 5, BRL 1, INR 2 a EGP 3. Snímky
byly ručně zkontrolovány v kontaktních listech pod kořenovým
`artifacts/ocr-benchmark/corpus-current/review/`.

## Úhly a podmínky

Každý z 25 snímků má 15 deterministických variant:

- originál,
- rotace −20°, −12°, −6°, +6°, +12° a +20°,
- perspektiva zleva, zprava, shora a zdola,
- tmavý, přesvětlený, nízký kontrast a Gaussovo rozmazání.

Bankovka je před transformací zvětšena tak, aby podobně jako v kamerovém
rámečku vyplnila většinu obrazu. Manifest 375 variant je v
`corpus-current/variants/variants.json`.

## Desktopový proxy výsledek

Tesseract dostal jazykové modely podle měny a režim pro řídký text bankovek.
Ve všech 375 případech vrátil neprázdný text. Původní classifier správně určil
124 Top‑1 a 138 Top‑3 výsledků. Audit objevil a opravil:

1. nepřevedené arabské, východoarabské, dévanágarí, thajské a full-width
   číslice na ASCII číslice;
2. shodné hodnocení krátkého fragmentu `2` a přesnější hodnoty `20`;
3. chybějící hindské slovní aliasy nominálů INR.

Po opravách stejná OCR data dosáhla 140 Top‑1 a 146 Top‑3. Zlepšení tedy není
způsobené jinými obrázky nebo příznivějšími úhly.

| Měna | Top‑1 | Úspěšnost |
|---|---:|---:|
| EUR | 67/105 | 63,8 % |
| BRL | 8/15 | 53,3 % |
| UAH | 21/75 | 28,0 % |
| EGP | 13/45 | 28,9 % |
| USD | 4/15 | 26,7 % |
| INR | 7/30 | 23,3 % |
| CZK | 20/90 | 22,2 % |

Podle transformace byl Top‑1 výsledek od 24 % u perspektivy zdola do 52 % u
rozmazání; originál dosáhl 12/25, tedy 48 %. Pět zdrojů neuspělo ani v jedné z
15 variant: EUR 5, UAH 200, INR 2000, EGP 10 a EGP 100.

Úplný report před opravami je `tesseract-report.json`, po opravách
`tesseract-report-after-fixes.json`; surový text všech průchodů je v
`tesseract-results.json`.

## Proč není uzavřený ML Kit/Vision test

Připravený Android instrumentation test
`OcrCorpusBenchmarkTest.kt` umí spustit stejné varianty přímo přes čtyři
bundlované ML Kit recognizery a zapsat výsledek pro Dart classifier. AVD však
na tomto PC nespustil x86_64 obraz: Android Emulator vyžaduje hardwarovou
akceleraci a Windows hlásí `Virtualization Enabled In Firmware: No`.
Softwarový x86 běh skončil a SDK nenabízí vhodný ARM64 systémový obraz.

Instrumentation APK se sestaví, ale skutečný optický ML Kit benchmark mimo
telefon zůstává otevřený, dokud nebude v BIOS/UEFI povolena CPU virtualizace.
iOS Vision test navíc vyžaduje macOS/Xcode.

## Bezpečnostní hranice

- OCR pouze navrhuje nominál a uživatel jej vždy potvrzuje.
- OCR neověřuje pravost bankovky.
- Mince se OCR nesnímají; zadávají se ručně.
- Fotografie z aplikace zůstává dočasná a po zpracování se maže.
- Syntetických 201/201 classifier testů dokládá katalog a rozhodovací logiku,
  nikoli optickou přesnost.

## Další přesný krok

1. Povolit virtualizaci CPU v BIOS/UEFI.
2. Spustit AVD `Vycetka_OCR_Audit`, nahrát `variants.json` a 375 obrázků a
   provést `OcrCorpusBenchmarkTest` s ML Kit.
3. Rozšířit korpus o chybějících 176 nominálů z právně použitelných zdrojů a
   zopakovat stejné transformace.
4. Teprve podle ML Kit výsledků upravit kamerové předzpracování; desktopový
   Tesseract sám není důvod měnit produkční kamerový řetězec.
