import '../models/currency_definition.dart';
import 'additional_currency_catalog.dart';
import 'banknote_weight_sources.dart';
import 'world_currency_catalog.dart';

abstract final class CurrencyCatalog {
  /// 2025 BIS global FX turnover order, limited to supported currencies.
  static const List<String> globalUsageOrder = <String>[
    'USD',
    'EUR',
    'JPY',
    'GBP',
    'CHF',
    'AUD',
    'CAD',
    'KRW',
    'INR',
    'MXN',
    'SEK',
    'NOK',
    'BRL',
    'ZAR',
    'PLN',
    'DKK',
    'TRY',
    'CZK',
    'ILS',
    'HUF',
    'SAR',
    'AED',
    'RUB',
    'THB',
    'MYR',
    'IDR',
    'PKR',
    'NGN',
    'EGP',
    'DZD',
    'ARS',
    'UAH',
  ];

  static final List<CurrencyDefinition> all = <CurrencyDefinition>[
    _czk,
    _eur,
    _usd,
    _gbp,
    _chf,
    _cad,
    _aud,
    _jpy,
    _krw,
    ...AdditionalCurrencyCatalog.all,
    ...WorldCurrencyCatalog.all,
  ];

  static CurrencyDefinition byCode(String code) {
    return all.firstWhere(
      (currency) => currency.code == code,
      orElse: () => _czk,
    );
  }

  static bool containsCode(String? code) =>
      code != null && all.any((currency) => currency.code == code);

  static List<CurrencyDefinition> displayOrder(
    String selectedCode, {
    Set<String> favoriteCodes = const <String>{},
    List<String>? favoriteOrder,
  }) {
    final ordered = globalUsageOrder.map(byCode).toList(growable: false);
    final priority = favoriteOrder ?? <String>[];
    final favoriteCodeOrder = <String>[];
    final seenFavorites = <String>{};
    for (final code in <String>[...priority, ...globalUsageOrder]) {
      if (favoriteCodes.contains(code) && seenFavorites.add(code)) {
        favoriteCodeOrder.add(code);
      }
    }
    final favorites = favoriteCodeOrder
        .where((code) => code != selectedCode)
        .map(byCode);
    return <CurrencyDefinition>[
      if (containsCode(selectedCode)) byCode(selectedCode),
      ...favorites,
      ...ordered.where(
        (currency) =>
            currency.code != selectedCode &&
            !favoriteCodes.contains(currency.code),
      ),
    ];
  }

