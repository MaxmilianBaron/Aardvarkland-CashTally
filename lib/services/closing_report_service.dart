import 'dart:convert';

import 'package:flutter/material.dart' show Locale;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/formatters.dart';
import '../l10n/app_localizations.dart';
import '../models/cash_count_session.dart';
import '../models/currency_definition.dart';
import 'closing_proof_service.dart';

class ClosingReportService {
  const ClosingReportService();

  static String fileStem(CashCountSession session) {
    final safeNumber = session.documentNumber.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    return 'Vycetka-$safeNumber';
  }

  Future<Uint8List> buildPdf({
    required CashCountSession session,
    required CurrencyDefinition currency,
    required Locale locale,
  }) async {
    final localeCode = locale.toLanguageTag();
    final languageCode = locale.languageCode;
    final l10n = AppLocalizations(locale);
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'),
    );
    final fallbacks = <pw.Font>[
      pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansArabic-Regular.ttf'),
      ),
      pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansHebrew-Regular.ttf'),
      ),
      pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansDevanagari-Regular.ttf'),
      ),
      pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansThai-Regular.ttf'),
      ),
      pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansJP-Variable.ttf'),
      ),
      pw.Font.ttf(
        await rootBundle.load('assets/fonts/NotoSansKR-Variable.ttf'),
      ),
    ];
    final theme = pw.ThemeData.withFont(
      base: regular,
      bold: bold,
      fontFallback: fallbacks,
    );
    final logoData = await rootBundle.load('assets/branding/vycetka_logo.png');
    final logo = pw.MemoryImage(logoData.buffer.asUint8List());
    final rtl = const <String>{'ar', 'he', 'ur'}.contains(languageCode);
    final direction = rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final total = session.totalMinorUnits(currency);
    final difference = session.differenceMinorUnits(currency);
    final deposit = session.depositMinorUnits(currency);
    final proofHash = ClosingProofService.hashFor(session, currency);
    final used =
        currency.denominations
            .where((item) => session.quantityFor(item) > 0)
            .toList(growable: false)
          ..sort((a, b) {
            final kind = b.kind.index.compareTo(a.kind.index);
            return kind != 0 ? kind : b.minorUnits.compareTo(a.minorUnits);
          });
    final totalPieces = used.fold<int>(
      0,
      (sum, item) => sum + session.quantityFor(item),
    );
    final breakdownRows = used
        .map(
          (item) => <String>[
            _denominationLabel(item, localeCode, l10n),
            '${session.quantityFor(item)}',
            currency.formatMinor(
              item.minorUnits * session.quantityFor(item),
              localeCode: localeCode,
            ),
          ],
        )
        .toList(growable: true);
    if (breakdownRows.isEmpty) {
      breakdownRows.add(<String>[l10n.tr('noDenominations'), '0', '']);
    }
    breakdownRows
      ..add(<String>[l10n.tr('total'), '$totalPieces', ''])
      ..add(<String>[
        l10n.tr('sumOfAmounts'),
        '',
        currency.formatMinor(total, localeCode: localeCode),
      ]);

    final document = pw.Document(
      title: '${l10n.tr('cashClosingReport')} ${session.documentNumber}',
      author: 'Výčetka',
      creator: 'Výčetka',
      subject: l10n.tr('cashClosingReport'),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(32, 32, 32, 36),
        theme: theme,
        textDirection: direction,
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: <pw.Widget>[
              pw.Text(
                session.documentNumber,
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
              pw.Text(
                '${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
        ),
        build: (context) => <pw.Widget>[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Image(logo, width: 52, height: 52, fit: pw.BoxFit.contain),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: <pw.Widget>[
                    pw.Text(
                      l10n.tr('reportStartsWith'),
                      style: pw.TextStyle(
                        font: bold,
                        fontFallback: fallbacks,
                        fontSize: 22,
                        color: PdfColors.blueGrey900,
                      ),
                    ),
                    if (session.closingTitle.trim().isNotEmpty) ...<pw.Widget>[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        session.closingTitle.trim(),
                        style: pw.TextStyle(
                          font: bold,
                          fontFallback: fallbacks,
                          fontSize: 16,
                          color: PdfColors.blueGrey700,
                        ),
                      ),
                    ],
                    pw.SizedBox(height: 3),
                    pw.Text(
                      '${l10n.tr('documentNumber')}: ${session.documentNumber}',
                      style: pw.TextStyle(
                        font: regular,
                        fontFallback: fallbacks,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 18),
          _sectionTitle(l10n.tr('closingDetails'), bold, fallbacks),
          _keyValueTable(<List<String>>[
            <String>[
              l10n.tr('createdAt'),
              AppFormatters.dateTime(session.createdAt, localeCode: localeCode),
            ],
            <String>[
              l10n.tr('updatedAt'),
              AppFormatters.dateTime(session.updatedAt, localeCode: localeCode),
            ],
            <String>[l10n.tr('currency'), currency.code],
            if (session.blindCount)
              <String>[l10n.tr('blindCount'), l10n.tr('blindCountUsed')],
            <String>[l10n.tr('proofHash'), proofHash],
          ]),
          pw.SizedBox(height: 16),
          _sectionTitle(l10n.tr('cashCheck'), bold, fallbacks),
          _keyValueTable(<List<String>>[
            <String>[
              l10n.tr('actualInTill'),
              currency.formatMinor(total, localeCode: localeCode),
            ],
            if (session.expectedMinorUnits != null)
              <String>[
                l10n.tr('expectedState', {'code': currency.code}),
                currency.formatMinor(
                  session.expectedMinorUnits!,
                  localeCode: localeCode,
                ),
              ],
            if (difference != null)
              <String>[
                l10n.tr('difference'),
                currency.formatMinor(difference, localeCode: localeCode),
              ],
            if (session.floatMinorUnits != null)
              <String>[
                l10n.tr('leaveInTill', {'code': currency.code}),
                currency.formatMinor(
                  session.floatMinorUnits!,
                  localeCode: localeCode,
                ),
              ],
            if (deposit != null)
              <String>[
                l10n.tr('deposit'),
                currency.formatMinor(
                  deposit < 0 ? 0 : deposit,
                  localeCode: localeCode,
                ),
              ],
          ]),
          if (session.posReport != null) ...<pw.Widget>[
            pw.SizedBox(height: 16),
            _sectionTitle(l10n.tr('posReconciliation'), bold, fallbacks),
            _keyValueTable(<List<String>>[
              <String>[l10n.tr('posReportId'), session.posReport!.id],
              <String>[l10n.tr('posSource'), session.posReport!.sourceFileName],
              <String>[
                l10n.tr('posExpectedCash'),
                session.posReport!.expectedCashMinorUnits == null
                    ? '—'
                    : currency.formatMinor(
                        session.posReport!.expectedCashMinorUnits!,
                        localeCode: localeCode,
                      ),
              ],
              if (session.posReport!.cardMinorUnits != null)
                <String>[
                  l10n.tr('posCardTotal'),
                  currency.formatMinor(
                    session.posReport!.cardMinorUnits!,
                    localeCode: localeCode,
                  ),
                ],
              if (session.posReport!.totalSalesMinorUnits != null)
                <String>[
                  l10n.tr('posTotalSales'),
                  currency.formatMinor(
                    session.posReport!.totalSalesMinorUnits!,
                    localeCode: localeCode,
                  ),
                ],
              <String>[
                l10n.tr('posSourceHash'),
                session.posReport!.sourceSha256,
              ],
            ]),
          ],
          pw.SizedBox(height: 16),
          _sectionTitle(l10n.tr('cashBreakdown'), bold, fallbacks),
          _breakdownTable(
            headers: <String>[
              l10n.tr('denomination'),
              l10n.tr('quantity'),
              l10n.tr('subtotal'),
            ],
            rows: breakdownRows,
            bold: bold,
            fallbacks: fallbacks,
          ),
          if (session.note.trim().isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 16),
            _sectionTitle(l10n.tr('note'), bold, fallbacks),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(session.note.trim()),
            ),
          ],
          if (_identitySentence(session).isNotEmpty) ...<pw.Widget>[
            pw.SizedBox(height: 10),
            pw.Text(
              '${l10n.tr('closingIdentitySentence')}: ${_identitySentence(session)}',
              style: pw.TextStyle(
                font: regular,
                fontFallback: fallbacks,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ],
          pw.SizedBox(height: 20),
          _signatureRow(session, l10n, regular, bold, fallbacks),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.tr('signatureGraphicNotice'),
            style: pw.TextStyle(
              font: regular,
              fontFallback: fallbacks,
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  String buildPlainText({
    required CashCountSession session,
    required CurrencyDefinition currency,
    required Locale locale,
  }) {
    final l10n = AppLocalizations(locale);
    final localeCode = locale.toLanguageTag();
    final total = session.totalMinorUnits(currency);
    final difference = session.differenceMinorUnits(currency);
    final deposit = session.depositMinorUnits(currency);
    final used =
        currency.denominations
            .where((item) => session.quantityFor(item) > 0)
            .toList(growable: false)
          ..sort((a, b) {
            final kind = b.kind.index.compareTo(a.kind.index);
            return kind != 0 ? kind : b.minorUnits.compareTo(a.minorUnits);
          });
    final totalPieces = used.fold<int>(
      0,
      (sum, item) => sum + session.quantityFor(item),
    );
    final output = StringBuffer()
      ..writeln(l10n.tr('reportStartsWith'))
      ..writeln(
        session.closingTitle.trim().isEmpty
            ? l10n.tr('cashClosingReport')
            : session.closingTitle.trim(),
      )
      ..writeln('================================')
      ..writeln('${l10n.tr('documentNumber')}: ${session.documentNumber}')
      ..writeln(
        '${l10n.tr('updatedAt')}: '
        '${AppFormatters.dateTime(session.updatedAt, localeCode: localeCode)}',
      )
      ..writeln('${l10n.tr('currency')}: ${currency.code}');
    final proofHash = ClosingProofService.hashFor(session, currency);
    output.writeln('${l10n.tr('proofHash')}: $proofHash');

    output
      ..writeln()
      ..writeln(l10n.tr('cashCheck').toUpperCase())
      ..writeln('--------------------------------')
      ..writeln(
        '${l10n.tr('actualInTill')}: '
        '${currency.formatMinor(total, localeCode: localeCode)}',
      );
    if (session.expectedMinorUnits != null) {
      output.writeln(
        '${l10n.tr('expectedState', {'code': currency.code})}: '
        '${currency.formatMinor(session.expectedMinorUnits!, localeCode: localeCode)}',
      );
    }
    if (difference != null) {
      output.writeln(
        '${l10n.tr('difference')}: ${currency.formatMinor(difference, localeCode: localeCode)}',
      );
    }
    if (session.floatMinorUnits != null) {
      output.writeln(
        '${l10n.tr('leaveInTill', {'code': currency.code})}: '
        '${currency.formatMinor(session.floatMinorUnits!, localeCode: localeCode)}',
      );
    }
    if (deposit != null) {
      output.writeln(
        '${l10n.tr('deposit')}: '
        '${currency.formatMinor(deposit < 0 ? 0 : deposit, localeCode: localeCode)}',
      );
    }
    final pos = session.posReport;
    if (pos != null) {
      output
        ..writeln()
        ..writeln(l10n.tr('posReconciliation').toUpperCase())
        ..writeln('--------------------------------')
        ..writeln('${l10n.tr('posReportId')}: ${pos.id}')
        ..writeln('${l10n.tr('posSource')}: ${pos.sourceFileName}')
        ..writeln(
          '${l10n.tr('posExpectedCash')}: '
          '${currency.formatMinor(pos.expectedCashMinorUnits ?? 0, localeCode: localeCode)}',
        );
      if (pos.cardMinorUnits != null) {
        output.writeln(
          '${l10n.tr('posCardTotal')}: '
          '${currency.formatMinor(pos.cardMinorUnits!, localeCode: localeCode)}',
        );
      }
      if (pos.totalSalesMinorUnits != null) {
        output.writeln(
          '${l10n.tr('posTotalSales')}: '
          '${currency.formatMinor(pos.totalSalesMinorUnits!, localeCode: localeCode)}',
        );
      }
      output.writeln('${l10n.tr('posSourceHash')}: ${pos.sourceSha256}');
    }

    output
      ..writeln()
      ..writeln(l10n.tr('cashBreakdown').toUpperCase())
      ..writeln('--------------------------------');
    if (used.isEmpty) {
      output.writeln(l10n.tr('noDenominations'));
    } else {
      for (final denomination in used) {
        final quantity = session.quantityFor(denomination);
        output.writeln(
          '${_denominationLabel(denomination, localeCode, l10n)} × $quantity = '
          '${currency.formatMinor(denomination.minorUnits * quantity, localeCode: localeCode)}',
        );
      }
    }
    output.writeln('${l10n.tr('total')}: $totalPieces');
    output.writeln(
      '${l10n.tr('sumOfAmounts')}: ${currency.formatMinor(total, localeCode: localeCode)}',
    );
    if (session.note.trim().isNotEmpty) {
      output
        ..writeln()
        ..writeln('${l10n.tr('note')}: ${session.note.trim()}');
    }
    final identity = _identitySentence(session);
    if (identity.isNotEmpty) {
      output.writeln('${l10n.tr('closingIdentitySentence')}: $identity');
    }
    return output.toString().trimRight();
  }

  Uint8List buildCsv({
    required CashCountSession session,
    required CurrencyDefinition currency,
    required Locale locale,
  }) {
    final l10n = AppLocalizations(locale);
    final localeCode = locale.toLanguageTag();
    final rows = <List<String>>[
      <String>[l10n.tr('reportStartsWith'), ''],
      if (session.closingTitle.trim().isNotEmpty)
        <String>[l10n.tr('closingTitle'), session.closingTitle.trim()],
      <String>[l10n.tr('documentNumber'), session.documentNumber],
      <String>[
        l10n.tr('createdAt'),
        AppFormatters.dateTime(session.createdAt, localeCode: localeCode),
      ],
      <String>[
        l10n.tr('updatedAt'),
        AppFormatters.dateTime(session.updatedAt, localeCode: localeCode),
      ],
      <String>[l10n.tr('currency'), currency.code],
      <String>[l10n.tr('blindCount'), session.blindCount ? 'true' : 'false'],
      <String>[
        l10n.tr('proofHash'),
        ClosingProofService.hashFor(session, currency),
      ],
      if (session.posReport != null) ...<List<String>>[
        <String>[l10n.tr('posReconciliation'), ''],
        <String>[l10n.tr('posReportId'), session.posReport!.id],
        <String>[l10n.tr('posSource'), session.posReport!.sourceFileName],
        <String>[
          l10n.tr('posExpectedCash'),
          currency.formatMinor(
            session.posReport!.expectedCashMinorUnits ?? 0,
            localeCode: localeCode,
          ),
        ],
        if (session.posReport!.cardMinorUnits != null)
          <String>[
            l10n.tr('posCardTotal'),
            currency.formatMinor(
              session.posReport!.cardMinorUnits!,
              localeCode: localeCode,
            ),
          ],
        if (session.posReport!.totalSalesMinorUnits != null)
          <String>[
            l10n.tr('posTotalSales'),
            currency.formatMinor(
              session.posReport!.totalSalesMinorUnits!,
              localeCode: localeCode,
            ),
          ],
        <String>[l10n.tr('posSourceHash'), session.posReport!.sourceSha256],
      ],
      <String>[],
      <String>[
        l10n.tr('denomination'),
        l10n.tr('quantity'),
        l10n.tr('subtotal'),
      ],
      ...currency.denominations
          .where((item) => session.quantityFor(item) > 0)
          .map(
            (item) => <String>[
              _denominationLabel(item, localeCode, l10n),
              '${session.quantityFor(item)}',
              currency.formatMinor(
                item.minorUnits * session.quantityFor(item),
                localeCode: localeCode,
              ),
            ],
          ),
      <String>[
        l10n.tr('total'),
        '${currency.denominations.fold<int>(0, (sum, item) => sum + session.quantityFor(item))}',
        '',
      ],
      <String>[
        l10n.tr('sumOfAmounts'),
        '',
        currency.formatMinor(
          session.totalMinorUnits(currency),
          localeCode: localeCode,
        ),
      ],
      <String>[],
      <String>[
        l10n.tr('actualInTill'),
        currency.formatMinor(
          session.totalMinorUnits(currency),
          localeCode: localeCode,
        ),
      ],
      if (session.expectedMinorUnits != null)
        <String>[
          l10n.tr('expectedState', {'code': currency.code}),
          currency.formatMinor(
            session.expectedMinorUnits!,
            localeCode: localeCode,
          ),
        ],
      if (session.differenceMinorUnits(currency) case final difference?)
        <String>[
          l10n.tr('difference'),
          currency.formatMinor(difference, localeCode: localeCode),
        ],
      if (session.floatMinorUnits != null)
        <String>[
          l10n.tr('leaveInTill', {'code': currency.code}),
          currency.formatMinor(
            session.floatMinorUnits!,
            localeCode: localeCode,
          ),
        ],
      if (session.depositMinorUnits(currency) case final deposit?)
        <String>[
          l10n.tr('deposit'),
          currency.formatMinor(
            deposit < 0 ? 0 : deposit,
            localeCode: localeCode,
          ),
        ],
      <String>[l10n.tr('note'), session.note],
      <String>[l10n.tr('closingIdentitySentence'), _identitySentence(session)],
    ];
    final content = rows.map((row) => row.map(_csvCell).join(';')).join('\r\n');
    return Uint8List.fromList(utf8.encode('\uFEFFsep=;\r\n$content\r\n'));
  }

  static String _csvCell(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static pw.Widget _sectionTitle(
    String text,
    pw.Font bold,
    List<pw.Font> fallbacks,
  ) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.only(bottom: 5),
    margin: const pw.EdgeInsets.only(bottom: 7),
    decoration: const pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey300)),
    ),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        font: bold,
        fontFallback: fallbacks,
        fontSize: 13,
        color: PdfColors.blueGrey900,
      ),
    ),
  );

  static String _denominationLabel(
    Denomination denomination,
    String localeCode,
    AppLocalizations l10n,
  ) {
    final weight = denomination.calculationWeightMilligrams;
    if (weight == null) {
      return denomination.label;
    }
    return '${denomination.label}\n${AppFormatters.weight(weight, localeCode: localeCode, approximate: denomination.weightIsApproximate, unavailableLabel: l10n.tr('weightUnavailable'))}';
  }

  static String _identitySentence(CashCountSession session) {
    final values = <String>[
      session.businessName,
      session.businessRegistrationId,
      session.businessAddress,
      session.locationName,
      session.tillName,
      session.shiftName,
      session.cashierName,
      session.managerName,
    ].map((value) => value.trim()).where((value) => value.isNotEmpty);
    return values.join(' · ');
  }

  static pw.Widget _keyValueTable(List<List<String>> rows) => pw.Table(
    columnWidths: const <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2),
      1: pw.FlexColumnWidth(3),
    },
    border: pw.TableBorder.symmetric(
      inside: const pw.BorderSide(color: PdfColors.grey300, width: 0.5),
    ),
    children: rows
        .map(
          (row) => pw.TableRow(
            children: <pw.Widget>[
              _tableCell(row[0], background: PdfColors.grey100),
              _tableCell(
                row[1],
                style:
                    row[1].trimLeft().startsWith('-') ||
                        row[1].trimLeft().startsWith('−')
                    ? const pw.TextStyle(color: PdfColors.red)
                    : null,
              ),
            ],
          ),
        )
        .toList(growable: false),
  );

  static pw.Widget _breakdownTable({
    required List<String> headers,
    required List<List<String>> rows,
    required pw.Font bold,
    required List<pw.Font> fallbacks,
  }) => pw.Table(
    border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
    columnWidths: const <int, pw.TableColumnWidth>{
      0: pw.FlexColumnWidth(2),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(2),
    },
    children: <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
        children: headers
            .asMap()
            .entries
            .map(
              (entry) => _tableCell(
                entry.value,
                alignment: entry.key == 1
                    ? pw.Alignment.center
                    : entry.key == 2
                    ? pw.Alignment.centerRight
                    : pw.Alignment.centerLeft,
                style: pw.TextStyle(font: bold, fontFallback: fallbacks),
              ),
            )
            .toList(growable: false),
      ),
      ...rows.map(
        (row) => pw.TableRow(
          children: row
              .asMap()
              .entries
              .map(
                (entry) => _tableCell(
                  entry.value,
                  alignment: entry.key == 1
                      ? pw.Alignment.center
                      : entry.key == 2
                      ? pw.Alignment.centerRight
                      : pw.Alignment.centerLeft,
                ),
              )
              .toList(growable: false),
        ),
      ),
    ],
  );

  static pw.Widget _tableCell(
    String value, {
    PdfColor? background,
    pw.TextStyle? style,
    pw.Alignment alignment = pw.Alignment.centerLeft,
  }) => pw.Container(
    color: background,
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
    child: style == null ? pw.Text(value) : pw.Text(value, style: style),
  );

  static pw.Widget _signatureRow(
    CashCountSession session,
    AppLocalizations l10n,
    pw.Font regular,
    pw.Font bold,
    List<pw.Font> fallbacks,
  ) => pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: <pw.Widget>[
      pw.Expanded(
        child: _signatureBox(
          label: l10n.tr('cashierSignature'),
          name: session.cashierName,
          encodedPng: session.cashierSignaturePngBase64,
          missingText: l10n.tr('signatureMissing'),
          regular: regular,
          bold: bold,
          fallbacks: fallbacks,
        ),
      ),
      pw.SizedBox(width: 16),
      pw.Expanded(
        child: _signatureBox(
          label: l10n.tr('managerSignature'),
          name: session.managerName,
          encodedPng: session.managerSignaturePngBase64,
          missingText: l10n.tr('signatureMissing'),
          regular: regular,
          bold: bold,
          fallbacks: fallbacks,
        ),
      ),
    ],
  );

  static pw.Widget _signatureBox({
    required String label,
    required String name,
    required String? encodedPng,
    required String missingText,
    required pw.Font regular,
    required pw.Font bold,
    required List<pw.Font> fallbacks,
  }) {
    pw.Widget image;
    try {
      final bytes = encodedPng == null ? null : base64Decode(encodedPng);
      image = bytes == null || bytes.isEmpty
          ? pw.Center(
              child: pw.Text(
                missingText,
                style: pw.TextStyle(
                  font: regular,
                  fontFallback: fallbacks,
                  fontSize: 8,
                  color: PdfColors.grey600,
                ),
              ),
            )
          : pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain);
    } on FormatException {
      image = pw.Center(
        child: pw.Text(
          missingText,
          style: pw.TextStyle(
            font: regular,
            fontFallback: fallbacks,
            fontSize: 8,
            color: PdfColors.grey600,
          ),
        ),
      );
    }
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: <pw.Widget>[
        pw.Text(
          label,
          style: pw.TextStyle(
            font: bold,
            fontFallback: fallbacks,
            fontSize: 10,
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Container(
          height: 70,
          width: double.infinity,
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey500),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: image,
        ),
        if (name.trim().isNotEmpty) ...<pw.Widget>[
          pw.SizedBox(height: 3),
          pw.Text(
            name.trim(),
            style: pw.TextStyle(
              font: regular,
              fontFallback: fallbacks,
              fontSize: 8,
            ),
          ),
        ],
      ],
    );
  }
}
