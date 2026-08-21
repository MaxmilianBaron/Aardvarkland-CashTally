import 'dart:async';

import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../data/currency_catalog.dart';
import '../data/country_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/business_profile.dart';
import '../models/cash_count_session.dart';
import '../models/country_profile.dart';
import '../models/custom_denomination.dart';
import '../models/currency_definition.dart';
import '../models/till_template.dart';
import '../services/ad_service.dart';
import '../services/app_lock_service.dart';
import '../services/entitlement_service.dart';
import '../services/local_store.dart';
import '../services/purchase_service.dart';
import '../services/preference_service.dart';

class AppController extends ChangeNotifier {
  AppController({
    LocalStore? localStore,
    EntitlementService? entitlementService,
    AdService? adService,
    PurchaseVerifier? purchaseVerifier,
    PreferenceService? preferenceService,
    AppLockService? appLockService,
  }) : _localStore = localStore ?? LocalStore(),
       entitlementService = entitlementService ?? EntitlementService(),
       adService = adService ?? AdService(),
       appLockService = appLockService ?? AppLockService() {
    _preferenceService = preferenceService ?? PreferenceService();
    purchaseService = PurchaseService(
      entitlementService: this.entitlementService,
      verifier: purchaseVerifier,
    );
    purchaseService.addListener(_handlePurchaseChange);
    this.adService.addListener(_handleAdChange);
  }

  final LocalStore _localStore;
  final EntitlementService entitlementService;
  final AdService adService;
  final AppLockService appLockService;
  late final PreferenceService _preferenceService;
  late final PurchaseService purchaseService;

  final List<CashCountSession> _sessions = <CashCountSession>[];
  bool _loading = true;
  String? _errorMessage;
  String _selectedCurrencyCode = 'CZK';
  Set<String> _favoriteCurrencyCodes = <String>{};
  List<String> _favoriteCurrencyOrder = <String>[];
  final List<TillTemplate> _tillTemplates = <TillTemplate>[];
  final List<CustomDenomination> _customDenominations = <CustomDenomination>[];
  final Map<String, Set<String>> _hiddenDenominationIds =
      <String, Set<String>>{};
  String? _selectedCountryId;
  Locale? _selectedLocale;
  bool _countryConfirmedForRun = false;
  ThemeMode _themeMode = ThemeMode.system;
  BusinessProfile _businessProfile = const BusinessProfile();
  bool _appLockEnabled = false;

  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  String get selectedCurrencyCode => _selectedCurrencyCode;
  CountryProfile? get selectedCountry =>
      CountryCatalog.byId(_selectedCountryId);
  Locale? get locale => _selectedLocale ?? selectedCountry?.locale;
  bool get countryConfirmedForRun => _countryConfirmedForRun;
  ThemeMode get themeMode => _themeMode;
  BusinessProfile get businessProfile => _businessProfile;
  bool get appLockEnabled => _appLockEnabled;
  EntitlementSnapshot get entitlement => entitlementService.snapshot;
  bool get isAdFree => !AppConfig.monetizationEnabled || entitlement.isAdFree;
  bool get shouldShowAds =>
      AppConfig.monetizationEnabled &&
      entitlement.showsAds &&
      adService.canRequestAds;
  List<CashCountSession> get sessions => List.unmodifiable(_sessions);
  List<TillTemplate> get tillTemplates => List.unmodifiable(_tillTemplates);
  List<CustomDenomination> get customDenominations =>
      List.unmodifiable(_customDenominations);
  Map<String, Set<String>> get hiddenDenominationIds => Map.unmodifiable(
    _hiddenDenominationIds.map(
      (code, ids) => MapEntry(code, Set<String>.unmodifiable(ids)),
    ),
  );
  Set<String> get favoriteCurrencyCodes =>
      Set<String>.unmodifiable(_favoriteCurrencyCodes);
  List<String> get favoriteCurrencyOrder =>
      List<String>.unmodifiable(_favoriteCurrencyOrder);
  List<CurrencyDefinition> get currencies => CurrencyCatalog.displayOrder(
    _selectedCurrencyCode,
    favoriteCodes: _favoriteCurrencyCodes,
    favoriteOrder: _favoriteCurrencyOrder,
  );
  CurrencyDefinition get selectedCurrency =>
      CurrencyCatalog.byCode(_selectedCurrencyCode);

