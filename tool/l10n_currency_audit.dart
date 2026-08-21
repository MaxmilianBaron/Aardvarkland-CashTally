import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:vycetka/data/country_catalog.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/l10n/app_localizations.dart';

void main(List<String> arguments) {
  final outputPath = arguments.isEmpty ? null : arguments.first;
  final english = const AppLocalizations(Locale('en'));
  final englishPlaceholders = <String, Set<String>>{
    for (final key in AppLocalizations.translationKeys)
      key: _placeholders(english.tr(key)),
  };
  final languageCodes =
      AppLocalizations.supportedLocales
          .map((locale) => locale.languageCode)
          .toSet()
          .toList(growable: false)
        ..sort();

  final languageRows = <Map<String, Object?>>[];
  for (final languageCode in languageCodes) {
    final l10n = AppLocalizations(Locale(languageCode));
    final placeholderErrors = <Map<String, Object?>>[];
    for (final key in AppLocalizations.translationKeys) {
      final expected = englishPlaceholders[key]!;
      final actual = _placeholders(l10n.tr(key));
      if (!_sameSet(expected, actual)) {
        placeholderErrors.add(<String, Object?>{
          'key': key,
          'expected': expected.toList()..sort(),
          'actual': actual.toList()..sort(),
        });
      }
    }
    final fallback = AppLocalizations.englishFallbackKeys(languageCode).toList()
      ..sort();
    final missingCore = AppLocalizations.missingCoreTranslationKeys(
      languageCode,
    ).toList()..sort();
    languageRows.add(<String, Object?>{
      'language': languageCode,
      'englishFallbackCount': fallback.length,
      'englishFallbackKeys': fallback,
      'missingCoreKeys': missingCore,
      'placeholderErrors': placeholderErrors,
      'translatedStrings': Map<String, String>.fromEntries(
        AppLocalizations.directTranslations(languageCode).entries.toList()
          ..sort((left, right) => left.key.compareTo(right.key)),
      ),
    });
  }

  final currencyRows = <Map<String, Object?>>[];
  for (final currency in CurrencyCatalog.all) {
    final issues = <String>[];
    final ids = currency.denominations.map((item) => item.id).toList();
    if (ids.toSet().length != ids.length) {
      issues.add('duplicate denomination IDs');
    }
    if (currency.banknotes.any((note) => note.minorUnits <= 0)) {
      issues.add('banknote with non-positive minor units');
    }
    if (currency.coins.any(
      (coin) =>
          coin.exactWeightMilligrams == null ||
          coin.exactWeightMilligrams! <= 0,
    )) {
      issues.add('coin without a positive exact weight');
    }
    for (final languageCode in languageCodes) {
      final formatted = currency.formatMinor(
        currency.minorUnitScale + (currency.fractionDigits == 0 ? 0 : 1),
        localeCode: languageCode,
      );
      if (formatted.isEmpty || !formatted.contains(currency.symbol)) {
        issues.add('invalid format for $languageCode: $formatted');
      }
    }
    currencyRows.add(<String, Object?>{
      'currency': currency.code,
      'banknotes': currency.banknotes.length,
      'coins': currency.coins.length,
      'issues': issues,
    });
  }

  final countryIssues = <String>[];
  final supportedLanguages = languageCodes.toSet();
  for (final country in CountryCatalog.all) {
    if (!supportedLanguages.contains(country.locale.languageCode)) {
      countryIssues.add('${country.id}: unsupported locale ${country.locale}');
    }
    if (!CurrencyCatalog.containsCode(country.currencyCode)) {
      countryIssues.add('${country.id}: unsupported ${country.currencyCode}');
    }
  }

  final payload = const JsonEncoder.withIndent('  ').convert(<String, Object?>{
    'schemaVersion': 1,
    'languageCount': languageCodes.length,
    'currencyCount': CurrencyCatalog.all.length,
    'countryCount': CountryCatalog.all.length,
    'languages': languageRows,
    'currencies': currencyRows,
    'countryIssues': countryIssues,
  });
  if (outputPath == null) {
    stdout.writeln(payload);
  } else {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('$payload\n');
  }
}

Set<String> _placeholders(String value) => RegExp(
  r'\{([A-Za-z][A-Za-z0-9_]*)\}',
).allMatches(value).map((match) => match.group(1)!).toSet();

bool _sameSet(Set<String> left, Set<String> right) =>
    left.length == right.length && left.containsAll(right);
