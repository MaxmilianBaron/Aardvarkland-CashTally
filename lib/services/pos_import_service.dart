import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../core/formatters.dart';
import '../data/currency_catalog.dart';
import '../models/pos_reconciliation.dart';

/// Parses common POS/EFTPOS exports without uploading the report anywhere.
///
/// The importer deliberately requires an explicit expected-cash value. A
/// gross sales total or a card total alone must never silently become the cash
/// amount used for reconciliation.
class PosImportService {
  const PosImportService();

  PosReconciliation parse({
    required List<int> bytes,
    required String sourceFileName,
  }) {
    if (bytes.isEmpty) {
      throw const PosImportException('emptyFile');
    }
    final text = utf8.decode(bytes, allowMalformed: true);
    final rows = _parseCsv(text);
    if (rows.isEmpty) {
      throw const PosImportException('emptyFile');
    }

    final values = _extractValues(rows);
    final currencyCode = _value(values, _currencyKeys)?.toUpperCase();
    if (currencyCode == null || !CurrencyCatalog.containsCode(currencyCode)) {
      throw const PosImportException('currencyMissing');
    }
    final currency = CurrencyCatalog.byCode(currencyCode);
    final expected = _amount(
      values,
      _expectedCashKeys,
      fractionDigits: currency.fractionDigits,
    );
    if (expected == null) {
      throw const PosImportException('expectedCashMissing');
    }
    final card = _amount(
      values,
      _cardKeys,
      fractionDigits: currency.fractionDigits,
    );
    final total = _amount(
      values,
      _totalSalesKeys,
      fractionDigits: currency.fractionDigits,
    );
    final sourceSha256 = _sha256(bytes);
    final reportId = _value(values, _idKeys)?.trim();
    final reportAt = _date(_value(values, _dateKeys));

    return PosReconciliation(
      id: reportId == null || reportId.isEmpty
          ? 'POS-${sourceSha256.substring(0, 16).toUpperCase()}'
          : reportId,
      sourceFileName: sourceFileName.trim(),
      currencyCode: currencyCode,
      importedAt: DateTime.now(),
      sourceSha256: sourceSha256,
      expectedCashMinorUnits: expected,
      cardMinorUnits: card,
      totalSalesMinorUnits: total,
      tillName: _value(values, _tillKeys)?.trim() ?? '',
      cashierName: _value(values, _cashierKeys)?.trim() ?? '',
      reportAt: reportAt,
    );
  }

  static const Set<String> _currencyKeys = <String>{
    'currency',
    'currencycode',
    'code',
    'mena',
  };
  static const Set<String> _expectedCashKeys = <String>{
    'expectedcash',
    'cashexpected',
    'cashdrawerexpected',
    'cashinregister',
    'cashintill',
    'cash',
    'cashamount',
    'cashtotal',
    'cashdrawer',
    'ocekavanahotovost',
    'hotovost',
  };
  static const Set<String> _cardKeys = <String>{
    'card',
    'cards',
    'cardtotal',
    'eftpos',
    'cardpayments',
    'karty',
  };
  static const Set<String> _totalSalesKeys = <String>{
    'total',
    'totalsales',
    'gross',
    'grosssales',
    'sales',
    'trzby',
  };
  static const Set<String> _idKeys = <String>{
    'id',
    'document',
    'documentnumber',
    'report',
    'reportid',
    'zreport',
    'zaverka',
    'cislozaverky',
    'cislouzaverky',
  };
  static const Set<String> _dateKeys = <String>{
    'date',
    'datetime',
    'reportat',
    'timestamp',
    'datum',
  };
  static const Set<String> _tillKeys = <String>{
    'till',
    'tillname',
    'register',
    'registername',
    'pokladna',
  };
  static const Set<String> _cashierKeys = <String>{
    'cashier',
    'cashiername',
    'operator',
    'obsluha',
  };

  static List<List<String>> _parseCsv(String source) {
    var text = source.replaceFirst('\uFEFF', '');
    final firstLineEnd = text.indexOf(RegExp(r'[\r\n]'));
    final firstLine = firstLineEnd < 0 ? text : text.substring(0, firstLineEnd);
    final separator = firstLine.contains(';') ? ';' : ',';
    if (firstLine.trim().toLowerCase().startsWith('sep=')) {
      final declared = firstLine.trim().substring(4, 5);
      if (declared == ';' || declared == ',') {
        text = text.substring(
          firstLineEnd < 0 ? text.length : firstLineEnd + 1,
        );
        return _scanRows(text, declared);
      }
    }
    return _scanRows(text, separator);
  }