  Future<void> initialize() async {
    try {
      await entitlementService.initialize();
      _selectedCountryId = await _preferenceService.loadCountryId();
      final storedLocale = await _preferenceService.loadLocaleCode();
      _selectedLocale = _localeFromCode(storedLocale);
      _appLockEnabled = await _preferenceService.loadAppLockEnabled();
      final storedCurrency = await _preferenceService.loadCurrencyCode();
      if (CurrencyCatalog.containsCode(storedCurrency)) {
        _selectedCurrencyCode = storedCurrency!;
      } else if (selectedCountry != null) {
        _selectedCurrencyCode = selectedCountry!.currencyCode;
      }
      _favoriteCurrencyCodes =
          (await _preferenceService.loadFavoriteCurrencyCodes())
              .where(CurrencyCatalog.containsCode)
              .toSet();
      _favoriteCurrencyOrder =
          (await _preferenceService.loadFavoriteCurrencyOrder())
              .where(CurrencyCatalog.containsCode)
              .where(_favoriteCurrencyCodes.contains)
              .toList(growable: false);
      // Legacy favorite sets were alphabetically stored. Persist the migrated
      // order once so drag-and-drop priority is stable across versions.
      if (_favoriteCurrencyCodes.isNotEmpty &&
          _favoriteCurrencyOrder.length != _favoriteCurrencyCodes.length) {
        _favoriteCurrencyOrder = <String>[
          ..._favoriteCurrencyOrder,
          ...CurrencyCatalog.globalUsageOrder.where(
            (code) =>
                _favoriteCurrencyCodes.contains(code) &&
                !_favoriteCurrencyOrder.contains(code),
          ),
        ];
        unawaited(
          _preferenceService.saveFavoriteCurrencyOrder(_favoriteCurrencyOrder),
        );
      }
      _businessProfile = await _preferenceService.loadBusinessProfile();
      _tillTemplates
        ..clear()
        ..addAll(await _preferenceService.loadTillTemplates());
      _customDenominations
        ..clear()
        ..addAll(await _preferenceService.loadCustomDenominations());
      _hiddenDenominationIds
        ..clear()
        ..addAll(await _preferenceService.loadHiddenDenominationIds());
      _sessions
        ..clear()
        ..addAll(await _localStore.loadSessions());
    } on Object catch (error) {
      _errorMessage = AppLocalizations(
        locale ?? const Locale('en'),
      ).tr('appLoadFailed', {'error': error});
    } finally {
      _loading = false;
      notifyListeners();
    }

    // Store connectivity must never delay offline cash counting at launch.
    if (AppConfig.monetizationEnabled) {
      unawaited(purchaseService.initialize());
    }
    if (AppConfig.monetizationEnabled && !isAdFree) {
      // Consent and ads are also non-blocking; every counting feature remains
      // available even when the network or an ad provider is unavailable.
      unawaited(adService.initialize());
    }
  }

  void selectCurrency(String code) {
    if (_selectedCurrencyCode == code) {
      return;
    }
    _selectedCurrencyCode = code;
    notifyListeners();
    unawaited(_preferenceService.saveCurrencyCode(code));
  }

  Future<void> setDefaultCurrency(String code) async {
    if (!CurrencyCatalog.containsCode(code) || _selectedCurrencyCode == code) {
      return;
    }
    _selectedCurrencyCode = code;
    notifyListeners();
    await _preferenceService.saveCurrencyCode(code);
  }

  Future<void> setDefaultLocale(Locale locale) async {
    if (!AppLocalizations.supportedLocales.any(
      (item) => item.languageCode == locale.languageCode,
    )) {
      return;
    }
    _selectedLocale = Locale(locale.languageCode);
    notifyListeners();
    await _preferenceService.saveLocaleCode(locale.languageCode);
  }

