import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/country_catalog.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/l10n/app_localizations.dart';
import 'package:vycetka/l10n/platform_localizations.dart';
import 'package:vycetka/screens/ad_free_screen.dart';
import 'package:vycetka/screens/count_screen.dart';
import 'package:vycetka/screens/dashboard_screen.dart';
import 'package:vycetka/services/entitlement_service.dart';
import 'package:vycetka/services/preference_service.dart';
import 'package:vycetka/state/app_controller.dart';
import 'package:vycetka/state/app_scope.dart';

void main() {
  final uniqueLocales = <String, Locale>{
    for (final locale in AppLocalizations.supportedLocales)
      locale.languageCode: locale,
  }.values.toList(growable: false);

  test('all language keys preserve the English placeholder contract', () {
    final english = const AppLocalizations(Locale('en'));
    for (final locale in uniqueLocales) {
      final l10n = AppLocalizations(locale);
      for (final key in AppLocalizations.translationKeys) {
        expect(
          _placeholders(l10n.tr(key)),
          _placeholders(english.tr(key)),
          reason: '${locale.languageCode}:$key',
        );
      }
    }
  });

  test('every supported language has a direct translation for every key', () {
    for (final locale in uniqueLocales) {
      expect(
        AppLocalizations.englishFallbackKeys(locale.languageCode),
        isEmpty,
        reason: locale.languageCode,
      );
    }
  });

  test('all currencies format every denomination in every language', () {
    for (final locale in uniqueLocales) {
      for (final currency in CurrencyCatalog.all) {
        for (final denomination in currency.denominations) {
          final formatted = currency.formatMinor(
            denomination.minorUnits,
            localeCode: locale.languageCode,
          );
          expect(
            formatted,
            isNotEmpty,
            reason: '${locale.languageCode} ${currency.code}',
          );
          expect(formatted, contains(currency.symbol));
        }
      }
    }
  });

  testWidgets('dashboard has no layout exception in all languages and plans', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in uniqueLocales) {
      final country = CountryCatalog.all.firstWhere(
        (item) => item.locale.languageCode == locale.languageCode,
      );
      for (final adFree in <bool>[false, true]) {
        final controller = _controller(adFree: adFree);
        await controller.selectCountry(country);
        await tester.pumpWidget(
          _localizedHarness(
            locale: locale,
            controller: controller,
            child: const DashboardScreen(),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '${locale.languageCode} ${adFree ? 'Ad-free' : 'Free'}',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      }
    }
  });

  testWidgets(
    'count screen has no layout exception in all languages and currencies',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final locale in uniqueLocales) {
        for (final currency in CurrencyCatalog.all) {
          final controller = _controller(adFree: true);
          await tester.pumpWidget(
            _localizedHarness(
              locale: locale,
              controller: controller,
              child: CountScreen(initialCurrencyCode: currency.code),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '${locale.languageCode} ${currency.code}',
          );
          expect(
            find.byType(CountScreen),
            findsOneWidget,
            reason: '${locale.languageCode} ${currency.code}',
          );
          await tester.pumpWidget(const SizedBox.shrink());
          controller.dispose();
        }
      }
    },
  );

  testWidgets('ad-free offer fits a narrow screen in every language', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final locale in uniqueLocales) {
      final controller = _controller(adFree: false);
      await tester.pumpWidget(
        _localizedHarness(
          locale: locale,
          controller: controller,
          child: const AdFreeScreen(),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: locale.languageCode);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    }
  });
}

AppController _controller({required bool adFree}) => AppController(
  entitlementService: _FakeEntitlementService(adFree: adFree),
  preferenceService: _MemoryPreferenceService(),
);

Widget _localizedHarness({
  required Locale locale,
  required AppController controller,
  required Widget child,
}) => AppScope(
  controller: controller,
  child: MaterialApp(
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
      AppLocalizations.delegate,
      AppMaterialFallbackLocalizationsDelegate(),
      AppCupertinoFallbackLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  ),
);

Set<String> _placeholders(String value) => RegExp(
  r'\{([A-Za-z][A-Za-z0-9_]*)\}',
).allMatches(value).map((match) => match.group(1)!).toSet();

class _FakeEntitlementService extends EntitlementService {
  _FakeEntitlementService({required bool adFree})
    : _snapshot = EntitlementSnapshot(
        kind: adFree ? EntitlementKind.lifetime : EntitlementKind.free,
      );

  final EntitlementSnapshot _snapshot;

  @override
  EntitlementSnapshot get snapshot => _snapshot;

  @override
  Future<EntitlementSnapshot> initialize() async => _snapshot;
}

class _MemoryPreferenceService extends PreferenceService {
  @override
  Future<void> saveCountryAndCurrency({
    required String countryId,
    required String currencyCode,
  }) async {}

  @override
  Future<void> saveLocaleCode(String localeCode) async {}

  @override
  Future<void> saveCurrencyCode(String currencyCode) async {}
}
