import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/country_catalog.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/l10n/app_localizations.dart';

void main() {
  test('every country maps to a supported locale and currency', () {
    final supported = AppLocalizations.supportedLocales
        .map((locale) => locale.languageCode)
        .toSet();

    for (final country in CountryCatalog.all) {
      expect(
        supported,
        contains(country.locale.languageCode),
        reason: country.id,
      );
      final l10n = AppLocalizations(country.locale);
      expect(country.localName, isNotEmpty, reason: country.id);
      expect(
        CurrencyCatalog.containsCode(country.currencyCode),
        isTrue,
        reason: country.id,
      );
      expect(
        l10n.tr('currency${country.currencyCode}'),
        isNot('currency${country.currencyCode}'),
        reason: country.id,
      );
    }
  });

  test('Japan and South Korea open in their language and currency', () {
    final japan = CountryCatalog.byId('JP')!;
    final korea = CountryCatalog.byId('KR')!;

    expect((japan.locale.languageCode, japan.currencyCode), ('ja', 'JPY'));
    expect((korea.locale.languageCode, korea.currencyCode), ('ko', 'KRW'));
    expect(AppLocalizations(japan.locale).tr('appTitle'), 'レジ締め・現金カウンター');
    expect(AppLocalizations(korea.locale).tr('appTitle'), '금고 마감 및 현금 계산기');
  });

  test('application title is localized for every supported language', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final title = AppLocalizations(locale).tr('appTitle');
      expect(title, isNotEmpty, reason: locale.languageCode);
      expect(title, isNot('appTitle'), reason: locale.languageCode);
    }
  });

  test('the complete currency catalog has usable labels and denominations', () {
    expect(CurrencyCatalog.all, isNotEmpty);
    for (final currency in CurrencyCatalog.all) {
      expect(currency.code, matches(r'^[A-Z]{3}$'));
      expect(currency.denominations, isNotEmpty, reason: currency.code);
      expect(currency.name, isNotEmpty, reason: currency.code);
      for (final denomination in currency.denominations) {
        expect(denomination.label, isNotEmpty, reason: currency.code);
        expect(denomination.minorUnits, greaterThan(0), reason: currency.code);
      }
    }
  });

  test('country picker contains all 21 euro-area members', () {
    const euroAreaIds = <String>{
      'AT',
      'BE',
      'BG',
      'HR',
      'CY',
      'DE',
      'EE',
      'FI',
      'FR',
      'GR',
      'IE',
      'IT',
      'LV',
      'LT',
      'LU',
      'MT',
      'NL',
      'PT',
      'SK',
      'SI',
      'ES',
    };
    final configured = CountryCatalog.all
        .where((country) => country.currencyCode == 'EUR')
        .map((country) => country.id)
        .toSet();

    expect(configured, euroAreaIds);
  });

  test('country picker is ordered from most to least populous', () {
    expect(
      CountryCatalog.mostToLeastPopulous.map((country) => country.id),
      <String>[
        'IN',
        'US',
        'ID',
        'PK',
        'NG',
        'BR',
        'RU',
        'MX',
        'JP',
        'EG',
        'TR',
        'DE',
        'TH',
        'GB',
        'FR',
        'ZA',
        'IT',
        'KR',
        'ES',
        'DZ',
        'AR',
        'CA',
        'UA',
        'PL',
        'MY',
        'SA',
        'AU',
        'NL',
        'BE',
        'AE',
        'CZ',
        'PT',
        'SE',
        'GR',
        'IL',
        'HU',
        'AT',
        'CH',
        'BG',
        'DK',
        'FI',
        'NO',
        'IE',
        'SK',
        'HR',
        'LT',
        'SI',
        'LV',
        'EE',
        'CY',
        'LU',
        'MT',
      ],
    );
  });

  test('top-level picker has one population-ranked euro-area card', () {
    final ids = CountryCatalog.topLevelByPopulation
        .map((country) => country.id)
        .toList();

    expect(ids.take(4), <String>['IN', 'EUROZONE', 'US', 'ID']);
    expect(ids.where((id) => id == 'EUROZONE').length, 1);
    expect(CountryCatalog.euroArea.localName, 'Eurozone');
    expect(
      CountryCatalog.topLevelByPopulation
          .where((country) => country.id != 'EUROZONE')
          .every((country) => country.currencyCode != 'EUR'),
      isTrue,
    );
  });

  const completeCatalogLanguages = {'en'};
  for (final locale in AppLocalizations.supportedLocales) {
    test('${locale.languageCode} covers the complete app workflow', () {
      final missing = completeCatalogLanguages.contains(locale.languageCode)
          ? AppLocalizations.missingTranslationKeys(locale.languageCode)
          : AppLocalizations.missingCoreTranslationKeys(locale.languageCode);
      expect(missing.join('|'), isEmpty, reason: locale.languageCode);
    });
  }
}
