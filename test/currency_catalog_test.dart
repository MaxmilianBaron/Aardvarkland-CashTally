import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/banknote_weight_sources.dart';
import 'package:vycetka/data/currency_catalog.dart';

void main() {
  test('catalog contains all requested currencies', () {
    expect(
      CurrencyCatalog.all.map((currency) => currency.code).toSet(),
      <String>{
        'CZK',
        'EUR',
        'USD',
        'GBP',
        'CHF',
        'CAD',
        'AUD',
        'JPY',
        'KRW',
        'SEK',
        'NOK',
        'UAH',
        'RUB',
        'DKK',
        'HUF',
        'PLN',
        'BRL',
        'ARS',
        'TRY',
        'MXN',
        'INR',
        'IDR',
        'PKR',
        'MYR',
        'THB',
        'NGN',
        'ZAR',
        'DZD',
        'EGP',
        'ILS',
        'SAR',
        'AED',
      },
    );
  });

  test('denomination IDs are unique inside every currency', () {
    for (final currency in CurrencyCatalog.all) {
      final ids = currency.denominations.map((item) => item.id).toList();
      expect(ids.toSet().length, ids.length, reason: currency.code);
    }
  });

  test('requested banknote sets are present', () {
    final expectedMajorUnits = <String, Set<int>>{
      'CZK': <int>{100, 200, 500, 1000, 2000, 5000},
      'EUR': <int>{5, 10, 20, 50, 100, 200, 500},
      'USD': <int>{1, 2, 5, 10, 20, 50, 100},
      'GBP': <int>{5, 10, 20, 50, 100},
      'CHF': <int>{10, 20, 50, 100, 200, 1000},
      'CAD': <int>{5, 10, 20, 50, 100},
      'AUD': <int>{5, 10, 20, 50, 100},
      'JPY': <int>{1000, 2000, 5000, 10000},
      'KRW': <int>{1000, 5000, 10000, 50000},
      'SEK': <int>{20, 50, 100, 200, 500, 1000},
      'NOK': <int>{50, 100, 200, 500, 1000},
      'UAH': <int>{20, 50, 100, 200, 500, 1000},
      'RUB': <int>{5, 10, 50, 100, 200, 500, 1000, 2000, 5000},
      'DKK': <int>{50, 100, 200, 500},
      'HUF': <int>{500, 1000, 2000, 5000, 10000, 20000},
      'PLN': <int>{10, 20, 50, 100, 200, 500},
      'BRL': <int>{2, 5, 10, 20, 50, 100, 200},
      'ARS': <int>{10, 20, 50, 100, 200, 500, 1000, 2000, 10000, 20000},
      'TRY': <int>{5, 10, 20, 50, 100, 200},
      'MXN': <int>{20, 50, 100, 200, 500, 1000},
      'INR': <int>{1, 10, 20, 50, 100, 200, 500, 2000},
      'IDR': <int>{1000, 2000, 5000, 10000, 20000, 50000, 100000},
      'PKR': <int>{10, 20, 50, 75, 100, 500, 1000, 5000},
      'MYR': <int>{1, 5, 10, 20, 50, 100},
      'THB': <int>{20, 50, 100, 500, 1000},
      'NGN': <int>{5, 10, 20, 50, 100, 200, 500, 1000},
      'ZAR': <int>{10, 20, 50, 100, 200},
      'DZD': <int>{100, 200, 500, 1000, 2000},
      'EGP': <int>{0, 1, 5, 10, 20, 50, 100, 200},
      'ILS': <int>{20, 50, 100, 200},
      'SAR': <int>{1, 5, 10, 20, 50, 100, 200, 500},
      'AED': <int>{5, 10, 20, 50, 100, 200, 500, 1000},
    };

    for (final entry in expectedMajorUnits.entries) {
      final currency = CurrencyCatalog.byCode(entry.key);
      final actual = currency.banknotes
          .map((note) => note.minorUnits ~/ currency.minorUnitScale)
          .toSet();
      expect(actual, entry.value, reason: entry.key);
    }
  });

  test('zero-decimal currencies never scale whole cash values', () {
    for (final code in <String>['JPY', 'KRW', 'HUF', 'IDR']) {
      expect(CurrencyCatalog.byCode(code).fractionDigits, 0, reason: code);
    }
    expect(CurrencyCatalog.byCode('JPY').formatMinor(1000), '¥1 000');
    expect(CurrencyCatalog.byCode('KRW').formatMinor(50000), '₩50 000');
  });

  test('money formatting follows locale grouping and decimal symbols', () {
    final usd = CurrencyCatalog.byCode('USD');
    expect(usd.formatMinor(123456, localeCode: 'en'), r'$1,234.56');
    expect(usd.formatMinor(123456, localeCode: 'de'), r'$1.234,56');
    expect(usd.formatMinor(12345678, localeCode: 'hi'), r'$1,23,456.78');
    expect(usd.formatMinor(123456, localeCode: 'ms'), r'$1,234.56');
    expect(
      usd.formatMinor(123456, localeCode: 'lb'),
      r'$1.234,56',
      reason: 'Luxembourgish uses the documented German number fallback',
    );
  });

  test('selected currency is first, followed by global usage order', () {
    final supported = CurrencyCatalog.all
        .map((currency) => currency.code)
        .toSet();
    expect(CurrencyCatalog.globalUsageOrder.toSet(), supported);

    for (final selected in <String>['JPY', 'CZK', 'NGN', 'AED']) {
      final actual = CurrencyCatalog.displayOrder(
        selected,
      ).map((currency) => currency.code).toList();
      expect(actual.first, selected);
      expect(actual.toSet(), supported);
      expect(actual.length, supported.length);
    }
  });

  test(
    'selected currency stays first and favorites precede other currencies',
    () {
      final actual = CurrencyCatalog.displayOrder(
        'CZK',
        favoriteCodes: const <String>{'JPY', 'AED', 'USD', 'INVALID'},
      ).map((currency) => currency.code).toList(growable: false);

      expect(actual.take(4), <String>['CZK', 'USD', 'JPY', 'AED']);
      expect(actual.toSet(), CurrencyCatalog.globalUsageOrder.toSet());
      expect(actual.length, CurrencyCatalog.all.length);
    },
  );

  test('every coin has an exact mint weight', () {
    for (final currency in CurrencyCatalog.all) {
      for (final coin in currency.coins) {
        expect(
          coin.exactWeightMilligrams,
          isNotNull,
          reason: '${currency.code} ${coin.label}',
        );
      }
    }
  });

  test('banknote weights exist only with an approved official source', () {
    final banknotes = CurrencyCatalog.all
        .expand((currency) => currency.banknotes)
        .toList(growable: false);
    final weighted = banknotes
        .where((banknote) => banknote.exactWeightMilligrams != null)
        .toList(growable: false);

    expect(banknotes, hasLength(201));
    expect(weighted, hasLength(32));
    for (final banknote in weighted) {
      expect(
        BanknoteWeightSources.officialUris,
        contains(banknote.weightSourceId),
        reason: banknote.label,
      );
      expect(banknote.weightIsApproximate, isTrue, reason: banknote.label);
    }
  });

  test('audited issuer weights preserve denomination-specific differences', () {
    final eur = CurrencyCatalog.byCode('EUR');
    expect(
      eur.banknotes
          .map((banknote) => banknote.exactWeightMilligrams)
          .toList(growable: false),
      <int?>[600, 700, 800, 900, 1000, 1100, 1100],
    );

    final czk = CurrencyCatalog.byCode('CZK');
    expect(
      czk.banknotes
          .map((banknote) => banknote.exactWeightMilligrams)
          .toList(growable: false),
      <int?>[null, null, null, 1000, null, null],
    );
  });
}
