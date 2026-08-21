# Audit jazyků a měn — historický záznam 28. 7. 2026

> Aktuální 0.4.0+19 používá stejný katalog 36 jazyků a 32 měn, ale OCR,
> kamerové modely a OCR matice níže už nejsou součástí runtime. Aktuální
> kontrola běží přes `test/country_localization_test.dart` a
> `test/l10n_currency_ui_matrix_test.dart`; hmotnosti se zobrazují jen pro
> doložené nominály. Tato stránka zachovává historické výsledky pro audit.

## Rozsah

Audit pokrývá všech 36 jazykových voleb, 52 zemí, 32 měn, 201 bankovek a
191 mincí. Kontroly záměrně oddělují technickou úplnost překladů, gramatickou
kontrolu, vykreslení UI, formátování částek a OCR katalog.

## Automatická matice

- Všech 36 jazyků má všech 260 uživatelských klíčů a shodné placeholdery jako
  angličtina: 0 anglických fallbacků, 0 chybějících hlavních klíčů a 0 chyb
  placeholderů.
- Dashboard byl vykreslen na ploše 360 × 800 pro všech 36 jazyků v režimu
  Free i Ad-free: 72 kombinací bez layout výjimky.
- Obrazovka výčetky byla vykreslena pro všech 32 měn ve všech 36 jazycích na
  ploše 360 × 800: 1 152 kombinací bez layout výjimky.
- Nabídka jednorázového Ad-free navždy byla vykreslena na šířce 360 px ve všech 36
  jazycích bez layout výjimky. Názvy plánu, cena, nákupní akce, právní a
  diagnostické vysvětlení mají přímý překlad.
- Všech 392 nominálů bylo naformátováno ve všech 36 jazycích, tedy 14 112
  kombinací. Zvláštní testy ověřují například `$1,234.56`, `$1.234,56` a
  indické seskupení `$1,23,456.78`.
- Syntetická OCR matice pokrývá všech 201 bankovek. U všech 191 mincí ověřuje,
  že classifier nikdy nevrací mincovou položku; mince se zadávají ručně.

Strojově čitelný výsledek je v kořenovém
`artifacts/language-fix-2026-07-28/final/language-currency-audit.json`,
gramatické kandidáty obsahuje `grammar-report.json` ve stejné složce.

## Nalezené a opravené chyby

1. Flutter framework neměl Material/Cupertino lokalizaci pro `lb` a `mt` a
   aplikace mohla po volbě Lucemburska nebo Malty spadnout. Přidané bezpečné
   delegáty nyní používají podporovaný frameworkový fallback, zatímco texty
   aplikace zůstávají lucemburské nebo maltské.
2. Dlouhé lokalizované názvy přetékaly v titulku dashboardu a v seznamu měn na
   360 px displeji. Titulek a položky nyní bezpečně používají zkrácení s
   výpustkou.
3. Částky používaly téměř všude desetinnou čárku a stejné seskupování tisíců.
   Formátování nyní respektuje locale přes `intl`, aniž by se peněžní výpočty
   převáděly z celých minor units na binární desetinná čísla.
4. Android měl pouze latinský ML Kit model. Doplněny jsou bundlované modely
   pro japonštinu, korejštinu a dévanágarí; JPY, KRW a INR vybírají správný
   recognizer. iOS Vision dostává jazykové hinty podle zvolené měny.
5. V katalogu aktivních nominálů chyběla indická vládní bankovka ₹1 a současná
   saúdská bankovka 1 SAR. Obě byly doplněny vedle stejně hodnotných mincí.
6. Opraveny byly jisté jazykové chyby: arabská tanwínová diakritika ve třech
   větách, španělské `unos 1 g`, mezera před výpustkou v němčině, chorvatštině
   a slovinštině a související typografie.
7. Doplněny byly všechny dřívější anglické fallbacky profesionální uzávěrky,
   exportů, oblíbených měn, monetizace a systémových chyb.
8. Android/iOS OCR mosty nyní vracejí jen stabilní kódy. Uživatelské chyby
   kamery, OCR a uložení výběru se lokalizují ve Flutteru.
9. Opraveny byly transportně poškozené znaky `—`, `…`, `·` a `ł`, chybné
   překlady výrazu pokladna a podpis a zastaralý počet devíti OCR měn.

## Gramatický audit

LanguageTool 6.6 byl spuštěn lokálně a každý přímo přeložený řetězec byl
kontrolován samostatně. Automatická pravidla byla dostupná pro 17 jazyků:
`ar, da, de, el, en, es, fr, it, ja, nl, pl, pt, ru, sk, sl, sv, uk`.
Pro 19 jazyků pravidla v tomto nástroji dostupná nebyla:
`bg, cs, et, fi, he, hi, hr, hu, id, ko, lb, lt, lv, ms, mt, nb, th, tr, ur`.