  void toggleFavoriteCurrency(String code) {
    if (!CurrencyCatalog.containsCode(code)) {
      return;
    }
    if (!_favoriteCurrencyCodes.remove(code)) {
      _favoriteCurrencyCodes.add(code);
      _favoriteCurrencyOrder = <String>[..._favoriteCurrencyOrder, code];
    } else {
      _favoriteCurrencyOrder.remove(code);
    }
    notifyListeners();
    unawaited(
      _preferenceService.saveFavoriteCurrencyOrder(_favoriteCurrencyOrder),
    );
  }

  void reorderFavoriteCurrencies(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= _favoriteCurrencyOrder.length) {
      return;
    }
    newIndex = newIndex.clamp(0, _favoriteCurrencyOrder.length - 1);
    final item = _favoriteCurrencyOrder.removeAt(oldIndex);
    _favoriteCurrencyOrder.insert(newIndex, item);
    notifyListeners();
    unawaited(
      _preferenceService.saveFavoriteCurrencyOrder(_favoriteCurrencyOrder),
    );
  }

  Future<void> selectCountry(CountryProfile country) async {
    await _preferenceService.saveCountryAndCurrency(
      countryId: country.id,
      currencyCode: country.currencyCode,
    );
    await _preferenceService.saveLocaleCode(country.locale.languageCode);
    _selectedCountryId = country.id;
    _selectedCurrencyCode = country.currencyCode;
    _selectedLocale = country.locale;
    _countryConfirmedForRun = true;
    notifyListeners();
  }

  void showCountryPicker() {
    _countryConfirmedForRun = false;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) {
      return;
    }
    _themeMode = mode;
    notifyListeners();
  }

  Future<void> saveBusinessProfile(BusinessProfile profile) async {
    await _preferenceService.saveBusinessProfile(profile);
    _businessProfile = profile;
    notifyListeners();
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    await _preferenceService.saveAppLockEnabled(enabled);
    _appLockEnabled = enabled;
    notifyListeners();
  }

  CurrencyDefinition configuredCurrency(String code) {
    final base = CurrencyCatalog.byCode(code);
    final custom = _customDenominations
        .where((item) => item.currencyCode == code)
        .map((item) => item.toDenomination());
    return base.copyWithDenominations(<Denomination>[
      ...base.denominations,
      ...custom,
    ]);
  }

  CurrencyDefinition countingCurrency(
    String code, {
    Set<String> keepVisible = const <String>{},
  }) {
    final configured = configuredCurrency(code);
    final hidden = _hiddenDenominationIds[code] ?? const <String>{};
    return configured.copyWithDenominations(
      configured.denominations
          .where(
            (item) =>
                !hidden.contains(item.id) || keepVisible.contains(item.id),
          )
          .toList(growable: false),
    );
  }

  Future<void> saveTillTemplate(TillTemplate template) async {
    final index = _tillTemplates.indexWhere((item) => item.id == template.id);
    if (index < 0) {
      _tillTemplates.add(template);
    } else {
      _tillTemplates[index] = template;
    }
    await _preferenceService.saveTillTemplates(_tillTemplates);
    notifyListeners();
  }

  Future<void> deleteTillTemplate(String id) async {
    _tillTemplates.removeWhere((item) => item.id == id);
    await _preferenceService.saveTillTemplates(_tillTemplates);
    notifyListeners();
  }

  Future<void> addCustomDenomination(CustomDenomination denomination) async {
    _customDenominations.add(denomination);
    await _preferenceService.saveCustomDenominations(_customDenominations);
    notifyListeners();
  }

  Future<void> setDenominationVisible(
    String currencyCode,
    String denominationId,
    bool visible,
  ) async {
    final hidden = _hiddenDenominationIds.putIfAbsent(
      currencyCode,
      () => <String>{},
    );
    if (visible) {
      hidden.remove(denominationId);
    } else {
      hidden.add(denominationId);
    }
    await _preferenceService.saveHiddenDenominationIds(_hiddenDenominationIds);
    notifyListeners();
  }

  bool isDenominationVisible(String currencyCode, String denominationId) =>
      !(_hiddenDenominationIds[currencyCode] ?? const <String>{}).contains(
        denominationId,
      );

  Future<void> importLocalData({
    required List<CashCountSession> sessions,
    required List<TillTemplate> templates,
    required List<CustomDenomination> customDenominations,
    required Map<String, Set<String>> hiddenDenominationIds,
  }) async {
    final bySessionId = <String, CashCountSession>{
      for (final item in _sessions) item.id: item,
    };
    for (final item in sessions) {
      final existing = bySessionId[item.id];
      if (existing == null || item.updatedAt.isAfter(existing.updatedAt)) {
        bySessionId[item.id] = item;
      }
    }
    final mergedSessions = bySessionId.values.toList(growable: false)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final byTemplateId = <String, TillTemplate>{
      for (final item in _tillTemplates) item.id: item,
      for (final item in templates) item.id: item,
    };
    final byCustomId = <String, CustomDenomination>{
      for (final item in _customDenominations) item.id: item,
      for (final item in customDenominations) item.id: item,
    };
    final mergedHidden = <String, Set<String>>{
      for (final entry in _hiddenDenominationIds.entries)
        entry.key: Set<String>.from(entry.value),
    };
    for (final entry in hiddenDenominationIds.entries) {
      mergedHidden.putIfAbsent(entry.key, () => <String>{}).addAll(entry.value);
    }

    await _localStore.saveSessions(mergedSessions);
    await _preferenceService.saveTillTemplates(
      byTemplateId.values.toList(growable: false),
    );
    await _preferenceService.saveCustomDenominations(
      byCustomId.values.toList(growable: false),
    );
    await _preferenceService.saveHiddenDenominationIds(mergedHidden);

    _sessions
      ..clear()
      ..addAll(mergedSessions);
    _tillTemplates
      ..clear()
      ..addAll(byTemplateId.values);
    _customDenominations
      ..clear()
      ..addAll(byCustomId.values);
    _hiddenDenominationIds
      ..clear()
      ..addAll(mergedHidden);
    notifyListeners();
  }

  bool canCreateSavedSession() => true;

  Future<bool> saveSession(CashCountSession session) async {
    final existingIndex = _sessions.indexWhere((item) => item.id == session.id);
    if (existingIndex < 0 && !canCreateSavedSession()) {
      return false;
    }

    final nextSessions = List<CashCountSession>.from(_sessions);
    if (existingIndex >= 0) {
      nextSessions[existingIndex] = session;
    } else {
      nextSessions.add(session);
    }
    nextSessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Commit the in-memory state only after the durable write succeeds.
    await _localStore.saveSessions(nextSessions);
    _sessions
      ..clear()
      ..addAll(nextSessions);
    notifyListeners();
    return true;
  }

  Future<void> deleteSession(String id) async {
    final nextSessions = List<CashCountSession>.from(_sessions)
      ..removeWhere((session) => session.id == id);
    if (nextSessions.length == _sessions.length) {
      return;
    }

    await _localStore.saveSessions(nextSessions);
    _sessions
      ..clear()
      ..addAll(nextSessions);
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _handlePurchaseChange() {
    if (!isAdFree) {
      unawaited(adService.initialize());
    }
    notifyListeners();
  }

  void _handleAdChange() => notifyListeners();

  Locale? _localeFromCode(String? code) {
    if (code == null || code.trim().isEmpty) {
      return null;
    }
    return AppLocalizations.supportedLocales.any(
          (locale) => locale.languageCode == code,
        )
        ? Locale(code)
        : null;
  }

  @override
  void dispose() {
    purchaseService.removeListener(_handlePurchaseChange);
    adService.removeListener(_handleAdChange);
    purchaseService.dispose();
    adService.dispose();
    super.dispose();
  }
}
