import 'dart:math';

import 'package:flutter/foundation.dart';

import 'currency_definition.dart';

@immutable
class CustomDenomination {
  const CustomDenomination({
    required this.id,
    required this.currencyCode,
    required this.minorUnits,
    required this.label,
    required this.kind,
  });

  static final Random _random = Random.secure();

  factory CustomDenomination.create({
    required String currencyCode,
    required int minorUnits,
    required String label,
    required DenominationKind kind,
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = _random.nextInt(0x100000000).toRadixString(36);
    return CustomDenomination(
      id: 'custom_${timestamp}_$entropy',
      currencyCode: currencyCode,
      minorUnits: minorUnits,
      label: label.trim(),
      kind: kind,
    );
  }

  factory CustomDenomination.fromJson(Map<String, Object?> json) {
    return CustomDenomination(
      id: json['id']! as String,
      currencyCode: json['currencyCode']! as String,
      minorUnits: (json['minorUnits']! as num).toInt(),
      label: json['label']! as String,
      kind: DenominationKind.values.byName(json['kind']! as String),
    );
  }

  final String id;
  final String currencyCode;
  final int minorUnits;
  final String label;
  final DenominationKind kind;

  Denomination toDenomination() => Denomination(
    customId: id,
    minorUnits: minorUnits,
    label: label,
    kind: kind,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'currencyCode': currencyCode,
    'minorUnits': minorUnits,
    'label': label,
    'kind': kind.name,
  };
}
