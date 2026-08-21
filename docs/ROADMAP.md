# Doporučený roadmap

## 0.4.0+19 — aktuální Alpha základ

Ruční počítání 32 měn a 36 jazyků, oblíbené měny, větná kapitalizace,
ověřitelné přibližné hmotnosti, historie a uzávěrky s vlastním nadpisem,
identitou, rozdílem, PDF/CSV/plain exportem a SHA-256. OCR, kamera a QR nejsou
součástí produkční aplikace. Free a trvalé Ad-free mají stejné funkce; liší se
jen reklamami. Schéma dat je v5 s migrací a zálohou.

## Historie 0.3.0+18 — předchozí Alpha základ

Ruční počítání 32 měn, 36 jazyků, lokální OCR návrh, historie, rozdíl/odvod,
identita pokladny, slepé počítání, podpisy a PDF/CSV. Obchodní model je Free se
všemi funkcemi a reklamami a jednorázové Ad-free navždy za výchozích 4,99 EUR.
Nově obsahuje rychlý a profesionální režim, násobiče zadávání, šablony pokladen,
skryté a vlastní nominály, filtry historie a šifrovanou zálohu/import. Alpha má
jen testovací reklamy; produkční produkty obchodů zůstávají otevřené.

Dokončeno je také důkazní otisk uzávěrky (SHA-256 + QR), lokální POS/EFTPOS
CSV párování s povinnou očekávanou hotovostí a zámek přes PIN/biometrii
zařízení. Schéma relací je v4 s explicitní migrací.

## 0.2.1 — uzavření store pilotu

- vlastní AdMob ID, UMP, veřejná privacy policy a podmínky,
- Play/App Store non-consumable a klientské ověření nákupu, obnovy a refundací,
- interní Google Play test a Apple TestFlight matice Free/Ad-free,
- fyzický test exportu a importu přes systémové dialogy Android/iOS.

## 0.3.1 — profesionální provoz

- hromadné reporty za období a souhrn rozdílů,
- volitelná šifrovaná synchronizace až po vyřešení recovery,
- role majitel/vedoucí/zaměstnanec/účetní,
- automatický e-mail účetní,
- audit log změn.

## Další kroky po 0.4

- API pro Dotykačku, mKasu a další systémy podle obchodních dohod,
- více provozoven a dashboard rozdílů.

## Co nedělat příliš brzy

Počítání překrývajících se bankovek nebo ověřování pravosti z jedné fotografie je vysoce rizikové. Nejdříve ověřte spolehlivost jednoduššího workflow jedné bankovky a reálnou ochotu provozoven platit.