Po jistých opravách zůstalo 600 kandidátů nad 4 420 kontrolovanými řetězci.
Jde převážně o zkratku `OCR`, názvy měn, značky obchodů, placeholdery, krátké
UI popisky a oborové složeniny, které slovníky neznají.
Nejsou automaticky měněny, protože návrhy jako přepsání `OCR`, názvu měny nebo
placeholderu by text poškodily. Úplná stylistická korektura 36 jazyků rodilými
mluvčími zůstává otevřená.

## Anglické fallbacky

Všech 36 jazyků má 0 anglických fallbacků. Ručně psané starší překlady mají
vždy přednost; doplňkový katalog pokrývá pouze dříve chybějící klíče.

Doplňkový katalog vznikl strojovým překladem s kontrolou placeholderů,
transportních znaků a ručními opravami jistých terminologických chyb. Nula
fallbacků proto znamená technickou a obsahovou úplnost, nikoli certifikovanou
korekturu rodilými mluvčími. Ta zůstává doporučená před širokým veřejným
vydáním.

## Katalog měn

| Měna | Bankovky | Mince | Android OCR model |
|---|---:|---:|---|
| CZK | 6 | 6 | Latin |
| EUR | 7 | 8 | Latin |
| USD | 7 | 6 | Latin |
| GBP | 5 | 8 | Latin |
| CHF | 6 | 7 | Latin |
| CAD | 5 | 7 | Latin |
| AUD | 5 | 6 | Latin |
| JPY | 4 | 6 | Japanese |
| KRW | 4 | 6 | Korean |
| SEK | 6 | 4 | Latin |
| NOK | 5 | 4 | Latin |
| UAH | 6 | 6 | Latin |
| RUB | 9 | 8 | Latin |
| DKK | 4 | 6 | Latin |
| HUF | 6 | 6 | Latin |
| PLN | 6 | 9 | Latin |
| BRL | 7 | 5 | Latin |
| ARS | 10 | 4 | Latin |
| TRY | 6 | 7 | Latin |
| MXN | 6 | 9 | Latin |
| INR | 8 | 6 | Devanagari |
| IDR | 7 | 4 | Latin |
| PKR | 8 | 4 | Latin |
| MYR | 6 | 4 | Latin |
| THB | 5 | 6 | Latin |
| NGN | 8 | 3 | Latin |
| ZAR | 5 | 6 | Latin |
| DZD | 5 | 8 | Latin |
| EGP | 9 | 3 | Latin |
| ILS | 4 | 6 | Latin |
| SAR | 8 | 7 | Latin |
| AED | 8 | 6 | Latin |

`Latin` u měn s arabským, hebrejským, thajským nebo cyrilským písmem
neznamená plnou podporu jejich písma. Bundlované Android ML Kit modely jsou
jen Latin, Chinese, Devanagari, Japanese a Korean. Číselná hodnota a latinské
prvky mohou být rozpoznány, ale přesnost těchto měn musí potvrdit reálný
optický benchmark.

## Primární zdroje nominálů

Katalog byl porovnán s primárními zdroji centrálních bank. Mezi rozhodující
kontroly patří ČNB, ECB, Bank of England, Bank of Scotland, Bank of Japan,
Bank of Korea, RBI, Saudi Central Bank, Danmarks Nationalbank, Bank of Canada,
Reserve Bank of Australia, Sveriges Riksbank, NBU, Bank of Russia, CBR Brazil,
BCRA Argentina, Bank Indonesia, State Bank of Pakistan, Bank of Thailand,
South African Reserve Bank, Central Bank of Egypt, Bank of Israel a Central
Bank of the UAE.

Katalog představuje aktivní nebo stále platná oběživa, nikoli seznam všech
historických sérií. Proto například DKK neobsahuje vyřazenou 1000korunovou
bankovku, zatímco GBP obsahuje platnou skotskou £100 a INR ponechává zákonné
₹2000 i vládní ₹1.

Rozhodující odkazy:

- RBI FAQ: <https://www.rbi.org.in/scripts/FS_FAQs.aspx?Id=136&fn=2753>
- Saudi Central Bank, šestá emise:
  <https://www.sama.gov.sa/ar-sa/Currency/SecurityFeatures/Pages/SixthIssueSecurityFeatures.aspx>
- Danmarks Nationalbank, platné bankovky:
  <https://www.nationalbanken.dk/en/what-we-do/notes-and-coins/security-in-banknotes-and-coins>
- Bank of England, aktuální bankovky:
  <https://www.bankofengland.co.uk/banknotes/current-banknotes>
- Bank of England, přehled skotských a severoirských bankovek:
  <https://www.bankofengland.co.uk/banknotes/uk-notes-and-coins>