  static final CurrencyDefinition _czk = CurrencyDefinition(
    code: 'CZK',
    name: 'Česká koruna',
    symbol: 'Kč',
    symbolBefore: false,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 100,
        label: '1 Kč',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3600,
      ),
      Denomination(
        minorUnits: 200,
        label: '2 Kč',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3700,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 Kč',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4800,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 Kč',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7620,
      ),
      Denomination(
        minorUnits: 2000,
        label: '20 Kč',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8430,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 Kč',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9700,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 Kč',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 Kč',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '500 Kč',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '1 000 Kč',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.czkCnbBundle,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 200000,
        label: '2 000 Kč',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 500000,
        label: '5 000 Kč',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _eur = CurrencyDefinition(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1 cent',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2300,
      ),
      Denomination(
        minorUnits: 2,
        label: '2 centy',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3060,
      ),
      Denomination(
        minorUnits: 5,
        label: '5 centů',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3920,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 centů',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4100,
      ),
      Denomination(
        minorUnits: 20,
        label: '20 centů',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5740,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 centů',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7800,
      ),
      Denomination(
        minorUnits: 100,
        label: '€1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7500,
      ),
      Denomination(
        minorUnits: 200,
        label: '€2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8500,
      ),
      Denomination(
        minorUnits: 500,
        label: '€5',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 600,
        weightSourceId: BanknoteWeightSources.euroOenb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 1000,
        label: '€10',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 700,
        weightSourceId: BanknoteWeightSources.euroOenb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 2000,
        label: '€20',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 800,
        weightSourceId: BanknoteWeightSources.euroOenb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 5000,
        label: '€50',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 900,
        weightSourceId: BanknoteWeightSources.euroOenb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 10000,
        label: '€100',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.euroOenb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 20000,
        label: '€200',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1100,
        weightSourceId: BanknoteWeightSources.euroOenb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 50000,
        label: '€500',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1100,
        weightSourceId: BanknoteWeightSources.euroOenb,
        weightIsApproximate: true,
      ),
    ],
  );

  static final CurrencyDefinition _usd = CurrencyDefinition(
    code: 'USD',
    name: 'Americký dolar',
    symbol: r'$',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2500,
      ),
      Denomination(
        minorUnits: 5,
        label: '5¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5000,
      ),
      Denomination(
        minorUnits: 10,
        label: '10¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2268,
      ),
      Denomination(
        minorUnits: 25,
        label: '25¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5670,
      ),
      Denomination(
        minorUnits: 50,
        label: '50¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 11340,
      ),
      Denomination(
        minorUnits: 100,
        label: r'$1 coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8100,
      ),
      Denomination(
        minorUnits: 100,
        label: r'$1',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.usdCurrencyEducation,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 200,
        label: r'$2',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.usdCurrencyEducation,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 500,
        label: r'$5',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.usdCurrencyEducation,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 1000,
        label: r'$10',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.usdCurrencyEducation,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 2000,
        label: r'$20',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.usdCurrencyEducation,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 5000,
        label: r'$50',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.usdCurrencyEducation,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 10000,
        label: r'$100',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.usdCurrencyEducation,
        weightIsApproximate: true,
      ),
    ],
  );

  static final CurrencyDefinition _gbp = CurrencyDefinition(
    code: 'GBP',
    name: 'Britská libra',
    symbol: '£',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1p',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3560,
      ),
      Denomination(
        minorUnits: 2,
        label: '2p',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7120,
      ),
      Denomination(
        minorUnits: 5,
        label: '5p',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3250,
      ),
      Denomination(
        minorUnits: 10,
        label: '10p',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6500,
      ),
      Denomination(
        minorUnits: 20,
        label: '20p',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5000,
      ),
      Denomination(
        minorUnits: 50,
        label: '50p',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8000,
      ),
      Denomination(
        minorUnits: 100,
        label: '£1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8750,
      ),
      Denomination(
        minorUnits: 200,
        label: '£2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 12000,
      ),
      Denomination(
        minorUnits: 500,
        label: '£5',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 700,
        weightSourceId: BanknoteWeightSources.gbpBankOfEngland,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 1000,
        label: '£10',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 850,
        weightSourceId: BanknoteWeightSources.gbpBankOfEngland,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 2000,
        label: '£20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '£50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '£100',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _chf = CurrencyDefinition(
    code: 'CHF',
    name: 'Švýcarský frank',
    symbol: 'CHF ',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 5,
        label: '5 rp.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1800,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 rp.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3000,
      ),
      Denomination(
        minorUnits: 20,
        label: '20 rp.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4000,
      ),
      Denomination(
        minorUnits: 50,
        label: '½ CHF',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2200,
      ),
      Denomination(
        minorUnits: 100,
        label: '1 CHF',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4400,
      ),
      Denomination(
        minorUnits: 200,
        label: '2 CHF',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8800,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 CHF',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 13200,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 CHF',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: '20 CHF',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 CHF',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 CHF',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 CHF',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '1 000 CHF',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _cad = CurrencyDefinition(
    code: 'CAD',
    name: 'Kanadský dolar',
    symbol: r'C$',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1¢ (legacy)',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2350,
      ),
      Denomination(
        minorUnits: 5,
        label: '5¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3950,
      ),
      Denomination(
        minorUnits: 10,
        label: '10¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1750,
      ),
      Denomination(
        minorUnits: 25,
        label: '25¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4400,
      ),
      Denomination(
        minorUnits: 50,
        label: '50¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6900,
      ),
      Denomination(
        minorUnits: 100,
        label: r'C$1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6270,
      ),
      Denomination(
        minorUnits: 200,
        label: r'C$2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6920,
      ),
      Denomination(
        minorUnits: 500,
        label: r'C$5',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 930,
        weightSourceId: BanknoteWeightSources.cadBankOfCanadaBundle,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 1000,
        label: r'C$10',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 930,
        weightSourceId: BanknoteWeightSources.cadBankOfCanadaBundle,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 2000,
        label: r'C$20',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 930,
        weightSourceId: BanknoteWeightSources.cadBankOfCanadaBundle,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 5000,
        label: r'C$50',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 930,
        weightSourceId: BanknoteWeightSources.cadBankOfCanadaBundle,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 10000,
        label: r'C$100',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 930,
        weightSourceId: BanknoteWeightSources.cadBankOfCanadaBundle,
        weightIsApproximate: true,
      ),
    ],
  );

  static final CurrencyDefinition _aud = CurrencyDefinition(
    code: 'AUD',
    name: 'Australský dolar',
    symbol: r'A$',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 5,
        label: '5¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2830,
      ),
      Denomination(
        minorUnits: 10,
        label: '10¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6650,
      ),
      Denomination(
        minorUnits: 20,
        label: '20¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 11300,
      ),
      Denomination(
        minorUnits: 50,
        label: '50¢',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 15550,
      ),
      Denomination(
        minorUnits: 100,
        label: r'A$1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9000,
      ),
      Denomination(
        minorUnits: 200,
        label: r'A$2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6600,
      ),
      Denomination(
        minorUnits: 500,
        label: r'A$5',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: r'A$10',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: r'A$20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: r'A$50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: r'A$100',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _jpy = CurrencyDefinition(
    code: 'JPY',
    name: 'Japonský jen',
    symbol: '¥',
    symbolBefore: true,
    fractionDigits: 0,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '¥1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1000,
      ),
      Denomination(
        minorUnits: 5,
        label: '¥5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3750,
      ),
      Denomination(
        minorUnits: 10,
        label: '¥10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4500,
      ),
      Denomination(
        minorUnits: 50,
        label: '¥50',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4000,
      ),
      Denomination(
        minorUnits: 100,
        label: '¥100',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4800,
      ),
      Denomination(
        minorUnits: 500,
        label: '¥500',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7100,
      ),
      Denomination(
        minorUnits: 1000,
        label: '¥1 000',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.jpyBankOfJapan,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 2000,
        label: '¥2 000',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.jpyBankOfJapan,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 5000,
        label: '¥5 000',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.jpyBankOfJapan,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 10000,
        label: '¥10 000',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.jpyBankOfJapan,
        weightIsApproximate: true,
      ),
    ],
  );

  static final CurrencyDefinition _krw = CurrencyDefinition(
    code: 'KRW',
    name: 'Jihokorejský won',
    symbol: '₩',
    symbolBefore: true,
    fractionDigits: 0,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '₩1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 729,
      ),
      Denomination(
        minorUnits: 5,
        label: '₩5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2950,
      ),
      Denomination(
        minorUnits: 10,
        label: '₩10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1220,
      ),
      Denomination(
        minorUnits: 50,
        label: '₩50',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4160,
      ),
      Denomination(
        minorUnits: 100,
        label: '₩100',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5420,
      ),
      Denomination(
        minorUnits: 500,
        label: '₩500',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7700,
      ),
      Denomination(
        minorUnits: 1000,
        label: '₩1 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '₩5 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '₩10 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '₩50 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );
}
