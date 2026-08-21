import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/currency_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/cash_count_session.dart';
import '../models/currency_definition.dart';
import '../services/closing_proof_service.dart';
import '../state/app_scope.dart';
import 'count_screen.dart';
import 'report_preview_screen.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({required this.sessionId, super.key});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    CashCountSession? session;
    for (final item in controller.sessions) {
      if (item.id == sessionId) {
        session = item;
        break;
      }
    }
    if (session == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(context.tr('missingSession'))),
      );
    }

    final current = session;
    final currency = current.currencyFor(
      CurrencyCatalog.byCode(current.currencyCode),
    );
    final total = current.totalMinorUnits(currency);
    final difference = current.differenceMinorUnits(currency);
    final deposit = current.depositMinorUnits(currency);
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    final used =
        currency.denominations
            .where((denomination) => current.quantityFor(denomination) > 0)
            .toList(growable: false)
          ..sort((a, b) => b.minorUnits.compareTo(a.minorUnits));

    return Scaffold(
      appBar: AppBar(
        title: Text('${current.currencyCode} · ${context.tr('count')}'),
        actions: <Widget>[
          IconButton(
            tooltip: context.tr('cashClosingReport'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReportPreviewScreen(session: current),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: context.tr('edit'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CountScreen(existingSession: current),
              ),
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(context.tr('actualInTill')),
                  const SizedBox(height: 4),
                  Text(
                    currency.formatMinor(total, localeCode: localeCode),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppFormatters.dateTime(
                      current.updatedAt,
                      localeCode: localeCode,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${context.tr('documentNumber')}: ${current.documentNumber}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ReportPreviewScreen(session: current),
              ),
            ),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(context.tr('openReport')),
          ),
          if (current.closingTitle.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 16),
            Text(
              current.closingTitle.trim(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
          const SizedBox(height: 12),
          _ProofCard(session: current, currency: currency),
          if (current.posReport != null) ...<Widget>[
            const SizedBox(height: 12),
            _PosReportCard(session: current, currency: currency),
          ],
          if (current.expectedMinorUnits != null)
            _SummaryRow(
              label: context.tr('expectedState', {'code': currency.code}),
              value: currency.formatMinor(
                current.expectedMinorUnits!,
                localeCode: localeCode,
              ),
            ),
          if (difference != null)
            _SummaryRow(
              label: context.tr('difference'),
              value: currency.formatMinor(difference, localeCode: localeCode),
              emphasized: true,
              negative: difference < 0,
            ),
          if (current.floatMinorUnits != null)
            _SummaryRow(
              label: context.tr('leaveInTill', {'code': currency.code}),
              value: currency.formatMinor(
                current.floatMinorUnits!,
                localeCode: localeCode,
              ),
            ),
          if (deposit != null)
            _SummaryRow(
              label: context.tr('deposit'),
              value: currency.formatMinor(
                deposit < 0 ? 0 : deposit,
                localeCode: localeCode,
              ),
              emphasized: true,
            ),
          const SizedBox(height: 24),
          Text(
            context.tr('cashBreakdown'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (used.isEmpty)
            Text(context.tr('noDenominations'))
          else
            ...used.map((denomination) {
              final quantity = current.quantityFor(denomination);
              return Card(
                child: ListTile(
                  title: Text(denomination.label),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(context.tr('pieces', {'count': quantity})),
                      if (denomination.calculationWeightMilligrams != null)
                        Text(
                          AppFormatters.weight(
                            denomination.calculationWeightMilligrams,
                            localeCode: localeCode,
                            approximate: denomination.weightIsApproximate,
                            unavailableLabel: context.tr('weightUnavailable'),
                          ),
                        ),
                    ],
                  ),
                  trailing: Text(
                    currency.formatMinor(
                      denomination.minorUnits * quantity,
                      localeCode: localeCode,
                    ),
                  ),
                ),
              );
            }),
          _SummaryRow(
            label: context.tr('total'),
            value:
                '${used.fold<int>(0, (sum, item) => sum + current.quantityFor(item))}',
          ),
          _SummaryRow(
            label: context.tr('sumOfAmounts'),
            value: currency.formatMinor(total, localeCode: localeCode),
            emphasized: true,
          ),
          if (current.note.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              context.tr('note'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(current.note),
              ),
            ),
          ],
          if (current.hasBusinessIdentity || current.blindCount) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              '${context.tr('closingIdentitySentence')}: ${_identitySentence(current)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (current.cashierSignaturePngBase64 != null ||
              current.managerSignaturePngBase64 != null) ...<Widget>[
            const SizedBox(height: 24),
            Text(
              context.tr('signatures'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _SignaturePreview(
                    label: context.tr('cashierSignature'),
                    encodedPng: current.cashierSignaturePngBase64,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SignaturePreview(
                    label: context.tr('managerSignature'),
                    encodedPng: current.managerSignaturePngBase64,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              context.tr('signatureGraphicNotice'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

String _identitySentence(CashCountSession session) => <String>[
  session.businessName,
  session.businessRegistrationId,
  session.businessAddress,
  session.locationName,
  session.tillName,
  session.shiftName,
  session.cashierName,
  session.managerName,
].map((value) => value.trim()).where((value) => value.isNotEmpty).join(' · ');

class _ProofCard extends StatelessWidget {
  const _ProofCard({required this.session, required this.currency});

  final CashCountSession session;
  final CurrencyDefinition currency;

  @override
  Widget build(BuildContext context) {
    final hash = ClosingProofService.hashFor(session, currency);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.verified_outlined),
        title: Text(context.tr('proofHash')),
        subtitle: SelectableText(hash),
        isThreeLine: true,
      ),
    );
  }
}

class _PosReportCard extends StatelessWidget {
  const _PosReportCard({required this.session, required this.currency});

  final CashCountSession session;
  final CurrencyDefinition currency;

  @override
  Widget build(BuildContext context) {
    final report = session.posReport!;
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.tr('posReconciliation'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('${context.tr('posReportId')}: ${report.id}'),
            Text('${context.tr('posSource')}: ${report.sourceFileName}'),
            Text(
              '${context.tr('posExpectedCash')}: '
              '${currency.formatMinor(report.expectedCashMinorUnits ?? 0, localeCode: localeCode)}',
            ),
            if (report.cardMinorUnits != null)
              Text(
                '${context.tr('posCardTotal')}: '
                '${currency.formatMinor(report.cardMinorUnits!, localeCode: localeCode)}',
              ),
            if (report.totalSalesMinorUnits != null)
              Text(
                '${context.tr('posTotalSales')}: '
                '${currency.formatMinor(report.totalSalesMinorUnits!, localeCode: localeCode)}',
              ),
            const SizedBox(height: 4),
            SelectableText(
              '${context.tr('posSourceHash')}: ${report.sourceSha256}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePreview extends StatelessWidget {
  const _SignaturePreview({required this.label, required this.encodedPng});

  final String label;
  final String? encodedPng;

  @override
  Widget build(BuildContext context) {
    Widget image = Center(child: Text(context.tr('signatureMissing')));
    try {
      final bytes = encodedPng == null ? null : base64Decode(encodedPng!);
      if (bytes != null && bytes.isNotEmpty) {
        image = Image.memory(bytes, fit: BoxFit.contain);
      }
    } on FormatException {
      // The saved record remains visible even if an old signature is malformed.
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            SizedBox(height: 88, width: double.infinity, child: image),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
    this.negative = false,
  });

  final String label;
  final String value;
  final bool emphasized;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: <Widget>[
            Expanded(child: Text(label)),
            Text(
              value,
              style: emphasized
                  ? Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: negative
                          ? Theme.of(context).colorScheme.error
                          : null,
                    )
                  : Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: negative
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
