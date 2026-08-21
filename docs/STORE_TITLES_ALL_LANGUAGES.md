# Lokalizované názvy Google Play

Google Play zobrazí uživateli překlad výchozího store listingu, pokud jeho
jazyk odpovídá lokalizaci přidané v Play Console. Výchozí listing Výčetky má
být `en-US`, aby nepodporované jazyky dostaly anglický název
`Cash Closing & Till Counter`.

Zdroj pravdy je `store_metadata/google_play_titles.tsv`. Přímo nahratelné
soubory jsou ve standardní Fastlane struktuře
`fastlane/metadata/android/<play-locale>/title.txt`.

## Pokrytí

- aplikace podporuje 36 jazyků,
- Google Play aktuálně umožňuje listing pro 34 z nich,
- lucemburština (`lb`) a maltština (`mt`) nejsou v seznamu podporovaných
  lokalizací Google Play a používají anglický výchozí listing,
- norské `nb` aplikace se mapuje na Google Play `no-NO`,
- hebrejské `he` aplikace se mapuje na historický Google Play kód `iw-IL`.

Všechny názvy splňují limit Google Play 30 znaků. Ověření:

```powershell
py scripts/verify_store_titles.py
```

## Nastavení v Play Console

1. Nastavit výchozí jazyk hlavního store listingu na English (United States).
2. Otevřít `Grow users > Store presence > Store listings`.
3. V `Manage translations > Select languages` přidat 33 dalších Play jazyků.
4. Do každého jazyka vložit příslušný `title.txt`, případně metadata nahrát
   přes Fastlane/Google Play Developer API.
5. V Play Console zkontrolovat náhled každého RTL a CJK listingu.

Samotné soubory v repozitáři Google Play nezmění. Projeví se po jejich vložení
nebo nahrání do Play Console a publikování změny listingu.

## Název uvnitř aplikace a na ploše

Stejný katalog se používá také pro viditelný název v horní liště aplikace a
pro název pod ikonou na ploše:

- Flutter vybírá název podle jazyka zvoleného v Nastavení aplikace,
- Android vybírá `@string/app_name` podle systémového jazyka telefonu,
- iOS vybírá `CFBundleDisplayName` z lokalizovaného `InfoPlist.strings` podle
  systémového jazyka telefonu,
- lucemburština a maltština používají anglický název ve všech třech místech.

Po změně TSV je nutné znovu vygenerovat platformní soubory a spustit kontrolu:

```powershell
py scripts/generate_localized_app_names.py
py scripts/verify_store_titles.py
```

Název pod ikonou může Android nebo iOS vizuálně zkrátit podle šířky plochy;
v nainstalovaném balíčku ale zůstává celý lokalizovaný text.
