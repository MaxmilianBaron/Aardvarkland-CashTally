import '../models/currency_definition.dart';

/// Currency definitions for Asia, Africa and the Middle East. Values are
/// stored in ISO minor units; zero-decimal currencies use whole units.
abstract final class WorldCurrencyCatalog {
  static final List<CurrencyDefinition> all = <CurrencyDefinition>[
    _inr,
    _idr,
    _pkr,
    _myr,
    _thb,
    _ngn,
    _zar,
    _dzd,
    _egp,
    _ils,
    _sar,
    _aed,
  ];

  static final CurrencyDefinition _inr = CurrencyDefinition(
    code: 'INR',
    name: 'Indická rupie',
    symbol: '₹',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 50,
        label: '50 paise',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3790,
      ),
      Denomination(
        minorUnits: 100,
        label: '₹1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3090,
      ),
      Denomination(
        minorUnits: 200,
        label: '₹2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4070,
      ),
      Denomination(
        minorUnits: 500,
        label: '₹5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6740,
      ),
      Denomination(
        minorUnits: 1000,
        label: '₹10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7740,
      ),
      Denomination(
        minorUnits: 2000,
        label: '₹20',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8540,
      ),
      Denomination(
        minorUnits: 100,
        label: '₹1 note',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: '₹10 note',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: '₹20 note',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '₹50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '₹100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '₹200',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '₹500',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 200000,
        label: '₹2 000 (legal tender)',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _idr = CurrencyDefinition(
    code: 'IDR',
    name: 'Indonéská rupie',
    symbol: 'Rp',
    symbolBefore: true,
    fractionDigits: 0,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 100,
        label: 'Rp100',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1790,
      ),
      Denomination(
        minorUnits: 200,
        label: 'Rp200',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2380,
      ),
      Denomination(
        minorUnits: 500,
        label: 'Rp500',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3100,
      ),
      Denomination(
        minorUnits: 1000,
        label: 'Rp1 000 coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4500,
      ),
      Denomination(
        minorUnits: 1000,
        label: 'Rp1 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: 'Rp2 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: 'Rp5 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: 'Rp10 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: 'Rp20 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: 'Rp50 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: 'Rp100 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _pkr = CurrencyDefinition(
    code: 'PKR',
    name: 'Pákistánská rupie',
    symbol: 'Rs',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 100,
        label: 'Rs1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2500,
      ),
      Denomination(
        minorUnits: 200,
        label: 'Rs2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2600,
      ),
      Denomination(
        minorUnits: 500,
        label: 'Rs5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3000,
      ),
      Denomination(
        minorUnits: 1000,
        label: 'Rs10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5500,
      ),
      Denomination(
        minorUnits: 1000,
        label: 'Rs10 note',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: 'Rs20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: 'Rs50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 7500,
        label: 'Rs75',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: 'Rs100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: 'Rs500',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: 'Rs1 000',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 500000,
        label: 'Rs5 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _myr = CurrencyDefinition(
    code: 'MYR',
    name: 'Malajsijský ringgit',
    symbol: 'RM',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 5,
        label: '5 sen',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1720,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 sen',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2980,
      ),
      Denomination(
        minorUnits: 20,
        label: '20 sen',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4180,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 sen',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5660,
      ),
      Denomination(
        minorUnits: 100,
        label: 'RM1',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 500,
        label: 'RM5',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: 'RM10',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: 'RM20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: 'RM50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: 'RM100',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _thb = CurrencyDefinition(
    code: 'THB',
    name: 'Thajský baht',
    symbol: '฿',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 25,
        label: '25 satang',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1900,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 satang',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2400,
      ),
      Denomination(
        minorUnits: 100,
        label: '฿1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3000,
      ),
      Denomination(
        minorUnits: 200,
        label: '฿2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4000,
      ),
      Denomination(
        minorUnits: 500,
        label: '฿5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6000,
      ),
      Denomination(
        minorUnits: 1000,
        label: '฿10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8500,
      ),
      Denomination(
        minorUnits: 2000,
        label: '฿20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '฿50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '฿100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '฿500',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '฿1 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _ngn = CurrencyDefinition(
    code: 'NGN',
    name: 'Nigerijská naira',
    symbol: '₦',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 50,
        label: '50 kobo',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5500,
      ),
      Denomination(
        minorUnits: 100,
        label: '₦1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4300,
      ),
      Denomination(
        minorUnits: 200,
        label: '₦2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5100,
      ),
      Denomination(
        minorUnits: 500,
        label: '₦5',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: '₦10',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: '₦20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '₦50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '₦100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '₦200',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '₦500',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '₦1 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _zar = CurrencyDefinition(
    code: 'ZAR',
    name: 'Jihoafrický rand',
    symbol: 'R',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 10,
        label: '10c',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2000,
      ),
      Denomination(
        minorUnits: 20,
        label: '20c',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3500,
      ),
      Denomination(
        minorUnits: 50,
        label: '50c',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5000,
      ),
      Denomination(
        minorUnits: 100,
        label: 'R1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4000,
      ),
      Denomination(
        minorUnits: 200,
        label: 'R2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5500,
      ),
      Denomination(
        minorUnits: 500,
        label: 'R5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9500,
      ),
      Denomination(
        minorUnits: 1000,
        label: 'R10',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: 'R20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: 'R50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: 'R100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: 'R200',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _dzd = CurrencyDefinition(
    code: 'DZD',
    name: 'Alžírský dinár',
    symbol: 'د.ج',
    symbolBefore: false,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 100,
        label: '1 DA',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4200,
      ),
      Denomination(
        minorUnits: 200,
        label: '2 DA',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5100,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 DA',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6150,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 DA',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4950,
      ),
      Denomination(
        minorUnits: 2000,
        label: '20 DA',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8620,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 DA',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 9270,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 DA coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 11000,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 DA coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 12000,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 DA',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 DA',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '500 DA',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: '1 000 DA',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 200000,
        label: '2 000 DA',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _egp = CurrencyDefinition(
    code: 'EGP',
    name: 'Egyptská libra',
    symbol: 'E£',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 25,
        label: '25 piastres',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5200,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 piastres',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6500,
      ),
      Denomination(
        minorUnits: 100,
        label: 'E£1 coin',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8500,
      ),
      Denomination(
        minorUnits: 25,
        label: '25 piastres note',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 piastres note',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100,
        label: 'E£1',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 500,
        label: 'E£5',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: 'E£10',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: 'E£20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: 'E£50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: 'E£100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: 'E£200',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _ils = CurrencyDefinition(
    code: 'ILS',
    name: 'Izraelský nový šekel',
    symbol: '₪',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 10,
        label: '10 agorot',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4000,
      ),
      Denomination(
        minorUnits: 50,
        label: '₪0.50',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6500,
      ),
      Denomination(
        minorUnits: 100,
        label: '₪1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3500,
      ),
      Denomination(
        minorUnits: 200,
        label: '₪2',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 5700,
      ),
      Denomination(
        minorUnits: 500,
        label: '₪5',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 8200,
      ),
      Denomination(
        minorUnits: 1000,
        label: '₪10',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 7000,
      ),
      Denomination(
        minorUnits: 2000,
        label: '₪20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '₪50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '₪100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '₪200',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _sar = CurrencyDefinition(
    code: 'SAR',
    name: 'Saúdský rijál',
    symbol: 'ر.س',
    symbolBefore: false,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1 halala',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2350,
      ),
      Denomination(
        minorUnits: 5,
        label: '5 halalas',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2400,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 halalas',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 2850,
      ),
      Denomination(
        minorUnits: 25,
        label: '25 halalas',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3800,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 halalas',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4500,
      ),
      Denomination(
        minorUnits: 100,
        label: '1 SAR',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6100,
      ),
      Denomination(
        minorUnits: 200,
        label: '2 SAR',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6100,
      ),
      Denomination(
        minorUnits: 100,
        label: '1 SAR',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 500,
        label: '5 SAR',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: '10 SAR',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: '20 SAR',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: '50 SAR',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: '100 SAR',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: '200 SAR',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: '500 SAR',
        kind: DenominationKind.banknote,
      ),
    ],
  );

  static final CurrencyDefinition _aed = CurrencyDefinition(
    code: 'AED',
    name: 'Dirham SAE',
    symbol: 'AED ',
    symbolBefore: true,
    denominations: const <Denomination>[
      Denomination(
        minorUnits: 1,
        label: '1 fils',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1500,
      ),
      Denomination(
        minorUnits: 5,
        label: '5 fils',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 1750,
      ),
      Denomination(
        minorUnits: 10,
        label: '10 fils',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3000,
      ),
      Denomination(
        minorUnits: 25,
        label: '25 fils',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 3500,
      ),
      Denomination(
        minorUnits: 50,
        label: '50 fils',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 4500,
      ),
      Denomination(
        minorUnits: 100,
        label: 'AED 1',
        kind: DenominationKind.coin,
        exactWeightMilligrams: 6100,
      ),
      Denomination(
        minorUnits: 500,
        label: 'AED 5',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 1000,
        label: 'AED 10',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 2000,
        label: 'AED 20',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 5000,
        label: 'AED 50',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 10000,
        label: 'AED 100',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 20000,
        label: 'AED 200',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 50000,
        label: 'AED 500',
        kind: DenominationKind.banknote,
      ),
      Denomination(
        minorUnits: 100000,
        label: 'AED 1 000',
        kind: DenominationKind.banknote,
      ),
    ],
  );
}
