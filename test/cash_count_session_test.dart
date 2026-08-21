import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/models/business_profile.dart';
import 'package:vycetka/models/cash_count_session.dart';
import 'package:vycetka/models/count_mode.dart';
import 'package:vycetka/models/currency_definition.dart';

void main() {
  test('schema v5 preserves quick mode and custom denomination snapshots', () {
    const voucher = Denomination(
      customId: 'custom_voucher_250',
      minorUnits: 25000,
      label: 'Voucher 250',
      kind: DenominationKind.banknote,
    );
    final session = CashCountSession.create(
      'CZK',
      mode: CountMode.quick,
      customDenominations: const <Denomination>[voucher],
    ).copyWith(quantities: const <String, int>{'custom_voucher_250': 2});

    final restored = CashCountSession.fromJson(session.toJson());
    final currency = restored.currencyFor(CurrencyCatalog.byCode('CZK'));

    expect(restored.mode, CountMode.quick);
    expect(restored.customDenominations.single.id, voucher.id);
    expect(restored.totalMinorUnits(currency), 50000);
    expect(
      restored.toJson()['schemaVersion'],
      CashCountSession.currentSchemaVersion,
    );
  });

  test('coin and banknote of the same USD value are counted separately', () {
    final usd = CurrencyCatalog.byCode('USD');
    final oneCoin = usd.coins.firstWhere((item) => item.minorUnits == 100);
    final oneNote = usd.banknotes.firstWhere((item) => item.minorUnits == 100);
    final session = CashCountSession(
      id: 'test',
      currencyCode: 'USD',
      createdAt: DateTime(2026),
      quantities: <String, int>{oneCoin.id: 3, oneNote.id: 2},
    );

    expect(session.totalMinorUnits(usd), 500);
  });

  test('generated session IDs are non-empty and distinct', () {
    final first = CashCountSession.generateId();
    final second = CashCountSession.generateId();

    expect(first, isNotEmpty);
    expect(second, isNot(equals(first)));
  });

  test('all configured denominations contribute exact minor units', () {
    for (final currency in CurrencyCatalog.all) {
      final quantities = <String, int>{
        for (final denomination in currency.denominations) denomination.id: 1,
      };
      final expected = currency.denominations.fold<int>(
        0,
        (total, denomination) => total + denomination.minorUnits,
      );
      final session = CashCountSession(
        id: 'all-${currency.code}',
        currencyCode: currency.code,
        createdAt: DateTime(2026),
        quantities: quantities,
      );

      expect(
        session.totalMinorUnits(currency),
        expected,
        reason: currency.code,
      );
    }
  });

  test('unknown banknote weight makes the complete total unavailable', () {
    final krw = CurrencyCatalog.byCode('KRW');
    final coin = krw.coins.firstWhere((item) => item.minorUnits == 500);
    final note = krw.banknotes.firstWhere((item) => item.minorUnits == 50000);
    final coinsOnly = CashCountSession(
      id: 'krw-coins',
      currencyCode: 'KRW',
      createdAt: DateTime(2026),
      quantities: <String, int>{coin.id: 2},
    );
    final withNote = coinsOnly.copyWith(
      quantities: <String, int>{coin.id: 2, note.id: 1},
    );

    expect(coinsOnly.totalWeightMilligrams(krw), 15400);
    expect(coinsOnly.hasApproximateWeight(krw), isFalse);
    expect(withNote.totalWeightMilligrams(krw), isNull);
    expect(withNote.hasApproximateWeight(krw), isFalse);
  });

  test(
    'official nominal banknote weight is included and marked approximate',
    () {
      final eur = CurrencyCatalog.byCode('EUR');
      final fiveEuro = eur.banknotes.firstWhere(
        (item) => item.minorUnits == 500,
      );
      final session = CashCountSession(
        id: 'eur-notes',
        currencyCode: 'EUR',
        createdAt: DateTime(2026),
        quantities: <String, int>{fiveEuro.id: 10},
      );

      expect(session.totalWeightMilligrams(eur), 6000);
      expect(session.hasApproximateWeight(eur), isTrue);
    },
  );

  test('schema v5 round-trip preserves closing identity and signatures', () {
    final created = DateTime.utc(2026, 7, 22, 10, 30);
    final locked = DateTime.utc(2026, 7, 22, 10, 45);
    final session = CashCountSession(
      id: 'stable-id',
      documentNumber: 'VYC-20260722-ABC123',
      currencyCode: 'CZK',
      createdAt: created,
      updatedAt: locked,
      quantities: const <String, int>{'banknote_500000': 3},
      expectedMinorUnits: 1500000,
      floatMinorUnits: 500000,
      note: 'Večerní směna',
      businessName: 'Aardvarkland s.r.o.',
      businessRegistrationId: '12345678',
      businessAddress: 'Praha 1',
      locationName: 'Centrum',
      tillName: 'P1',
      cashierName: 'Eva',
      managerName: 'Jan',
      shiftName: 'Večer',
      cashierSignaturePngBase64: 'Y2FzaGllcg==',
      managerSignaturePngBase64: 'bWFuYWdlcg==',
      blindCount: true,
      blindCountLockedAt: locked,
    );

    final json = session.toJson();
    final restored = CashCountSession.fromJson(json);

    expect(json['schemaVersion'], CashCountSession.currentSchemaVersion);
    expect(restored.documentNumber, session.documentNumber);
    expect(restored.businessName, session.businessName);
    expect(restored.tillName, session.tillName);
    expect(restored.cashierSignaturePngBase64, 'Y2FzaGllcg==');
    expect(restored.managerSignaturePngBase64, 'bWFuYWdlcg==');
    expect(restored.quantitiesAreLocked, isTrue);
    expect(restored.toJson(), json);
  });

  test(
    'legacy schema v1 receives safe defaults and a stable document number',
    () {
      final legacy = <String, Object?>{
        'id': 'legacy-123456',
        'currencyCode': 'EUR',
        'createdAt': '2026-07-20T10:00:00.000Z',
        'updatedAt': '2026-07-20T10:05:00.000Z',
        'quantities': <String, Object?>{'banknote_5000': 2},
        'expectedMinorUnits': 10000,
        'floatMinorUnits': null,
        'note': 'legacy',
        'ocrScans': 1,
      };

      final first = CashCountSession.fromJson(legacy);
      final second = CashCountSession.fromJson(legacy);

      expect(first.documentNumber, startsWith('VYC-20260720-'));
      expect(second.documentNumber, first.documentNumber);
      expect(first.hasBusinessIdentity, isFalse);
      expect(first.blindCount, isFalse);
      expect(first.quantitiesAreLocked, isFalse);
    },
  );

  test('new session copies the business profile into its own snapshot', () {
    const profile = BusinessProfile(
      businessName: 'Pilot shop',
      registrationId: 'CZ123',
      locationName: 'North',
      tillName: 'Register 4',
      cashierName: 'Alex',
    );

    final session = CashCountSession.create('USD', profile: profile);

    expect(session.businessName, profile.businessName);
    expect(session.businessRegistrationId, profile.registrationId);
    expect(session.locationName, profile.locationName);
    expect(session.tillName, profile.tillName);
    expect(session.cashierName, profile.cashierName);
    expect(session.documentNumber, startsWith('VYC-'));
  });
}
