import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter/services.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../core/formatters.dart';
import '../data/currency_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/cash_count_session.dart';
import '../models/count_mode.dart';
import '../models/currency_definition.dart';
import '../models/pos_reconciliation.dart';
import '../models/till_template.dart';
import '../services/closing_proof_service.dart';
import '../services/pos_import_service.dart';
import '../state/app_scope.dart';
import '../widgets/denomination_row.dart';
import 'signature_capture_screen.dart';

class CountScreen extends StatefulWidget {
  const CountScreen({
    this.initialCurrencyCode,
    this.existingSession,
    this.mode = CountMode.professional,
    this.template,
    super.key,
  }) : assert(
         initialCurrencyCode != null || existingSession != null,
         'A currency or an existing session is required.',
       );

  final String? initialCurrencyCode;
  final CashCountSession? existingSession;
  final CountMode mode;
  final TillTemplate? template;

  @override
  State<CountScreen> createState() => _CountScreenState();
}

class _CountScreenState extends State<CountScreen> {
  late String _currencyCode;
  late String _sessionId;
  late String _documentNumber;
  late DateTime _createdAt;
  late Map<String, int> _quantities;
  late CountMode _mode;
  late List<Denomination> _customDenominationSnapshots;
  late bool _blindCount;
  DateTime? _blindCountLockedAt;
  String? _cashierSignaturePngBase64;
  String? _managerSignaturePngBase64;
  PosReconciliation? _posReport;

  late final TextEditingController _expectedController;
  late final TextEditingController _floatController;
  late final TextEditingController _noteController;
  late final TextEditingController _closingTitleController;
  late final TextEditingController _businessNameController;
  late final TextEditingController _registrationIdController;
  late final TextEditingController _businessAddressController;
  late final TextEditingController _locationNameController;
  late final TextEditingController _tillNameController;
  late final TextEditingController _cashierNameController;
  late final TextEditingController _managerNameController;
  late final TextEditingController _shiftNameController;

  var _saving = false;
  var _currencyFieldRevision = 0;
  var _quickStep = 1;
  var _posImportBusy = false;

  CurrencyDefinition get _currency {
    final configured = AppScope.read(
      context,
    ).countingCurrency(_currencyCode, keepVisible: _quantities.keys.toSet());
    final knownIds = configured.denominations.map((item) => item.id).toSet();
    return configured.copyWithDenominations(<Denomination>[
      ...configured.denominations,
      ..._customDenominationSnapshots.where((item) => knownIds.add(item.id)),
    ]);
  }

