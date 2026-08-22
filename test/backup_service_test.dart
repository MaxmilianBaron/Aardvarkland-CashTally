import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/models/business_profile.dart';
import 'package:vycetka/models/cash_count_session.dart';
import 'package:vycetka/models/custom_denomination.dart';
import 'package:vycetka/models/currency_definition.dart';
import 'package:vycetka/models/till_template.dart';
import 'package:vycetka/services/backup_service.dart';

void main() {
  test(
    'encrypted backup round-trip preserves all local configuration',
    () async {
      final service = BackupService(iterations: 100000);
      final custom = CustomDenomination.create(
        currencyCode: 'CZK',
        minorUnits: 25000,
        label: 'Voucher 250',
        kind: DenominationKind.banknote,
      );
      final bundle = BackupBundle(
        sessions: <CashCountSession>[CashCountSession.create('CZK')],
        templates: <TillTemplate>[
          TillTemplate.create(
            name: 'Bar',
            currencyCode: 'CZK',
            profile: const BusinessProfile(),
          ),
        ],
        customDenominations: <CustomDenomination>[custom],
        hiddenDenominationIds: <String, Set<String>>{
          'CZK': <String>{'coin_100'},
        },
      );

      final encrypted = await service.encrypt(
        bundle: bundle,
        password: 'correct horse',
      );
      final restored = await service.decrypt(
        bytes: encrypted,
        password: 'correct horse',
      );

      expect(String.fromCharCodes(encrypted), isNot(contains('Voucher 250')));
      expect(restored.sessions.single.currencyCode, 'CZK');
      expect(restored.templates.single.name, 'Bar');
      expect(restored.customDenominations.single.id, custom.id);
      expect(restored.hiddenDenominationIds['CZK'], contains('coin_100'));
    },
  );

  test('encrypted backup rejects a wrong password', () async {
    final service = BackupService(iterations: 100000);
    final encrypted = await service.encrypt(
      bundle: const BackupBundle(
        sessions: <CashCountSession>[],
        templates: <TillTemplate>[],
        customDenominations: <CustomDenomination>[],
        hiddenDenominationIds: <String, Set<String>>{},
      ),
      password: 'correct horse',
    );

    await expectLater(
      service.decrypt(bytes: encrypted, password: 'wrong password'),
      throwsA(anything),
    );
  });
}
