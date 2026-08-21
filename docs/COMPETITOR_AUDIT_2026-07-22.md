# Konkurenční audit Výčetky

**Datum:** 22. 7. 2026
**Metoda:** aktuální veřejné listingy Google Play a Apple App Store, dostupné
screenshoty a deklarace funkcí/soukromí. Pokus o interaktivní prohlížeč v
tomto běhu neměl dostupný browser backend. APK z neoficiálních mirrorů nebyla
stažena ani spuštěna, protože by přinesla zbytečné riziko dodavatelského
řetězce. Fyzické ověření konkurence proto není vydáváno za dokončené.

## Reprezentativní konkurenti

| Aplikace | Veřejně deklarované silné stránky | Obchodní model / signál |
|---|---|---|
| [Cash Counter: Count Money](https://apps.apple.com/us/app/cash-counter-count-money/id6472790146) | rychlé klepání a přímý vstup, více počítadel, CSV/text export, iCloud, widgety, Apple Watch, 32 jazyků | 4,7/5 z 187 hodnocení v US; v UK listing uvádí mimo jiné 9,99 GBP měsíčně |
| [Cash Counter Count Note & Coin](https://play.google.com/store/apps/details?id=com.panagola.app.cash) | více aktivních počítadel, několik měn současně, režim +1/+10/+100, tisk/PDF/sdílení | 10 tis.+ instalací, reklamy a IAP |
| [Cash Calculator – Cashier](https://play.google.com/store/apps/details?id=sachapps.denocalc) | vlastní nominály, cash-in/out kniha, hledání podle data/jména, PDF, VAT/GST, nastavitelná pole | 10 tis.+ instalací, reklamy; široká funkčnost, ale složitější produkt a citlivější data |
| [Cash Calculator – Money Counter](https://play.google.com/store/apps/details?id=com.byone.cashcalculatorapp) | jednoduchý bezplatný výpočet a PDF, všechny funkce zdarma | 100 tis.+ instalací, reklamy; changelog zmiňuje omezení reklam jako UX téma |
| [Cash Counter for Bills & Coins](https://apps.apple.com/us/app/cash-counter-for-bills-coins/id6752465174) | velké karty pro rychlé klepání, dlouhý stisk pro odečet, směny/štítky a analytika | bez reklam a bez předplatného; premium jednorázově |
| [Tally My Cash](https://play.google.com/store/apps/details?id=com.addas.tallymycash) | hledání historie, dlouhým stiskem kalkulačka, sdílení, indický pracovní tok | 50 tis.+ instalací, deklarovaně bez reklam |

Počty instalací, hodnocení, ceny a store deklarace jsou proměnlivé a musí se
před obchodním rozhodnutím znovu ověřit.

## Kde je Výčetka silnější

- 32 měn, 201 bankovek a 191 mincí v jednom konzistentním katalogu.
- 36 jazyků a výběr země/měny; konkurenti obvykle řeší méně měn nebo jen
  generické vlastní řádky.
- Identita firmy, provozovny, pokladny, směny, pokladníka a kontrolujícího.
- Slepé počítání, očekávaný stav, manko/přebytek, ponechaná hotovost a odvod.
- Grafické podpisy a profesionální PDF/CSV s číslem dokladu.
- Výpočet hmotnosti mincí/bankovek a lokální práce bez účtu.
- OCR jako volitelný návrh nominálu s povinným lidským potvrzením.

Profesionální uzávěrka je lepší odlišení než snaha být jen další jednoduchou
kalkulačkou bankovek.

## Co máme špatně nebo slabší

### P0 — před veřejným vydáním

1. **OCR není dost spolehlivé jako hlavní marketingový slib.** Vlastní
   desktopový proxy benchmark dosáhl jen 140/375 Top-1. OCR ponechat jako
   pomocnou Alpha funkci a do screenshotu číslo 1 dát ruční rychlé počítání a
   uzávěrku, ne kameru.
2. **Monetizace ještě nemá živou konfiguraci obchodů.** Chybí vlastní AdMob
   ID, non-consumable `vycetka_full_unlock`, consent message a veřejné právní
   URL. Potvrzený jednorázový model vlastní receipt backend nepotřebuje.
3. **Nové profesionální texty nejsou kompletně lidsky přeložené.** Základní
   plán a nákupní akce jsou nyní ve všech 36 jazycích, delší vysvětlení stále
   používají anglický fallback mimo češtinu.
4. **Datová obnova není uživatelsky uzavřená.** Lokální historie je soukromá,
   ale ztráta telefonu znamená ztrátu dat. Nejdříve přidat šifrovaný export a
   import zálohy; cloud až po vyřešení účtů, rolí a práva na výmaz.

### P1 — největší dopad na každodenní používání

1. **Vlastní a skryté nominály.** Provozovny používají poukázky, žetony a
   nemusí chtít vidět všechny drobné. Konkurence to nabízí a zrychluje tím
   obrazovku.
2. **Šablony a více pokladen.** Profil umí jednu výchozí identitu, ale chybí
   rychlé přepnutí „Bar / Recepce / Pokladna 2“ a duplikace předchozí uzávěrky.
3. **Hledání a filtry historie.** Datum, pokladna, obsluha, měna, číslo dokladu
   a pouze rozdílové uzávěrky.
4. **Rychlý vstup na malém telefonu.** Současná řádka −/počet/+/+5/+10 je na
   360 px funkční, ale vizuálně hustá. Doporučený další prototyp: velká karta,
   klepnutí +1, dlouhý stisk −1 a samostatný numerický vstup; +10/+100 jako
   volitelný násobitel.
5. **Jedním klepnutím kopírovat součet a sdílet stručný text.** PDF je vhodné
   pro archiv, ale obsluha často potřebuje jen vložit výsledek do POS zprávy.

### P2 — růst produktu

- šifrovaný backup/import a teprve potom volitelná synchronizace,
- role majitel/vedoucí/pokladní a neměnný audit log změn,
- export více uzávěrek za období a souhrn rozdílů,
- import očekávané částky z POS přes CSV; konkrétní POS API až podle poptávky,
- widget/Watch až po ověření, že jej platící uživatelé skutečně potřebují.

## Doporučené pořadí

1. Dokončit compliant Free/Ad-free store tok a nepustit testovací reklamy do
   veřejného releasu.
2. Udělat historii s filtrem a šablony více pokladen.
3. Přidat skrytí/vlastní nominály a otestovat nový rychlý řádek na Nokii.
4. Přidat export/import zálohy a hromadný měsíční report.
5. Teprve po reálném ML Kit/Vision acceptance investovat do dalšího OCR.

Potvrzená startovní cena je 4,99 EUR jednorázově za trvalé odstranění reklam.
Je srozumitelnější než levné měsíční předplatné a odpovídá konkurentovi s
jednorázovým premium. Po prvních 100–300 nákupech je vhodné znovu změřit
konverzi, příjem z reklam a cenu podpory; jednorázový prodej nevytváří
opakovaný příjem.
