import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../data/currency_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/cash_count_session.dart';
import '../services/closing_report_service.dart';

class ReportPreviewScreen extends StatefulWidget {
  const ReportPreviewScreen({required this.session, super.key});

  final CashCountSession session;

  @override
  State<ReportPreviewScreen> createState() => _ReportPreviewScreenState();
}

class _ReportPreviewScreenState extends State<ReportPreviewScreen> {
  static const ClosingReportService _reports = ClosingReportService();

  Future<Uint8List>? _pdf;
  String? _pdfFingerprint;
  var _busy = false;

  String get _pdfFileName =>
      '${ClosingReportService.fileStem(widget.session)}.pdf';
  String get _csvFileName =>
      '${ClosingReportService.fileStem(widget.session)}.csv';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final locale = Localizations.localeOf(context);
    final fingerprint = locale.toLanguageTag();
    if (_pdfFingerprint == fingerprint) {
      return;
    }
    _pdfFingerprint = fingerprint;
    _pdf = _reports.buildPdf(
      session: widget.session,
      currency: widget.session.currencyFor(
        CurrencyCatalog.byCode(widget.session.currencyCode),
      ),
      locale: locale,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reportPreview'))),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PdfPreview(
              build: (_) => _pdf!,
              initialPageFormat: PdfPageFormat.a4,
              dynamicLayout: false,
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              pdfFileName: _pdfFileName,
              onError: (_, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    context.tr('reportExportFailed', {'error': error}),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: _busy
                  ? const LinearProgressIndicator()
                  : Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: _openZoomedPreview,
                          icon: const Icon(Icons.zoom_in),
                          label: Text(context.tr('zoomPreview')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _printPdf,
                          icon: const Icon(Icons.print_outlined),
                          label: Text(context.tr('printPdf')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _savePdf,
                          icon: const Icon(Icons.download_outlined),
                          label: Text(context.tr('downloadPdf')),
                        ),
                        FilledButton.tonalIcon(
                          onPressed: _sharePdf,
                          icon: const Icon(Icons.share_outlined),
                          label: Text(context.tr('sharePdf')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _saveCsv,
                          icon: const Icon(Icons.table_view_outlined),
                          label: Text(context.tr('downloadCsv')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _shareCsv,
                          icon: const Icon(Icons.ios_share_outlined),
                          label: Text(context.tr('shareCsv')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _copyText,
                          icon: const Icon(Icons.copy_all_outlined),
                          label: Text(context.tr('copyFinalText')),
                        ),
                        OutlinedButton.icon(
                          onPressed: _shareText,
                          icon: const Icon(Icons.send_outlined),
                          label: Text(context.tr('shareFinalText')),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf() => _runAction(() async {
    final bytes = await _pdf!;
    await Printing.layoutPdf(
      name: _pdfFileName,
      format: PdfPageFormat.a4,
      dynamicLayout: false,
      onLayout: (_) async => bytes,
    );
  });

  Future<void> _openZoomedPreview() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text(context.tr('zoomPreview')),
            actions: <Widget>[
              IconButton(
                tooltip: context.tr('close'),
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          body: PdfPreview(
            build: (_) => _pdf!,
            initialPageFormat: PdfPageFormat.a4,
            dynamicLayout: false,
            useActions: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: _pdfFileName,
          ),
        ),
      ),
    );
  }

  Future<void> _savePdf() => _runAction(() async {
    final path = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: await _pdf!,
        fileName: _pdfFileName,
        mimeTypesFilter: const <String>['application/pdf'],
      ),
    );
    if (path != null && mounted) {
      _showSaved(path);
    }
  });

  Future<void> _sharePdf() => _runAction(() async {
    final subject = context.tr('cashClosingReport');
    final bounds = _shareBounds();
    final bytes = await _pdf!;
    await Printing.sharePdf(
      bytes: bytes,
      filename: _pdfFileName,
      bounds: bounds,
      subject: subject,
    );
  });

  Future<void> _saveCsv() => _runAction(() async {
    final bytes = _csvBytes();
    final path = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: bytes,
        fileName: _csvFileName,
        mimeTypesFilter: const <String>['text/csv'],
      ),
    );
    if (path != null && mounted) {
      _showSaved(path);
    }
  });

  Future<void> _shareCsv() => _runAction(() async {
    await SharePlus.instance.share(
      ShareParams(
        title: context.tr('cashClosingReport'),
        subject: context.tr('cashClosingReport'),
        files: <XFile>[XFile.fromData(_csvBytes(), mimeType: 'text/csv')],
        fileNameOverrides: <String>[_csvFileName],
        sharePositionOrigin: _shareBounds(),
      ),
    );
  });

  Future<void> _copyText() => _runAction(() async {
    await Clipboard.setData(ClipboardData(text: _plainText()));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('finalTextCopied'))));
    }
  });

  Future<void> _shareText() => _runAction(() async {
    final title = context.tr('cashClosingReport');
    await SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: title,
        text: _plainText(),
        sharePositionOrigin: _shareBounds(),
      ),
    );
  });

  Uint8List _csvBytes() => _reports.buildCsv(
    session: widget.session,
    currency: widget.session.currencyFor(
      CurrencyCatalog.byCode(widget.session.currencyCode),
    ),
    locale: Localizations.localeOf(context),
  );

  String _plainText() => _reports.buildPlainText(
    session: widget.session,
    currency: widget.session.currencyFor(
      CurrencyCatalog.byCode(widget.session.currencyCode),
    ),
    locale: Localizations.localeOf(context),
  );

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('reportExportFailed', {'error': error})),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Rect _shareBounds() {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return const Rect.fromLTWH(0, 0, 1, 1);
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  void _showSaved(String path) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('reportSaved', {'path': path}))),
    );
  }
}
