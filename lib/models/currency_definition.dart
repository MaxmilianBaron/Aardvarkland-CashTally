import 'package:flutter/foundation.dart';

import '../core/locale_formatting.dart';

enum DenominationKind { coin, banknote }

@immutable
class Denomination {
  const Denomination({
    required this.minorUnits,
    required this.label,
    required this.kind,
    this.customId,
    this.exactWeightMilligrams,
    this.weightSourceId,
    this.weightIsApproximate = false,
  }) : assert(
         kind != DenominationKind.banknote ||
             exactWeightMilligrams == null ||
             weightSourceId != null,
         'An official source is required for every banknote weight.',
       );

  final int minorUnits;
  final String label;
  final DenominationKind kind;
  final String? customId;

  /// Official mint weight for coins or issuer-published nominal banknote
  /// weight. A null value means that no suitable official banknote figure was
  /// found and the denomination must not contribute to a weight total.
  final int? exactWeightMilligrams;
  final String? weightSourceId;
  final bool weightIsApproximate;

  int? get calculationWeightMilligrams => exactWeightMilligrams;
  bool get hasOfficialWeight => exactWeightMilligrams != null;

  bool get isBanknote => kind == DenominationKind.banknote;

  String get id => customId ?? '${kind.name}_$minorUnits';

  Map<String, Object?> toSnapshotJson() => <String, Object?>{
    'id': id,
    'minorUnits': minorUnits,
    'label': label,
    'kind': kind.name,
  };

  factory Denomination.fromSnapshotJson(Map<String, Object?> json) {
    return Denomination(
      customId: json['id']! as String,
      minorUnits: (json['minorUnits']! as num).toInt(),
      label: json['label']! as String,
      kind: DenominationKind.values.byName(json['kind']! as String),
    );
  }
}

@immutable
class CurrencyDefinition {
  const CurrencyDefinition({
    required this.code,
    required this.name,
    required this.symbol,
    required this.symbolBefore,
    required this.denominations,
    this.fractionDigits = 2,
  });

  final String code;
  final String name;
  final String symbol;
  final bool symbolBefore;
  final List<Denomination> denominations;
  final int fractionDigits;

  int get minorUnitScale {
    var scale = 1;
    for (var index = 0; index < fractionDigits; index += 1) {
      scale *= 10;
    }
    return scale;
  }

  List<Denomination> get banknotes => denominations
      .where((denomination) => denomination.kind == DenominationKind.banknote)
      .toList(growable: false);

  List<Denomination> get coins => denominations
      .where((denomination) => denomination.kind == DenominationKind.coin)
      .toList(growable: false);

  Denomination? denominationById(String id) {
    for (final denomination in denominations) {
      if (denomination.id == id) {
        return denomination;
      }
    }
    return null;
  }

  Denomination? banknoteByMinorUnits(int minorUnits) {
    for (final denomination in banknotes) {
      if (denomination.minorUnits == minorUnits) {
        return denomination;
      }
    }
    return null;
  }

  CurrencyDefinition copyWithDenominations(
    List<Denomination> nextDenominations,
  ) {
    return CurrencyDefinition(
      code: code,
      name: name,
      symbol: symbol,
      symbolBefore: symbolBefore,
      denominations: List<Denomination>.unmodifiable(nextDenominations),
      fractionDigits: fractionDigits,
    );
  }

  String formatMinor(
    int minorUnits, {
    bool includeCode = false,
    String localeCode = 'cs',
  }) {
    final negative = minorUnits < 0;
    final absolute = minorUnits.abs();
    final scale = minorUnitScale;
    final whole = absolute ~/ scale;
    final fraction = absolute % scale;
    final formatter = localizedDecimalFormat(localeCode);
    final groupedWhole = formatter.format(whole);
    final decimalSeparator = formatter.symbols.DECIMAL_SEP;
    final amount = fractionDigits == 0 || fraction == 0
        ? groupedWhole
        : '$groupedWhole$decimalSeparator'
              '${fraction.toString().padLeft(fractionDigits, '0')}';
    final sign = negative ? '−' : '';
    final formatted = symbolBefore
        ? '$sign$symbol$amount'
        : '$sign$amount $symbol';
    return includeCode ? '$formatted $code' : formatted;
  }
}
