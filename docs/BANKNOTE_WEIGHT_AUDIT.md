# Audit hmotností bankovek

Datum auditu: 2026-07-27

## Pravidlo přijetí

Hmotnost je v katalogu pouze tehdy, když ji zveřejnil vydavatel bankovky,
centrální banka nebo jimi vydaný technický dokument:

- přímo pro nominál,
- jednoznačně pro všechny bankovky dané série, nebo
- jako hmotnost přesně určeného počtu bankovek, ze které lze prostým dělením
  získat hmotnost jednoho kusu.

Rozměry, gramáž substrátu, neoficiální numismatické katalogy, neurčité průměry
a údaje ke staré nebo nejednoznačné sérii se nepřepočítávají. Pokud chybí
přijatelný zdroj, aplikace zobrazí `Nedostupná — bez oficiální hmotnosti`.
Směs obsahující takovou bankovku nemá částečný ani náhradní hmotnostní součet.

## Přijaté údaje

| Měna a nominály | Hmotnost jednoho kusu | Oficiální zdroj |
| --- | ---: | --- |
| EUR 5 / 10 / 20 / 50 / 100 / 200 / 500 | 0,6 / 0,7 / 0,8 / 0,9 / 1,0 / 1,1 / 1,1 g | [Oesterreichische Nationalbank](https://www.oenb.at/en/the-euro/cash-management/banknotes.html) |
| USD 1 / 2 / 5 / 10 / 20 / 50 / 100 | přibližně 1,0 g | [U.S. Currency Education Program](https://www.uscurrency.gov/about-us/currency-facts) |
| GBP 5 / 10 | přibližně 0,7 / 0,85 g | [Bank of England](https://www.bankofengland.co.uk/-/media/boe/files/banknotes/polymer/polymer-qanda-for-businesses.pdf) |
| CAD 5 / 10 / 20 / 50 / 100 | přibližně 0,93 g | [Bank of Canada, 0,093 kg na 100 polymerových bankovek](https://www.bankofcanada.ca/wp-content/uploads/2011/06/Life-Cycle-Assessment-of-Polymer-and-Cotton-Paper-Bank-Notes_opt.pdf) |
| JPY 1 000 / 2 000 / 5 000 / 10 000 | přibližně 1,0 g | [Bank of Japan](https://www.boj.or.jp/en/about/education/oshiete/money/c15.htm) |
| CZK 1 000 | přibližně 1,0 g | [ČNB, 1 kg na 1 000 bankovek](https://www.cnb.cz/export/sites/cnb/cs/verejnost/.galleries/pro_media/konference_projevy/vystoupeni_projevy/download/rezabek_20080321_bankovka_1000Kc.pdf) |
| HUF 500 / 1 000 / 2 000 / 5 000 / 10 000 / 20 000 | přibližně 1,0 g | [Magyar Nemzeti Bank](https://www.mnb.hu/letoltes/tudta.pdf) |

Všechny bankovkové hodnoty se v uživatelském rozhraní označují symbolem `≈`,
protože vlhkost, opotřebení, znečištění a výrobní tolerance mění hmotnost
jednotlivého kusu. Hmotnost neslouží k ověřování pravosti.

## Pokrytí celého katalogu

| Měna | Bankovek v katalogu | S oficiální hmotností | Bez použitelné hodnoty |
| --- | ---: | ---: | ---: |
| CZK | 6 | 1 | 5 |
| EUR | 7 | 7 | 0 |
| USD | 7 | 7 | 0 |
| GBP | 5 | 2 | 3 |
| CHF | 6 | 0 | 6 |
| CAD | 5 | 5 | 0 |
| AUD | 5 | 0 | 5 |
| JPY | 4 | 4 | 0 |
| KRW | 4 | 0 | 4 |
| SEK | 6 | 0 | 6 |
| NOK | 5 | 0 | 5 |
| UAH | 6 | 0 | 6 |
| RUB | 9 | 0 | 9 |
| DKK | 4 | 0 | 4 |
| HUF | 6 | 6 | 0 |
| PLN | 6 | 0 | 6 |
| BRL | 7 | 0 | 7 |
| ARS | 10 | 0 | 10 |
| TRY | 6 | 0 | 6 |
| MXN | 6 | 0 | 6 |
| INR | 8 | 0 | 8 |
| IDR | 7 | 0 | 7 |
| PKR | 8 | 0 | 8 |
| MYR | 6 | 0 | 6 |
| THB | 5 | 0 | 5 |
| NGN | 8 | 0 | 8 |
| ZAR | 5 | 0 | 5 |
| DZD | 5 | 0 | 5 |
| EGP | 9 | 0 | 9 |
| ILS | 4 | 0 | 4 |
| SAR | 8 | 0 | 8 |
| AED | 8 | 0 | 8 |
| **Celkem** | **201** | **32** | **169** |

Příklady odmítnutých údajů: gramáž papíru INR, IDR a ARS neurčuje hmotnost
hotové potištěné bankovky; turecký oficiální údaj je pouze průměr bankovky bez
vazby na nominál; mexický údaj 0,92 g se vztahuje k nejednoznačné starší sérii;
české formulace „necelý kilogram“ a „něco málo přes kilogram“ pro balík 1 000
kusů nejsou dost přesné pro číselnou hodnotu v aplikaci.

## Automatické pojistky

- katalogový test kontroluje všech 201 bankovek a přesně 32 přijatých hodnot,
- každá bankovka s hmotností musí odkazovat na schválený oficiální zdroj,
- neznámá hmotnost je `null`, nikdy náhradních 1 000 mg,
- směs s neznámou hmotností vrací nedostupný celkový údaj,
- rozdílné EUR nominály mají samostatné hmotnosti 0,6 až 1,1 g.
