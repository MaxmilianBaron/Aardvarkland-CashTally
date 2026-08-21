import '../models/currency_definition.dart';
import 'banknote_weight_sources.dart';

abstract final class AdditionalCurrencyCatalog {
  static final List<CurrencyDefinition> all = <CurrencyDefinition>[
    _sek,
    _nok,
    _uah,
    _rub,
    _dkk,
    _huf,
    _pln,
    _brl,
    _ars,
    _try,
    _mxn,
  ];

  static final CurrencyDefinition _sek = CurrencyDefinition(
    code: 'SEK',
    name: 'Švédská koruna',
    symbol: 'kr',
    symbolBefore: false,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 100,
        label: '1 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3600,
      ),
      Denomination(
        minorUnits: 200,
        label: '2 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4800,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6100,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6600,
      ),
      Denomination(
        minorUnits: 2000,
        label: '20 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '500 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '1 000 kr',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _nok = CurrencyDefinition(
    code: 'NOK',
    name: 'Norská koruna',
    symbol: 'kr',
    symbolBefore: false,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 100,
        label: '1 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4350,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7850,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6800,
      ),
      Denomination(
        minorUnits: 2000,
        label: '20 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9900,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '500 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '1 000 kr',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _uah = CurrencyDefinition(
    code: 'UAH',
    name: 'Ukrajinská hřivna',
    symbol: '₴',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 10,
        label: '10 коп.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1700,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 коп.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4200,
      ),
      Denomination(
        minorUnits: 100,
        label: '₴1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3300,
      ),
      Denomination(
        minorUnits: 200,
        label: '₴2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4000,
      ),
      Denomination(
        minorUnits: 500,
        label: '₴5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5200,
      ),
      Denomination(
        minorUnits: 1000,
        label: '₴10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6400,
      ),
      Denomination(
        minorUnits: 2000,
        label: '₴20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '₴50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '₴100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '₴200',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '₴500',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '₴1 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _rub = CurrencyDefinition(
    code: 'RUB',
    name: 'Ruský rubl',
    symbol: '₽',
    symbolBefore: false,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1 коп.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1500,
      ),
      Denomination(
        minorUnits: 5,
        label: '5 коп.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2600,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 коп.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1850,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 коп.',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2750,
      ),
      Denomination(
        minorUnits: 100,
        label: '1 ₽',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3000,
      ),
      Denomination(
        minorUnits: 200,
        label: '2 ₽',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5000,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 ₽ coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6000,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 ₽ coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5630,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 ₽',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 ₽',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 ₽',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 ₽',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 ₽',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '500 ₽',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '1 000 ₽',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 200000,
        label: '2 000 ₽',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 500000,
        label: '5 000 ₽',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _dkk = CurrencyDefinition(
    code: 'DKK',
    name: 'Dánská koruna',
    symbol: 'kr',
    symbolBefore: false,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 50,
        label: '50 øre',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4300,
      ),
      Denomination(
        minorUnits: 100,
        label: '1 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3600,
      ),
      Denomination(
        minorUnits: 200,
        label: '2 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5900,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9200,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7000,
      ),
      Denomination(
        minorUnits: 2000,
        label: '20 kr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9300,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 kr',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '500 kr',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _huf = CurrencyDefinition(
    code: 'HUF',
    name: 'Maďarský forint',
    symbol: 'Ft',
    symbolBefore: false,
    fractionDigits: 0,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 5,
        label: '5 Ft',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4200,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 Ft',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6100,
      ),
      Denomination(
        minorUnits: 20,
        label: '20 Ft',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6900,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 Ft',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7700,
      ),
      Denomination(
        minorUnits: 100,
        label: '100 Ft',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8000,
      ),
      Denomination(
        minorUnits: 200,
        label: '200 Ft',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9000,
      ),
      Denomination(
        minorUnits: 500,
        label: '500 Ft',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.hufMnb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 1000,
        label: '1 000 Ft',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.hufMnb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 2000,
        label: '2 000 Ft',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.hufMnb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 5000,
        label: '5 000 Ft',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.hufMnb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 10000,
        label: '10 000 Ft',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.hufMnb,
        weightIsApproximate: true,
      ),
      Denomination(
        minorUnits: 20000,
        label: '20 000 Ft',
        kind: DenominationKind.banknote,
        exactWeightMilligrams: 1000,
        weightSourceId: BanknoteWeightSources.hufMnb,
        weightIsApproximate: true,
      ),
    ],
  );

  static final CurrencyDefinition _pln = CurrencyDefinition(
    code: 'PLN',
    name: 'Polský zlotý',
    symbol: 'zł',
    symbolBefore: false,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1 gr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1640,
      ),
      Denomination(
        minorUnits: 2,
        label: '2 gr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2130,
      ),
      Denomination(
        minorUnits: 5,
        label: '5 gr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2590,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 gr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2510,
      ),
      Denomination(
        minorUnits: 20,
        label: '20 gr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3220,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 gr',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3940,
      ),
      Denomination(
        minorUnits: 100,
        label: '1 zł',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5000,
      ),
      Denomination(
        minorUnits: 200,
        label: '2 zł',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5210,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 zł',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6540,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 zł',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: '20 zł',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 zł',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 zł',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 zł',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '500 zł',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _brl = CurrencyDefinition(
    code: 'BRL',
    name: 'Brazilský real',
    symbol: r'R$',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 5,
        label: '5 centavos',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4100,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 centavos',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4800,
      ),
      Denomination(
        minorUnits: 25,
        label: '25 centavos',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7550,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 centavos',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7810,
      ),
      Denomination(
        minorUnits: 100,
        label: r'R$1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7000,
      ),
      Denomination(
        minorUnits: 200,
        label: r'R$2',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 500,
        label: r'R$5',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: r'R$10',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: r'R$20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: r'R$50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: r'R$100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: r'R$200',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _ars = CurrencyDefinition(
    code: 'ARS',
    name: 'Argentinské peso',
    symbol: r'AR$',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 100,
        label: r'AR$1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4350,
      ),
      Denomination(
        minorUnits: 200,
        label: r'AR$2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5000,
      ),
      Denomination(
        minorUnits: 500,
        label: r'AR$5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6650,
      ),
      Denomination(
        minorUnits: 1000,
        label: r'AR$10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9250,
      ),
      Denomination(
        minorUnits: 1000,
        label: r'AR$10 note',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: r'AR$20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: r'AR$50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: r'AR$100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: r'AR$200',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: r'AR$500',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: r'AR$1 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 200000,
        label: r'AR$2 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000000,
        label: r'AR$10 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000000,
        label: r'AR$20 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _try = CurrencyDefinition(
    code: 'TRY',
    name: 'Turecká lira',
    symbol: '₺',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1 kuruş',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2700,
      ),
      Denomination(
        minorUnits: 5,
        label: '5 kuruş',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2900,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 kuruş',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3150,
      ),
      Denomination(
        minorUnits: 25,
        label: '25 kuruş',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4000,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 kuruş',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6800,
      ),
      Denomination(
        minorUnits: 100,
        label: '₺1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8200,
      ),
      Denomination(
        minorUnits: 500,
        label: '₺5 coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8250,
      ),
      Denomination(
        minorUnits: 500,
        label: '₺5',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: '₺10',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: '₺20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '₺50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '₺100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '₺200',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _mxn = CurrencyDefinition(
    code: 'MXN',
    name: 'Mexické peso',
    symbol: r'MX$',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 5,
        label: '5 centavos',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1580,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 centavos',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1755,
      ),
      Denomination(
        minorUnits: 20,
        label: '20 centavos',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2258,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 centavos',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3103,
      ),
      Denomination(
        minorUnits: 100,
        label: r'MX$1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3950,
      ),
      Denomination(
        minorUnits: 200,
        label: r'MX$2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5190,
      ),
      Denomination(
        minorUnits: 500,
        label: r'MX$5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7070,
      ),
      Denomination(
        minorUnits: 1000,
        label: r'MX$10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 10329,
      ),
      Denomination(
        minorUnits: 2000,
        label: r'MX$20 coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 12670,
      ),
      Denomination(
        minorUnits: 2000,
        label: r'MX$20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: r'MX$50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: r'MX$100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: r'MX$200',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: r'MX$500',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: r'MX$1 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );
}
