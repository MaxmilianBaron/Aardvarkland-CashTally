import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/l10n/app_localizations.dart';
import 'package:vycetka/l10n/platform_localizations.dart';
import 'package:vycetka/models/count_mode.dart';
import 'package:vycetka/screens/count_screen.dart';
import 'package:vycetka/services/entitlement_service.dart';
import 'package:vycetka/services/preference_service.dart';
import 'package:vycetka/state/app_controller.dart';
import 'package:vycetka/state/app_scope.dart';
import 'package:vycetka/widgets/denomination_row.dart';

void main() {
  testWidgets('tap multiplier accelerates entry and respects a locked count', (
    tester,
  ) async {
    final currency = CurrencyCatalog.byCode('CZK');
    final denomination = currency.banknotes.last;
    final changes = <int>[];

    await tester.pumpWidget(
      _materialHarness(
        child: DenominationRow(
          currency: currency,
          denomination: denomination,
          quantity: 0,
          step: 5,
          onChanged: changes.add,
          onEdit: () {},
        ),
      ),
    );
    await tester.tap(find.byType(DenominationRow));

    expect(changes, <int>[5]);

    await tester.pumpWidget(
      _materialHarness(
        child: DenominationRow(
          currency: currency,
          denomination: denomination,
          quantity: 7,
          enabled: false,
          step: 10,
          onChanged: changes.add,
          onEdit: () {},
        ),
      ),
    );
    await tester.tap(find.byType(DenominationRow));
    expect(changes, <int>[5]);
  });

  testWidgets('all quick steps work for card, plus, minus and long press', (
    tester,
  ) async {
    final currency = CurrencyCatalog.byCode('CZK');
    final denomination = currency.banknotes.last;

    for (final step in <int>[1, 10, 50, 100]) {
      var quantity = 0;
      await tester.pumpWidget(
        _materialHarness(
          child: StatefulBuilder(
            builder: (context, setState) => DenominationRow(
              key: ValueKey(step),
              currency: currency,
              denomination: denomination,
              quantity: quantity,
              step: step,
              onChanged: (value) => setState(() => quantity = value),
              onEdit: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byType(DenominationRow));
      await tester.pump();
      expect(quantity, step);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pump();
      expect(quantity, step * 2);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
      await tester.pump();
      expect(quantity, step);
      await tester.longPress(find.byType(DenominationRow));
      await tester.pump();
      expect(quantity, 0);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.remove));
      await tester.pump();
      expect(quantity, 0);
    }
  });

  testWidgets(
    'blind count hides comparison, blocks save and then locks quantities',
    (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = AppController(
        entitlementService: _AdFreeEntitlementService(),
        preferenceService: _MemoryPreferenceService(),
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        AppScope(
          controller: controller,
          child: _materialHarness(
            child: const CountScreen(initialCurrencyCode: 'CZK'),
          ),
        ),
      );
      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      expect(find.text('Expected amount (CZK)'), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pump();
      expect(
        find.text('Finish and lock the blind count before saving.'),
        findsOneWidget,
      );

      await tester.drag(find.byType(Scrollable).first, const Offset(0, -600));
      await tester.pumpAndSettle();
      expect(find.byType(DenominationRow), findsWidgets);
      await tester.tap(find.byType(DenominationRow).first);
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Finish blind count'),
        600,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Finish blind count'));
      await tester.pumpAndSettle();
      expect(find.text('Lock and continue'), findsOneWidget);
      await tester.tap(find.text('Lock and continue'));
      await tester.pumpAndSettle();

      expect(find.text('Expected amount (CZK)'), findsOneWidget);
      expect(
        tester.widgetList<DenominationRow>(find.byType(DenominationRow)),
        everyElement(predicate<DenominationRow>((row) => !row.enabled)),
      );
    },
  );

  testWidgets('quick count omits professional closing fields', (tester) async {
    tester.view.physicalSize = const Size(400, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = AppController(
      entitlementService: _AdFreeEntitlementService(),
      preferenceService: _MemoryPreferenceService(),
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: _materialHarness(
          child: const CountScreen(
            initialCurrencyCode: 'CZK',
            mode: CountMode.quick,
          ),
        ),
      ),
    );

    expect(find.text('Quick count'), findsOneWidget);
    expect(find.text('Expected amount (CZK)'), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });
}

Widget _materialHarness({required Widget child}) => MaterialApp(
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
  home: Scaffold(body: child),
);

class _AdFreeEntitlementService extends EntitlementService {
  static const snapshotValue = EntitlementSnapshot(
    kind: EntitlementKind.lifetime,
  );

  @override
  EntitlementSnapshot get snapshot => snapshotValue;

  @override
  Future<EntitlementSnapshot> initialize() async => snapshotValue;
}

class _MemoryPreferenceService extends PreferenceService {
  @override
  Future<void> saveCountryAndCurrency({
    required String countryId,
    required String currencyCode,
  }) async {}

  @override
  Future<void> saveCurrencyCode(String currencyCode) async {}
}
