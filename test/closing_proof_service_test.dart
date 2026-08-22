import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/models/cash_count_session.dart';
import 'package:vycetka/models/pos_reconciliation.dart';
import 'package:vycetka/services/closing_proof_service.dart';

void main() {
  final currency = CurrencyCatalog.byCode('CZK');

  test('proof hash is deterministic and changes when count changes', () {
    final session = CashCountSession(
      id: 'proof-session',
      documentNumber: 'VYC-20260730-PROOF',
      currencyCode: 'CZK',
      createdAt: DateTime.utc(2026, 7, 30, 8),
      updatedAt: DateTime.utc(2026, 7, 30, 8),
      quantities: const <String, int>{'banknote_500000': 2},
    );
    final first = ClosingProofService.hashFor(session, currency);
    final second = ClosingProofService.hashFor(session, currency);
    final changed = ClosingProofService.hashFor(
      session.copyWith(quantities: const <String, int>{'banknote_500000': 3}),
      currency,
    );

    expect(first, second);
    expect(first, hasLength(64));
    expect(changed, isNot(first));
    expect(first, isNot(contains('QR')));
  });

  test('proof includes POS source hash and reconciliation values', () {
    final session = CashCountSession(
      id: 'proof-pos-session',
      documentNumber: 'VYC-20260730-POS',
      currencyCode: 'CZK',
      createdAt: DateTime.utc(2026, 7, 30),
      quantities: const <String, int>{'coin_100': 5},
      posReport: PosReconciliation(
        id: 'Z-99',
        sourceFileName: 'z.csv',
        currencyCode: 'CZK',
        importedAt: DateTime.utc(2026, 7, 30),
        sourceSha256: 'a' * 64,
        expectedCashMinorUnits: 500,
        cardMinorUnits: 1000,
      ),
    );
    final payload = ClosingProofService.canonicalPayload(session, currency);

    expect(payload, contains('Z-99'));
    expect(payload, contains('sourceSha256'));
    expect(payload, contains('expectedCashMinorUnits'));
  });
}
