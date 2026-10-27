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
    if (fractionDigits < 0 || fractionDigits > 3) return null;
    var source = input.trim().replaceAll(RegExp(r'[\u00A0\u202F]'), ' ');
    // Currency markers are permitted only as a prefix or a suffix.
    source = source.replaceFirst(
      RegExp(r'^(?:[A-Za-z]{3}|Kč|[$€£¥₹₽₴₩])\s*', caseSensitive: false), '',
    );
    source = source.replaceFirst(
      RegExp(r'\s*(?:[A-Za-z]{3}|Kč|[$€£¥₹₽₴₩])$', caseSensitive: false), '',
    ).trim();
    if (!RegExp(r'^-?[0-9][0-9 ,.]*$').hasMatch(source)) return null;

    final negative = source.startsWith('-');
    if (negative) source = source.substring(1);
    final comma = source.lastIndexOf(',');
    final dot = source.lastIndexOf('.');
    final last = comma > dot ? comma : dot;
    final trailing = last < 0 ? '' : source.substring(last + 1);
    final separatorCount = RegExp(r'[,.]').allMatches(source).length;
    int decimalIndex = -1;
    if (last >= 0 && fractionDigits > 0 && trailing.isNotEmpty
        && trailing.length <= fractionDigits) {
      final hasBoth = comma >= 0 && dot >= 0;
      // A single .xxx/,xxx is a thousands group for 2-decimal currencies.
      // In 3-decimal currencies, 0.xxx is unambiguously fractional;
      // other single 3-digit groups remain grouped for compatibility.
      final groupedTriple = separatorCount == 1 && trailing.length == 3
          && source.substring(0, last) != '0';
      if (hasBoth || !groupedTriple) decimalIndex = last;
    }

    final wholeSource = decimalIndex >= 0 ? source.substring(0, decimalIndex) : source;
    final fractionSource = decimalIndex >= 0 ? source.substring(decimalIndex + 1) : '';
    if (fractionSource.length > fractionDigits) return null;
    if (decimalIndex >= 0 && !RegExp(r'^[0-9]+$').hasMatch(fractionSource)) return null;

    String wholeDigits;
    if (RegExp(r'^[0-9]+$').hasMatch(wholeSource)) {
      wholeDigits = wholeSource;
    } else {
      final groups = wholeSource.split(RegExp(r'[ ,.]+'));
      if (groups.length < 2 || !RegExp(r'^[0-9]{1,3}$').hasMatch(groups.first)
          || groups.skip(1).any((group) => !RegExp(r'^[0-9]{3}$').hasMatch(group))) {
        return null;
      }
      wholeDigits = groups.join();
    }
    final whole = int.tryParse(wholeDigits);
    if (whole == null) return null;
    var scale = 1;
    for (var index = 0; index < fractionDigits; index += 1) {
      scale *= 10;
    }
    const maxMinorUnits = 9000000000000000;
    if (whole > maxMinorUnits ~/ scale) return null;
    final paddedFraction = fractionSource.padRight(fractionDigits, '0');
    final fraction = paddedFraction.isEmpty ? 0 : int.tryParse(paddedFraction);
    if (fraction == null) return null;
    final minorUnits = whole * scale + fraction;
    if (minorUnits > maxMinorUnits) return null;
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
