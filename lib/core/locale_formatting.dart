import 'package:intl/intl.dart';

const Map<String, String> _numberLocaleFallbacks = <String, String>{
  'lb': 'de',
  'mt': 'en',
};

/// Returns a decimal formatter without throwing for app locales which are not
/// included in intl's number-symbol dataset.
NumberFormat localizedDecimalFormat(String localeCode) {
  final normalized = localeCode.replaceAll('-', '_');
  final base = normalized.split('_').first;
  final candidates = <String>[
    normalized,
    if (base != normalized) base,
    ?_numberLocaleFallbacks[base],
    'en',
  ];
  final supported = candidates.firstWhere(NumberFormat.localeExists);
  return NumberFormat.decimalPattern(supported);
}