  bool get _quantitiesLocked => _blindCount && _blindCountLockedAt != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingSession;
    final app = AppScope.read(context);
    final template = widget.template;
    final initialCode =
        template?.currencyCode ?? widget.initialCurrencyCode ?? 'CZK';
    final configured = app.configuredCurrency(initialCode);
    final customSnapshots = configured.denominations
        .where((item) => item.customId != null)
        .toList(growable: false);
    final seed =
        existing ??
        CashCountSession.create(
          initialCode,
          profile: template?.profile ?? app.businessProfile,
          mode: widget.mode,
          floatMinorUnits: template?.floatMinorUnits,
          customDenominations: customSnapshots,
        );
    _currencyCode = seed.currencyCode;
    _sessionId = seed.id;
    _documentNumber = seed.documentNumber;
    _createdAt = seed.createdAt;
    _quantities = Map<String, int>.from(seed.quantities);
    _mode = seed.mode;
    _customDenominationSnapshots = List<Denomination>.from(
      seed.customDenominations,
    );
    _blindCount = seed.blindCount;
    _blindCountLockedAt = seed.blindCountLockedAt;
    _cashierSignaturePngBase64 = seed.cashierSignaturePngBase64;
    _managerSignaturePngBase64 = seed.managerSignaturePngBase64;
    _posReport = seed.posReport;
    _expectedController = TextEditingController(
      text: AppFormatters.moneyInputFromMinor(
        seed.expectedMinorUnits,
        fractionDigits: _currency.fractionDigits,
      ),
    );
    _floatController = TextEditingController(
      text: AppFormatters.moneyInputFromMinor(
        seed.floatMinorUnits,
        fractionDigits: _currency.fractionDigits,
      ),
    );
    _noteController = TextEditingController(text: seed.note);
    _closingTitleController = TextEditingController(text: seed.closingTitle);
    _businessNameController = TextEditingController(text: seed.businessName);
    _registrationIdController = TextEditingController(
      text: seed.businessRegistrationId,
    );
    _businessAddressController = TextEditingController(
      text: seed.businessAddress,
    );
    _locationNameController = TextEditingController(text: seed.locationName);
    _tillNameController = TextEditingController(text: seed.tillName);
    _cashierNameController = TextEditingController(text: seed.cashierName);
    _managerNameController = TextEditingController(text: seed.managerName);
    _shiftNameController = TextEditingController(text: seed.shiftName);
  }

  @override
  void dispose() {
    _expectedController.dispose();
    _floatController.dispose();
    _noteController.dispose();
    _closingTitleController.dispose();
    _businessNameController.dispose();
    _registrationIdController.dispose();
    _businessAddressController.dispose();
    _locationNameController.dispose();
    _tillNameController.dispose();
    _cashierNameController.dispose();
    _managerNameController.dispose();
    _shiftNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final total = _totalMinorUnits;
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    final expected = _blindCount && !_quantitiesLocked
        ? null
        : AppFormatters.parseMoneyToMinor(
            _expectedController.text,
            fractionDigits: _currency.fractionDigits,
          );
    final difference = expected == null ? null : total - expected;
    final banknotes = _currency.banknotes.reversed.toList(growable: false);
    final coins = _currency.coins.reversed.toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr(widget.existingSession == null ? 'newCount' : 'editCount'),
        ),
      ),
      body: ListView(
        // Denomination rows stay mounted just beyond the viewport so hardware
        // keyboard/accessibility focus and fast repeated entry remain stable.
        scrollCacheExtent: const ScrollCacheExtent.pixels(1600),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 160),
        children: <Widget>[
          DropdownButtonFormField<String>(
            key: ValueKey('currency-$_currencyCode-$_currencyFieldRevision'),
            initialValue: _currencyCode,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('currency'),
              prefixIcon: const Icon(Icons.currency_exchange),
            ),
            items:
                CurrencyCatalog.displayOrder(
                      _currencyCode,
                      favoriteCodes: app.favoriteCurrencyCodes,
                    )
                    .map(
                      (currency) => DropdownMenuItem<String>(
                        value: currency.code,
                        child: Text(
                          '${currency.code} · '
                          '${context.tr('currency${currency.code}')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
            onChanged: _quantitiesLocked
                ? null
                : (code) {
                    if (code != null && code != _currencyCode) {
                      _changeCurrency(code);
                    }
                  },
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Icon(
                _mode == CountMode.quick
                    ? Icons.flash_on_outlined
                    : Icons.assignment_turned_in_outlined,
              ),
              title: Text(
                context.tr(
                  _mode == CountMode.quick ? 'quickCount' : 'professionalClose',
                ),
              ),
              subtitle: Text(
                context.tr(
                  _mode == CountMode.quick
                      ? 'quickCountHelp'
                      : 'professionalCloseHelp',
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_mode == CountMode.professional)
            Card(
              child: SwitchListTile(
                value: _blindCount,
                onChanged: _quantitiesLocked
                    ? null
                    : (value) => setState(() {
                        _blindCount = value;
                        if (!value) {
                          _blindCountLockedAt = null;
                        }
                      }),
                secondary: const Icon(Icons.visibility_off_outlined),
                title: Text(context.tr('blindCount')),
                subtitle: Text(
                  _quantitiesLocked
                      ? context.tr('blindCountLocked')
                      : context.tr('blindCountHelp'),
                ),
              ),
            ),
          if (_mode == CountMode.professional) const SizedBox(height: 12),
          SegmentedButton<int>(
            segments: const <ButtonSegment<int>>[
              ButtonSegment<int>(value: 1, label: Text('×1')),
              ButtonSegment<int>(value: 10, label: Text('×10')),
              ButtonSegment<int>(value: 50, label: Text('×50')),
              ButtonSegment<int>(value: 100, label: Text('×100')),
            ],
            selected: <int>{_quickStep},
            onSelectionChanged: _quantitiesLocked
                ? null
                : (values) => setState(() => _quickStep = values.first),
          ),
          const SizedBox(height: 6),
          Text(
            context.tr('tapToAddHelp'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: context.tr('banknotes'),
            icon: Icons.payments_outlined,
            onClear:
                !_quantitiesLocked &&
                    banknotes.any((item) => _quantity(item) > 0)
                ? () => _clearSection(banknotes)
                : null,
          ),
          const SizedBox(height: 8),
          ...banknotes.map(_denominationRow),
          const SizedBox(height: 24),
          _SectionHeader(
            title: context.tr('coins'),
            icon: Icons.toll_outlined,
            onClear:
                !_quantitiesLocked && coins.any((item) => _quantity(item) > 0)
                ? () => _clearSection(coins)
                : null,
          ),
          const SizedBox(height: 8),
          ...coins.map(_denominationRow),
          const SizedBox(height: 24),
          if (_mode == CountMode.professional) ...<Widget>[
            _closingDetailsCard(),
            const SizedBox(height: 24),
            Text(
              context.tr('cashCheck'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
          ],
          if (_mode == CountMode.professional &&
              _blindCount &&
              !_quantitiesLocked)
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(context.tr('blindCountBeforeReveal')),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _lockBlindCount,
                      icon: const Icon(Icons.lock_outline),
                      label: Text(context.tr('finishBlindCount')),
                    ),
                  ],
                ),
              ),
            )
          else if (_mode == CountMode.professional) ...<Widget>[
            TextField(
              controller: _expectedController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]')),
              ],
              decoration: InputDecoration(
                labelText: context.tr('expectedState', {
                  'code': _currency.code,
                }),
                helperText: context.tr('expectedHelp'),
                prefixIcon: const Icon(Icons.fact_check_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _floatController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]')),
              ],
              decoration: InputDecoration(
                labelText: context.tr('leaveInTill', {'code': _currency.code}),
                helperText: context.tr('leaveInTillHelp'),
                prefixIcon: const Icon(Icons.savings_outlined),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
          if (_mode == CountMode.professional) const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: const <TextInputFormatter>[
              SentenceCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              labelText: context.tr('note'),
              prefixIcon: const Icon(Icons.notes_outlined),
            ),
          ),
          if (difference != null) ...<Widget>[
            const SizedBox(height: 16),
            Card(
              color: difference == 0
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.tertiaryContainer,
              child: ListTile(
                title: Text(context.tr('difference')),
                trailing: Text(
                  _currency.formatMinor(difference, localeCode: localeCode),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: difference < 0
                        ? Theme.of(context).colorScheme.error
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Material(
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(context.tr('total')),
                      Text(
                        _currency.formatMinor(total, localeCode: localeCode),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(context.tr('save')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _closingDetailsCard() {
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.assignment_outlined),
        title: Text(context.tr('closingDetails')),
        subtitle: Text(_documentNumber),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: <Widget>[
          TextField(
            controller: _closingTitleController,
            textCapitalization: TextCapitalization.sentences,
            inputFormatters: const <TextInputFormatter>[
              SentenceCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              labelText: context.tr('closingTitle'),
              helperText: context.tr('closingTitleHelp'),
              prefixIcon: const Icon(Icons.title_outlined),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('closingSnapshotHelp'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _posImportBusy ? null : _importPosReport,
            icon: _posImportBusy
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.point_of_sale_outlined),
            label: Text(context.tr('importPosReport')),
          ),
          if (_posReport != null) ...<Widget>[
            const SizedBox(height: 8),
            _posReportSummary(),
          ],
          const SizedBox(height: 8),
          _detailField(
            _businessNameController,
            context.tr('businessName'),
            Icons.business_outlined,
          ),
          _detailField(
            _registrationIdController,
            context.tr('registrationId'),
            Icons.badge_outlined,
            capitalize: false,
          ),
          _detailField(
            _businessAddressController,
            context.tr('businessAddress'),
            Icons.location_on_outlined,
          ),
          _detailField(
            _locationNameController,
            context.tr('locationName'),
            Icons.store_outlined,
          ),
          _detailField(
            _tillNameController,
            context.tr('tillName'),
            Icons.point_of_sale_outlined,
          ),
          _detailField(
            _shiftNameController,
            context.tr('shiftName'),
            Icons.schedule_outlined,
          ),
          _detailField(
            _cashierNameController,
            context.tr('cashierName'),
            Icons.person_outline,
          ),
          _signatureField(
            label: context.tr('cashierSignature'),
            value: _cashierSignaturePngBase64,
            onChanged: (value) {
              setState(() => _cashierSignaturePngBase64 = value);
            },
          ),
          _detailField(
            _managerNameController,
            context.tr('managerName'),
            Icons.supervisor_account_outlined,
          ),
          _signatureField(
            label: context.tr('managerSignature'),
            value: _managerSignaturePngBase64,
            onChanged: (value) {
              setState(() => _managerSignaturePngBase64 = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _detailField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool capitalize = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        textCapitalization: capitalize
            ? TextCapitalization.sentences
            : TextCapitalization.none,
        inputFormatters: capitalize
            ? const <TextInputFormatter>[SentenceCaseTextFormatter()]
            : null,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  Future<void> _importPosReport() async {
    final path = await FlutterFileDialog.pickFile(
      params: const OpenFileDialogParams(
        fileExtensionsFilter: <String>['csv', 'txt'],
        mimeTypesFilter: <String>['text/csv', 'text/plain'],
        copyFileToCacheDir: true,
      ),
    );
    if (path == null || !mounted) {
      return;
    }
    setState(() => _posImportBusy = true);
    try {
      final report = const PosImportService().parse(
        bytes: await File(path).readAsBytes(),
        sourceFileName: path.split(Platform.pathSeparator).last,
      );
      if (report.currencyCode != _currencyCode) {
        throw const PosImportException('currencyMismatch');
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _posReport = report;
        _expectedController.text = AppFormatters.moneyInputFromMinor(
          report.expectedCashMinorUnits,
          fractionDigits: _currency.fractionDigits,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('posImportSucceeded'))));
    } on PosImportException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_posImportError(error.code))));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('posImportFailed'))));
      }
    } finally {
      if (mounted) {
        setState(() => _posImportBusy = false);
      }
    }
  }

  String _posImportError(String code) {
    return switch (code) {
      'emptyFile' => context.tr('posImportEmpty'),
      'currencyMissing' => context.tr('posImportCurrencyMissing'),
      'expectedCashMissing' => context.tr('posImportExpectedMissing'),
      'amountInvalid' => context.tr('posImportAmountInvalid'),
      'currencyMismatch' => context.tr('posImportCurrencyMismatch'),
      _ => context.tr('posImportFailed'),
    };
  }

  Widget _posReportSummary() {
    final report = _posReport!;
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    final rows = <String>[
      '${context.tr('posReportId')}: ${report.id}',
      '${context.tr('posSource')}: ${report.sourceFileName}',
      '${context.tr('posExpectedCash')}: ${_currency.formatMinor(report.expectedCashMinorUnits ?? 0, localeCode: localeCode)}',
      if (report.cardMinorUnits != null)
        '${context.tr('posCardTotal')}: ${_currency.formatMinor(report.cardMinorUnits!, localeCode: localeCode)}',
      if (report.totalSalesMinorUnits != null)
        '${context.tr('posTotalSales')}: ${_currency.formatMinor(report.totalSalesMinorUnits!, localeCode: localeCode)}',
      '${context.tr('posSourceHash')}: ${report.sourceSha256.substring(0, 16)}…',
    ];
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: rows.map(Text.new).toList(growable: false),
        ),
      ),
    );
  }

  Widget _signatureField({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    Widget preview = const Icon(Icons.draw_outlined, size: 32);
    if (value != null) {
      try {
        preview = Image.memory(
          base64Decode(value),
          width: 96,
          height: 44,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
        );
      } on FormatException {
        preview = const Icon(Icons.broken_image_outlined);
      }
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: SizedBox(width: 96, child: Center(child: preview)),
          title: Text(label),
          subtitle: Text(
            value == null
                ? context.tr('signatureMissing')
                : context.tr('signatureCaptured'),
          ),
          trailing: value == null
              ? const Icon(Icons.chevron_right)
              : IconButton(
                  tooltip: context.tr('clear'),
                  onPressed: () => onChanged(null),
                  icon: const Icon(Icons.delete_outline),
                ),
          onTap: () async {
            final result = await Navigator.of(context).push<String>(
              MaterialPageRoute<String>(
                builder: (_) => SignatureCaptureScreen(title: label),
              ),
            );
            if (result != null && mounted) {
              onChanged(result);
            }
          },
        ),
      ),
    );
  }

  Widget _denominationRow(Denomination denomination) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DenominationRow(
        currency: _currency,
        denomination: denomination,
        quantity: _quantity(denomination),
        enabled: !_quantitiesLocked,
        onChanged: (value) => _setQuantity(denomination, value),
        onEdit: () => _editQuantity(denomination),
        step: _quickStep,
      ),
    );
  }

  int get _totalMinorUnits {
    var total = 0;
    for (final denomination in _currency.denominations) {
      total += denomination.minorUnits * _quantity(denomination);
    }
    return total;
  }

  int _quantity(Denomination denomination) => _quantities[denomination.id] ?? 0;

  void _setQuantity(Denomination denomination, int value) {
    if (_quantitiesLocked) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      if (value <= 0) {
        _quantities.remove(denomination.id);
      } else {
        _quantities[denomination.id] = value;
      }
    });
  }

  Future<void> _editQuantity(Denomination denomination) async {
    if (_quantitiesLocked) {
      return;
    }
    final inputController = TextEditingController(
      text: _quantity(denomination).toString(),
    );
    final result = await showDialog<int>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('quantityTitle', {'label': denomination.label})),
        content: TextField(
          controller: inputController,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly,
          ],
          onSubmitted: (value) =>
              Navigator.pop(dialogContext, int.tryParse(value) ?? 0),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              int.tryParse(inputController.text) ?? 0,
            ),
            child: Text(context.tr('confirm')),
          ),
        ],
      ),
    );
    inputController.dispose();
    if (result != null && mounted) {
      _setQuantity(denomination, result);
    }
  }

  Future<void> _changeCurrency(String code) async {
    if (_quantitiesLocked) {
      return;
    }
    final hasEnteredValues =
        _quantities.isNotEmpty ||
        _expectedController.text.trim().isNotEmpty ||
        _floatController.text.trim().isNotEmpty;
    if (hasEnteredValues) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(context.tr('changeCurrencyTitle')),
          content: Text(context.tr('changeCurrencyBody')),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(context.tr('keep')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(context.tr('change')),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) {
        if (mounted) {
          setState(() => _currencyFieldRevision += 1);
        }
        return;
      }
    }
    setState(() {
      _currencyCode = code;
      _currencyFieldRevision += 1;
      _quantities.clear();
      _expectedController.clear();
      _floatController.clear();
      _blindCountLockedAt = null;
      _cashierSignaturePngBase64 = null;
      _managerSignaturePngBase64 = null;
      _posReport = null;
      _customDenominationSnapshots = AppScope.read(context)
          .configuredCurrency(code)
          .denominations
          .where((item) => item.customId != null)
          .toList(growable: false);
    });
  }

  Future<void> _clearSection(List<Denomination> denominations) async {
    if (_quantitiesLocked) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('clearSectionTitle')),
        content: Text(context.tr('clearSectionBody')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('clear')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        for (final denomination in denominations) {
          _quantities.remove(denomination.id);
        }
      });
    }
  }

  Future<void> _lockBlindCount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('finishBlindCount')),
        content: Text(context.tr('finishBlindCountConfirm')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('lockAndContinue')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() => _blindCountLockedAt = DateTime.now());
    }
  }

  Future<void> _save() async {
    if (_blindCount && !_quantitiesLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('finishBlindBeforeSave'))),
      );
      return;
    }
    final app = AppScope.read(context);
    final session = CashCountSession(
      id: _sessionId,
      documentNumber: _documentNumber,
      currencyCode: _currencyCode,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      quantities: _quantities,
      expectedMinorUnits: AppFormatters.parseMoneyToMinor(
        _expectedController.text,
        fractionDigits: _currency.fractionDigits,
      ),
      floatMinorUnits: AppFormatters.parseMoneyToMinor(
        _floatController.text,
        fractionDigits: _currency.fractionDigits,
      ),
      note: _noteController.text.trim(),
      closingTitle: _closingTitleController.text.trim(),
      businessName: _businessNameController.text.trim(),
      businessRegistrationId: _registrationIdController.text.trim(),
      businessAddress: _businessAddressController.text.trim(),
      locationName: _locationNameController.text.trim(),
      tillName: _tillNameController.text.trim(),
      cashierName: _cashierNameController.text.trim(),
      managerName: _managerNameController.text.trim(),
      shiftName: _shiftNameController.text.trim(),
      cashierSignaturePngBase64: _cashierSignaturePngBase64,
      managerSignaturePngBase64: _managerSignaturePngBase64,
      blindCount: _blindCount,
      blindCountLockedAt: _blindCountLockedAt,
      mode: _mode,
      customDenominations: _customDenominationSnapshots,
      posReport: _posReport,
    );
    final proofed = session.copyWith(
      closingHash: ClosingProofService.hashFor(session, _currency),
    );

    setState(() => _saving = true);
    try {
      final saved = await app.saveSession(proofed);
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      if (!saved) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('saveFailed'))));
        return;
      }
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('saved'))));
      Navigator.of(context).pop();
    } on Object {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr('saveFailed'))));
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onClear,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (onClear != null)
          TextButton(onPressed: onClear, child: Text(context.tr('clear'))),
      ],
    );
  }
}
