import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/l10n/app_localizations.dart';
import 'package:vycetka/l10n/platform_localizations.dart';
import 'package:vycetka/services/preference_service.dart';
import 'package:vycetka/widgets/currency_selector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'favorite currency codes persist and malformed data fails open',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final service = PreferenceService();

      await service.saveFavoriteCurrencyCodes(<String>{'USD', 'JPY'});
      expect(await service.loadFavoriteCurrencyCodes(), <String>{'JPY', 'USD'});

      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'favorite_currencies_v1': 'not-json',
      });
      expect(await PreferenceService().loadFavoriteCurrencyCodes(), isEmpty);
    },
  );

  test(
    'locale, currency and favorite priority survive a new preference service',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      final service = PreferenceService();

      await service.saveLocaleCode('ja');
      await service.saveCurrencyCode('JPY');
      await service.saveFavoriteCurrencyOrder(<String>['JPY', 'USD', 'EUR']);

      final restored = PreferenceService();
      expect(await restored.loadLocaleCode(), 'ja');
      expect(await restored.loadCurrencyCode(), 'JPY');
      expect(await restored.loadFavoriteCurrencyOrder(), <String>[
        'JPY',
        'USD',
        'EUR',
      ]);
      expect(await restored.loadFavoriteCurrencyCodes(), <String>{
        'JPY',
        'USD',
        'EUR',
      });
    },
  );

  test(
    'legacy favorite set migrates to a stable deterministic order',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        'favorite_currencies_v1': '["USD","EUR","JPY"]',
      });

      expect(await PreferenceService().loadFavoriteCurrencyOrder(), <String>[
        'EUR',
        'JPY',
        'USD',
      ]);
    },
  );

  testWidgets('currency selector exposes a separate favorite star', (
    tester,
  ) async {
    String? toggledCode;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          AppMaterialFallbackLocalizationsDelegate(),
          AppCupertinoFallbackLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: CurrencySelector(
            currencies: [
              CurrencyCatalog.byCode('CZK'),
              CurrencyCatalog.byCode('USD'),
            ],
            selectedCode: 'CZK',
            favoriteCodes: const <String>{'USD'},
            onSelected: (_) {},
            onFavoriteToggled: (code) => toggledCode = code,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    expect(find.byIcon(Icons.star_border_rounded), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('favorite-currency-USD')),
    );
    expect(toggledCode, 'USD');
  });
}
