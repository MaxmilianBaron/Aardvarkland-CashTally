# Zásady ochrany osobních údajů — šablona

> Před zveřejněním doplňte provozovatele, kontakty, datum účinnosti a veřejnou URL. Text musí zkontrolovat právník podle skutečné produkční konfigurace.

**Provozovatel:** [NÁZEV / JMÉNO, IČO, ADRESA]
**Kontakt:** [E-MAIL]
**Účinnost od:** [DATUM]

## 1. Jaká data Výčetka zpracovává

Aplikace umožňuje ručně zapisovat počty bankovek a mincí, očekávaný stav pokladny, ponechanou hotovost a uživatelskou poznámku. Tyto údaje se v základní verzi ukládají pouze do aplikačního úložiště zařízení.

Verze 0.4.0+19 nepoužívá kameru, fotografie bankovek ani OCR. Počty a
poznámky vznikají ručním zadáním a zůstávají v privátním úložišti zařízení.

## 2. Nákupy

Jednorázový nákup Výčetka bez reklam zpracovává Apple App Store nebo Google
Play. Nákup pouze trvale odstraní reklamy; funkce aplikace neomezuje a
automaticky se neobnovuje. Aplikace obdrží technický identifikátor transakce,
store token, stav a identifikátor produktu, nikoli kompletní údaje platební
karty. Tyto údaje ověří klientská knihovna příslušného obchodu; provozovatel
nepoužívá vlastní platební ani receipt server. Na platbu a refundace se
vztahují zásady příslušného obchodu.

## 3. Oprávnění zařízení

Aplikace pro ruční výčetku nevyžaduje přístup ke kameře ani mikrofonu.

## 4. Přenos a sdílení

V aplikaci není účet ani cloudová synchronizace a obsah výčetek ani podpisy se
reklamnímu systému neposílají.
Režim Free používá Google Mobile Ads a Google User Messaging Platform. Podle
země, nastavení zařízení a uděleného souhlasu mohou Google a jeho partneři
zpracovat zejména IP adresu, reklamní nebo aplikační identifikátory, technické
údaje zařízení, diagnostiku, přibližnou polohu odvozenou z IP a interakce s
reklamou. Přesný seznam partnerů, účelů a právních základů musí produkční
provozovatel doplnit podle skutečné AdMob/UMP konfigurace a zpřístupnit přes
nastavení soukromí reklam.

Při aktivním nároku bez reklam aplikace reklamní SDK při startu neinicializuje
a reklamní požadavek neposílá. Android build má systémové zálohování
aplikačních dat vypnuté. Na Apple zařízeních se chování lokálních dat řídí
systémovou zálohou uživatele a musí být ověřeno na podepsaném buildu.

## 5. Doba uchování a smazání

Výčetky zůstávají v zařízení, dokud je uživatel jednotlivě nesmaže nebo
neodinstaluje aplikaci. Odinstalace zpravidla odstraní lokální data, avšak
obnovení systémové zálohy se řídí pravidly Apple/Google. Obchod může informace
o nákupu uchovávat po dobu nutnou pro jeho obnovu, účetnictví, prevenci
podvodů a právní povinnosti. Konkrétní lhůty se řídí zásadami Apple nebo
Google.

## 6. Bezpečnost

Stav trvalého nároku bez reklam je uložen v chráněném úložišti
operačního systému. Historie výčetek je uložena v privátním aplikačním
adresáři. Žádné technické opatření však nezaručuje absolutní bezpečnost
zařízení, které je odemčené, rootnuté nebo jailbreaknuté.

## 7. Děti

Aplikace není určena dětem a vědomě od nich neshromažďuje osobní údaje.

## 8. Změny zásad

Při změně reklamních partnerů nebo účelů, přidání cloudu, účtů, analytiky či
crash reportingu nebo změně způsobu ověřování nákupů musí být tyto zásady
před vydáním aktualizace upraveny.

## 9. Kontakt

Dotazy a žádosti související se soukromím posílejte na [E-MAIL].
