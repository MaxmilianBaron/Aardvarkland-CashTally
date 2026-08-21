import 'package:flutter/services.dart';

import 'locale_formatting.dart';

abstract final class AppFormatters {
  static String dateTime(DateTime value, {String localeCode = 'cs'}) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final date = switch (localeCode) {
      'en' => '$month/$day/${local.year}',
      'ja' || 'ko' => '${local.year}/$month/$day',
      'de' => '$day.$month.${local.year}',
      _ => '$day/$month/${local.year}',
    };
    return '$date · '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  /// Parses Czech and English-style money input without floating-point math.
  ///
  /// Accepted examples: `1 234,56`, `1,234.56`, `1.234,56`, `1234.5`.
  /// A single separator followed by three or more digits is treated as a
  /// thousands separator, so `1.234` becomes 1234 rather than 1.234.
  static int? parseMoneyToMinor(String input, {int fractionDigits = 2}) {
    var source = input
        .trim()
        .replaceAll(RegExp(r'[\s\u00A0]'), '')
        .replaceAll(RegExp(r'[^0-9,\.\-]'), '');
    if (source.isEmpty || source == '-') {
      return null;
    }

    final negative = source.startsWith('-');
    source = source.replaceAll('-', '');
    if (source.isEmpty || !RegExp(r'\d').hasMatch(source)) {
      return null;
    }

    final lastComma = source.lastIndexOf(',');
    final lastDot = source.lastIndexOf('.');
    final possibleDecimalIndex = lastComma > lastDot ? lastComma : lastDot;
    final digitsAfterSeparator = possibleDecimalIndex < 0
        ? -1
        : source.length - possibleDecimalIndex - 1;
    final hasDecimalSeparator =
        fractionDigits > 0 &&
        possibleDecimalIndex >= 0 &&
        digitsAfterSeparator <= fractionDigits;

    String wholeSource;
    String fractionSource;
    if (hasDecimalSeparator) {
      wholeSource = source.substring(0, possibleDecimalIndex);
      fractionSource = source.substring(possibleDecimalIndex + 1);
    } else {
      wholeSource = source;
      fractionSource = '';
    }

    final wholeDigits = wholeSource.replaceAll(RegExp(r'[^0-9]'), '');
    final parsedFractionDigits = fractionSource.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    if (wholeDigits.isEmpty && parsedFractionDigits.isEmpty) {
      return null;
    }

    final whole = int.tryParse(wholeDigits.isEmpty ? '0' : wholeDigits);
    final parsedFraction =
        int.tryParse(parsedFractionDigits.padRight(fractionDigits, '0')) ?? 0;
    if (whole == null) {
      return null;
    }

    var scale = 1;
    for (var index = 0; index < fractionDigits; index += 1) {
      scale *= 10;
    }
    final minorUnits = whole * scale + parsedFraction;
    return negative ? -minorUnits : minorUnits;
  }

  static String moneyInputFromMinor(int? minorUnits, {int fractionDigits = 2}) {
    if (minorUnits == null) {
      return '';
    }
    final negative = minorUnits < 0;
    final absolute = minorUnits.abs();
    var scale = 1;
    for (var index = 0; index < fractionDigits; index += 1) {
      scale *= 10;
    }
    final whole = absolute ~/ scale;
    final fraction = absolute % scale;
    final sign = negative ? '-' : '';
    return fractionDigits == 0 || fraction == 0
        ? '$sign$whole'
        : '$sign$whole.${fraction.toString().padLeft(fractionDigits, '0')}';
  }

  static String weight(
    int? milligrams, {
    required String localeCode,
    bool approximate = false,
    String unavailableLabel = '—',
  }) {
    if (milligrams == null) {
      return unavailableLabel;
    }
    final prefix = approximate ? '≈ ' : '';
    if (milligrams >= 1000000) {
      final tenths = (milligrams / 100000).round();
      return '$prefix${_localizedTenths(tenths, localeCode)} kg';
    }
    final tenths = (milligrams / 100).round();
    return '$prefix${_localizedTenths(tenths, localeCode)} g';
  }

  static String _localizedTenths(int tenths, String localeCode) {
    final formatter = localizedDecimalFormat(localeCode);
    final whole = tenths ~/ 10;
    final fraction = tenths % 10;
    return fraction == 0
        ? formatter.format(whole)
        : '${formatter.format(whole)}${formatter.symbols.DECIMAL_SEP}$fraction';
  }
}

/// Capitalizes the first Unicode letter of each sentence, including pasted
/// text. Numeric, currency and identifier fields should not use it.
class SentenceCaseTextFormatter extends TextInputFormatter {
  const SentenceCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final runes = newValue.text.runes.toList(growable: true);
    var capitalizeNext = true;
    for (var index = 0; index < runes.length; index++) {
      final rune = runes[index];
      if (capitalizeNext && _isLetter(rune)) {
        final upper = String.fromCharCode(rune).toUpperCase().runes;
        if (upper.length == 1) {
          runes[index] = upper.first;
        }
        capitalizeNext = false;
      } else if (_isSentencePunctuation(rune)) {
        capitalizeNext = true;
      } else if (_isLetter(rune)) {
        capitalizeNext = false;
      }
    }
    final formatted = String.fromCharCodes(runes);
    if (formatted == newValue.text) {
      return newValue;
    }
    return newValue.copyWith(text: formatted);
  }

  static bool _isLetter(int rune) {
    final character = String.fromCharCode(rune);
    return character.toLowerCase() != character.toUpperCase();
  }

  static bool _isSentencePunctuation(int rune) =>
      rune == 0x2e || rune == 0x21 || rune == 0x3f || rune == 0x0a;
}
