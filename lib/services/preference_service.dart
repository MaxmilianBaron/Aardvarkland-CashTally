import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/business_profile.dart';
import '../models/custom_denomination.dart';
import '../models/till_template.dart';

class PreferenceService {
  PreferenceService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _countryKey = 'selected_country_v1';
  static const _currencyKey = 'selected_currency_v1';
  static const _localeKey = 'selected_locale_v1';
  static const _favoriteCurrenciesKey = 'favorite_currencies_v1';
  static const _favoriteCurrencyOrderKey = 'favorite_currency_order_v1';
  static const _businessProfileKey = 'business_profile_v1';
  static const _tillTemplatesKey = 'till_templates_v1';
  static const _customDenominationsKey = 'custom_denominations_v1';
  static const _hiddenDenominationsKey = 'hidden_denominations_v1';
  static const _appLockKey = 'app_lock_enabled_v1';

  final FlutterSecureStorage _storage;

  Future<String?> loadCountryId() => _storage.read(key: _countryKey);
  Future<String?> loadCurrencyCode() => _storage.read(key: _currencyKey);
  Future<String?> loadLocaleCode() => _storage.read(key: _localeKey);

  Future<bool> loadAppLockEnabled() async =>
      (await _storage.read(key: _appLockKey)) == 'true';

  Future<void> saveAppLockEnabled(bool enabled) =>
      _storage.write(key: _appLockKey, value: enabled ? 'true' : 'false');

  Future<Set<String>> loadFavoriteCurrencyCodes() async {
    final source = await _storage.read(key: _favoriteCurrenciesKey);
    if (source == null || source.isEmpty) {
      return <String>{};
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List<Object?>) {
        return <String>{};
      }
      return decoded.whereType<String>().toSet();
    } on Object {
      // A malformed optional preference must not prevent access to counting.
      return <String>{};
    }
  }

  /// Returns favorites in the user's explicit priority order. Older builds
  /// stored only a set, so that set remains the safe fallback until the first
  /// save writes the ordered representation.
  Future<List<String>> loadFavoriteCurrencyOrder() async {
    final ordered = await _loadStringList(_favoriteCurrencyOrderKey);
    if (ordered.isNotEmpty) {
      return ordered;
    }
    final legacy = await loadFavoriteCurrencyCodes();
    final result = legacy.toList(growable: false)..sort();
    if (result.isNotEmpty) {
      // Convert the old unordered set on first read so subsequent app starts
      // use the new drag-and-drop representation directly.
      await saveFavoriteCurrencyOrder(result);
    }
    return result;
  }

  Future<BusinessProfile> loadBusinessProfile() async {
    final source = await _storage.read(key: _businessProfileKey);
    if (source == null || source.isEmpty) {
      return const BusinessProfile();
    }
    try {
      final decoded = jsonDecode(source) as Map<String, Object?>;
      return BusinessProfile.fromJson(decoded);
    } on Object {
      // A malformed optional profile must not prevent access to cash counts.
      return const BusinessProfile();
    }
  }

  Future<List<TillTemplate>> loadTillTemplates() async {
    final decoded = await _loadJsonList(_tillTemplatesKey);
    return decoded
        .map(TillTemplate.fromJson)
        .where((item) => item.name.trim().isNotEmpty)
        .toList(growable: false);
  }

  Future<List<CustomDenomination>> loadCustomDenominations() async {
    final decoded = await _loadJsonList(_customDenominationsKey);
    return decoded
        .map(CustomDenomination.fromJson)
        .where(
          (item) =>
              item.currencyCode.isNotEmpty &&
              item.minorUnits > 0 &&
              item.label.trim().isNotEmpty,
        )
        .toList(growable: false);
  }

  Future<Map<String, Set<String>>> loadHiddenDenominationIds() async {
    final source = await _storage.read(key: _hiddenDenominationsKey);
    if (source == null || source.isEmpty) {
      return <String, Set<String>>{};
    }
    try {
      final decoded = jsonDecode(source) as Map<String, Object?>;
      return decoded.map(
        (code, value) => MapEntry(
          code,
          (value as List<Object?>).whereType<String>().toSet(),
        ),
      );
    } on Object {
      return <String, Set<String>>{};
    }
  }

  Future<void> saveCountryAndCurrency({
    required String countryId,
    required String currencyCode,
  }) async {
    await _storage.write(key: _countryKey, value: countryId);
    await _storage.write(key: _currencyKey, value: currencyCode);
  }

  Future<void> saveCurrencyCode(String currencyCode) =>
      _storage.write(key: _currencyKey, value: currencyCode);

  Future<void> saveLocaleCode(String localeCode) =>
      _storage.write(key: _localeKey, value: localeCode);

  Future<void> saveFavoriteCurrencyCodes(Set<String> currencyCodes) {
    final ordered = currencyCodes.toList(growable: false)..sort();
    return _storage.write(
      key: _favoriteCurrenciesKey,
      value: jsonEncode(ordered),
    );
  }

  Future<void> saveFavoriteCurrencyOrder(List<String> currencyCodes) async {
    final ordered = <String>[];
    final seen = <String>{};
    for (final code in currencyCodes) {
      if (seen.add(code)) {
        ordered.add(code);
      }
    }
    await _storage.write(
      key: _favoriteCurrencyOrderKey,
      value: jsonEncode(ordered),
    );
    // Keep the legacy set in sync so an older app never loses favorites.
    await saveFavoriteCurrencyCodes(seen);
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) => _storage.write(
    key: _businessProfileKey,
    value: jsonEncode(profile.toJson()),
  );

  Future<void> saveTillTemplates(List<TillTemplate> templates) =>
      _storage.write(
        key: _tillTemplatesKey,
        value: jsonEncode(
          templates.map((item) => item.toJson()).toList(growable: false),
        ),
      );

  Future<void> saveCustomDenominations(
    List<CustomDenomination> denominations,
  ) => _storage.write(
    key: _customDenominationsKey,
    value: jsonEncode(
      denominations.map((item) => item.toJson()).toList(growable: false),
    ),
  );

  Future<void> saveHiddenDenominationIds(Map<String, Set<String>> hiddenIds) =>
      _storage.write(
        key: _hiddenDenominationsKey,
        value: jsonEncode(
          hiddenIds.map((code, ids) {
            final ordered = ids.toList(growable: false)..sort();
            return MapEntry(code, ordered);
          }),
        ),
      );

  Future<List<Map<String, Object?>>> _loadJsonList(String key) async {
    final source = await _storage.read(key: key);
    if (source == null || source.isEmpty) {
      return <Map<String, Object?>>[];
    }
    try {
      final decoded = jsonDecode(source) as List<Object?>;
      return decoded
          .whereType<Map<Object?, Object?>>()
          .map(
            (item) => item.map((key, value) => MapEntry(key! as String, value)),
          )
          .toList(growable: false);
    } on Object {
      return <Map<String, Object?>>[];
    }
  }

  Future<List<String>> _loadStringList(String key) async {
    final source = await _storage.read(key: key);
    if (source == null || source.isEmpty) {
      return <String>[];
    }
    try {
      final decoded = jsonDecode(source);
      if (decoded is! List<Object?>) {
        return <String>[];
      }
      return decoded.whereType<String>().toList(growable: false);
    } on Object {
      return <String>[];
    }
  }
}
