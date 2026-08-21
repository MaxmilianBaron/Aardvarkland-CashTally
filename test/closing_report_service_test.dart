import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/data/currency_catalog.dart';
import 'package:vycetka/l10n/app_localizations.dart';
import 'package:vycetka/models/cash_count_session.dart';
import 'package:vycetka/services/closing_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const service = ClosingReportService();
  final currency = CurrencyCatalog.byCode('CZK');
  final session = CashCountSession(
    id: 'report-session',
    documentNumber: 'VYC-20260722-REPORT',
    currencyCode: 'CZK',
    createdAt: DateTime.utc(2026, 7, 22, 12),
    updatedAt: DateTime.utc(2026, 7, 22, 12, 15),
    quantities: const <String, int>{'banknote_500000': 2, 'coin_5000': 3},
    expectedMinorUnits: 1015000,
    floatMinorUnits: 200000,
    note: 'Testovací uzávěrka',
    closingTitle: 'Odpolední směna',
    businessName: 'Aardvarkland s.r.o.',
    businessRegistrationId: '12345678',
    businessAddress: 'Praha',
    locationName: 'Centrum',
    tillName: 'Pokladna 1',
    cashierName: 'Eva',
    managerName: 'Jan',
    shiftName: 'Odpolední',
    blindCount: true,
    blindCountLockedAt: DateTime.utc(2026, 7, 22, 12, 10),
  );

  test('CSV export is spreadsheet-safe and works in every app locale', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final bytes = service.buildCsv(
        session: session,
        currency: currency,
        locale: locale,
      );
      final csv = utf8.decode(bytes);

      expect(bytes.take(3), <int>[0xef, 0xbb, 0xbf]);
      expect(csv, startsWith('sep=;\r\n'));
      expect(csv, contains('VYC-20260722-REPORT'));
      expect(csv, contains('Aardvarkland s.r.o.'));
      expect(csv, contains('"2"'));
      expect(csv, isNot(contains('{code}')), reason: locale.languageCode);
    }
  });

  test('plain-text closing has a localized header and complete totals', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = AppLocalizations(locale);
      final text = service.buildPlainText(
        session: session,
        currency: currency,
        locale: locale,
      );

      expect(
        text,
        startsWith(l10n.tr('reportStartsWith')),
        reason: locale.languageCode,
      );
      expect(text, contains('VYC-20260722-REPORT'));
      expect(text, contains('Aardvarkland s.r.o.'));
      expect(text, contains('5 000 Kč × 2'));
      expect(text, contains(l10n.tr('cashBreakdown').toUpperCase()));
      expect(text, contains('Odpolední směna'));
      expect(text, contains(l10n.tr('sumOfAmounts')));
      expect(text, contains(l10n.tr('total')));
      expect(
        text.indexOf(l10n.tr('closingIdentitySentence')),
        greaterThan(text.indexOf(l10n.tr('note'))),
      );
      expect(text, isNot(contains('proofQrPayload')));
      expect(text, isNot(contains('{code}')), reason: locale.languageCode);
    }
  });

  test(
    'PDF report renders Latin, RTL, Devanagari and CJK locales',
    () async {
      final signatureData = await rootBundle.load(
        'assets/branding/vycetka_logo.png',
      );
      final signatureBytes = signatureData.buffer.asUint8List(
        signatureData.offsetInBytes,
        signatureData.lengthInBytes,
      );
      final signedSession = session.copyWith(
        cashierSignaturePngBase64: base64Encode(signatureBytes),
      );
      for (final locale in const <Locale>[
        Locale('cs'),
        Locale('ar'),
        Locale('hi'),
        Locale('ja'),
      ]) {
        final bytes = await service.buildPdf(
          session: signedSession,
          currency: currency,
          locale: locale,
        );

        expect(
          ascii.decode(bytes.take(5).toList()),
          '%PDF-',
          reason: locale.languageCode,
        );
        expect(bytes.length, greaterThan(10000), reason: locale.languageCode);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'report file names are deterministic and contain no unsafe characters',
    () {
      final stem = ClosingReportService.fileStem(
        session.copyWith(documentNumber: 'VYC/2026:07 22'),
      );

      expect(stem, 'Vycetka-VYC_2026_07_22');
    },
  );
}
