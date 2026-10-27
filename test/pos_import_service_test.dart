import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/services/pos_import_service.dart';

void main() {
  const service = PosImportService();

  test('imports semicolon summary with Czech labels and exact minor units', () {
    final source = utf8.encode(
      'sep=;\r\n'
      'Měna;Číslo uzávěrky;Očekávaná hotovost;Karty;Tržby;Pokladna\r\n'
      'CZK;Z-2026-07;12 345,67;2 000,00;14 345,67;P1\r\n',
    );

    final report = service.parse(bytes: source, sourceFileName: 'z-report.csv');

    expect(report.currencyCode, 'CZK');
    expect(report.id, 'Z-2026-07');
    expect(report.expectedCashMinorUnits, 1234567);
    expect(report.cardMinorUnits, 200000);
    expect(report.totalSalesMinorUnits, 1434567);
    expect(report.tillName, 'P1');
    expect(report.sourceSha256, hasLength(64));
  });

  test('imports key-value CSV and supports quoted commas', () {
    final source = utf8.encode(
      'currency,report,expected_cash,card,total_sales,till\n'
      'USD,"Z,42",1234.56,100.00,1334.56,"Front, till"\n',
    );

    final report = service.parse(bytes: source, sourceFileName: 'z.csv');

    expect(report.currencyCode, 'USD');
    expect(report.id, 'Z,42');
    expect(report.expectedCashMinorUnits, 123456);
    expect(report.tillName, 'Front, till');
  });

  test('rejects multiple POS rows rather than blending currencies and till amounts', () {
    final rows = utf8.encode(
      'currency;expected_cash;till\n'
      'CZK;100,00;A\n'
      'EUR;;B\n',
    );
    expect(
      () => service.parse(bytes: rows, sourceFileName: 'multi.csv'),
      throwsA(isA<PosImportException>().having(
        (error) => error.code, 'code', 'ambiguousRows',
      )),
    );
  });

  test('rejects malformed expected amounts before reconciliation', () {
    final rows = utf8.encode('currency;expected_cash\nCZK;1e3\n');
    expect(
      () => service.parse(bytes: rows, sourceFileName: 'malformed.csv'),
      throwsA(isA<PosImportException>().having(
        (error) => error.code, 'code', 'amountInvalid',
      )),
    );
  });

  test('rejects a POS export without explicit expected cash', () {
    final source = utf8.encode('currency;total_sales\nCZK;100,00\n');

    expect(
      () => service.parse(bytes: source, sourceFileName: 'sales.csv'),
      throwsA(
        isA<PosImportException>().having(
          (error) => error.code,
          'code',
          'expectedCashMissing',
        ),
      ),
    );
  });
}
