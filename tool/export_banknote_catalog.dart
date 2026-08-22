import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/l10n/app_localizations.dart';

void main(List<String> arguments) {
  final outputPath = arguments.isEmpty ? null : arguments.first;
  final english = const AppLocalizations(Locale('en'));
  final records = <Map<String, Object?>>[];

  for (final currency in CurrencyCatalog.all) {
    for (final banknote in currency.banknotes) {
      records.add(<String, Object?>{
        'currency': currency.code,
        'currencyName': english.tr('currency${currency.code}'),
        'minorUnits': banknote.minorUnits,
        'fractionDigits': currency.fractionDigits,
        'value': _decimalValue(
          banknote.minorUnits,
          currency.minorUnitScale,
          currency.fractionDigits,
        ),
        'label': banknote.label,
        'weightMilligrams': banknote.calculationWeightMilligrams,
        'weightSourceId': banknote.weightSourceId,
        'weightIsApproximate': banknote.weightIsApproximate,
      });
    }
  }

  final payload = const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'schemaVersion': 1,
    'banknoteCount': records.length,
    'banknotes': records,
  });
  if (outputPath == null) {
    stdout.writeln(payload);
  } else {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('$payload\n');
  }
}

String _decimalValue(int minorUnits, int scale, int fractionDigits) {
  final whole = minorUnits ~/ scale;
  final fraction = minorUnits % scale;
  if (fractionDigits == 0 || fraction == 0) {
    return '$whole';
  }
  return '$whole.${fraction.toString().padLeft(fractionDigits, '0')}';
}
