# OCR, přesnost a bezpečnost

## Co OCR umí

- přečíst viditelný text a čísla z jedné bankovky,
- navrhnout nominál ve vybrané měně,
- zobrazit skóre a důvody klasifikace,
- fungovat lokálně bez nahrávání snímku na server.

## Co OCR neumí

- potvrdit pravost bankovky,
- spolehlivě určit bankovku zakrytou, přeloženou nebo silně poškozenou,
- garantovat 100% výsledek v odlescích, rozmazání a slabém světle,
- bezpečně spočítat hromadu překrývajících se bankovek.

## UX pravidla, která nesmí zmizet

1. Skenuje se jedna bankovka.
2. Uživatel před započtením vždy potvrzuje nominál.
3. Při nízké jistotě se zobrazí všechny nominály měny.
4. Dočasný snímek se po výsledku smaže.
5. Aplikace nikde netvrdí, že ověřuje pravost.

## Testovací matice před vydáním

Pro každý nominál testujte minimálně:

- přední i zadní stranu,
- starší i aktuální platné série,
- světlý pult, tmavý pult a barevné pozadí,
- denní světlo, teplé umělé světlo a slabé světlo,
- zařízení nižší, střední a vyšší třídy,
- bankovku rovně, otočenou o 90° a mírně šikmo,
- opotřebenou a pomačkanou bankovku.

Cíl pro pilot: alespoň 98 % správný návrh u kvalitní fotografie a 100 % bezpečné chování, tedy žádné automatické započtení bez potvrzení.