  static List<List<String>> _scanRows(String source, String separator) {
    final rows = <List<String>>[];
    var row = <String>[];
    var cell = StringBuffer();
    var quoted = false;
    for (var index = 0; index < source.length; index += 1) {
      final character = source[index];
      if (character == '"') {
        if (quoted && index + 1 < source.length && source[index + 1] == '"') {
          cell.write('"');
          index += 1;
        } else {
          quoted = !quoted;
        }
      } else if (!quoted && character == separator) {
        row.add(cell.toString().trim());
        cell = StringBuffer();
      } else if (!quoted && (character == '\n' || character == '\r')) {
        if (character == '\r' &&
            index + 1 < source.length &&
            source[index + 1] == '\n') {
          index += 1;
        }
        row.add(cell.toString().trim());
        cell = StringBuffer();
        if (row.any((value) => value.isNotEmpty)) {
          rows.add(row);
        }
        row = <String>[];
      } else {
        cell.write(character);
      }
    }
    row.add(cell.toString().trim());
    if (row.any((value) => value.isNotEmpty)) {
      rows.add(row);
    }
    return rows;
  }

  static Map<String, String> _extractValues(List<List<String>> rows) {
    final values = <String, String>{};
    if (rows.isEmpty) {
      return values;
    }
    final first = rows.first;
    final knownHeaders = first.map(_normalize).where(_isKnownKey).length;
    final firstLooksLikeKeyValue =
        first.length >= 2 &&
        knownHeaders <= 1 &&
        _isKnownKey(_normalize(first.first));
    if (firstLooksLikeKeyValue) {
      for (final row in rows) {
        if (row.length >= 2 && row.first.trim().isNotEmpty) {
          values[_normalize(row.first)] = row.sublist(1).join(' ').trim();
        }
      }
      return values;
    }

    final headers = first.map(_normalize).toList(growable: false);
    for (final row in rows.skip(1)) {
      if (row.isEmpty) {
        continue;
      }
      for (
        var index = 0;
        index < headers.length && index < row.length;
        index += 1
      ) {
        final value = row[index].trim();
        if (value.isNotEmpty) {
          final key = headers[index];
          // A POS report should contain one summary row. If an export has
          // several rows, keep the last non-empty value and require the user
          // to import a summary export rather than guessing at a total.
          values[key] = value;
        }
      }
    }
    return values;
  }

  static bool _isKnownKey(String key) => <Set<String>>[
    _currencyKeys,
    _expectedCashKeys,
    _cardKeys,
    _totalSalesKeys,
    _idKeys,
    _dateKeys,
    _tillKeys,
    _cashierKeys,
  ].any((keys) => keys.contains(key));

  static String? _value(Map<String, String> values, Set<String> keys) {
    for (final key in keys) {
      final value = values[key];
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int? _amount(
    Map<String, String> values,
    Set<String> keys, {
    required int fractionDigits,
  }) {
    final value = _value(values, keys);
    if (value == null) {
      return null;
    }
    final parsed = AppFormatters.parseMoneyToMinor(
      value,
      fractionDigits: fractionDigits,
    );
    if (parsed == null) {
      throw const PosImportException('amountInvalid');
    }
    return parsed;
  }

  static DateTime? _date(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }

  static String _sha256(List<int> bytes) {
    final digest = Sha256().toSync().hashSync(bytes);
    return digest.bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static String _normalize(String value) {
    const replacements = <String, String>{
      'á': 'a',
      'č': 'c',
      'ď': 'd',
      'é': 'e',
      'ě': 'e',
      'í': 'i',
      'ň': 'n',
      'ó': 'o',
      'ř': 'r',
      'š': 's',
      'ť': 't',
      'ú': 'u',
      'ů': 'u',
      'ý': 'y',
      'ž': 'z',
    };
    var normalized = value.trim().toLowerCase();
    replacements.forEach(
      (from, to) => normalized = normalized.replaceAll(from, to),
    );
    return normalized.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }
}

class PosImportException implements Exception {
  const PosImportException(this.code);

  final String code;

  @override
  String toString() => 'PosImportException($code)';
}
