import 'package:flutter/material.dart';

@immutable
class CountryProfile {
  const CountryProfile({
    required this.id,
    required this.flag,
    required this.localName,
    required this.locale,
    required this.currencyCode,
  });

  final String id;
  final String flag;
  final String localName;
  final Locale locale;
  final String currencyCode;
}
