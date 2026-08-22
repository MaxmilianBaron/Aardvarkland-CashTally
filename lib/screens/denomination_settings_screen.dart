import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../data/currency_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/custom_denomination.dart';
import '../models/currency_definition.dart';
import '../state/app_scope.dart';

class DenominationSettingsScreen extends StatefulWidget {
  const DenominationSettingsScreen({super.key});

  @override
  State<DenominationSettingsScreen> createState() =>
      _DenominationSettingsScreenState();
}

class _DenominationSettingsScreenState
    extends State<DenominationSettingsScreen> {
  String? _selectedCurrencyCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedCurrencyCode ??= AppScope.read(context).selectedCurrencyCode;
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final currencyCode = _selectedCurrencyCode!;
    final currency = app.configuredCurrency(currencyCode);
    final denominations = currency.denominations.toList(growable: false)
      ..sort((a, b) {
        final kind = a.kind.index.compareTo(b.kind.index);
        return kind != 0 ? kind : b.minorUnits.compareTo(a.minorUnits);
      });
    final visibleCount = denominations
        .where((item) => app.isDenominationVisible(currencyCode, item.id))
        .length;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('denominationSettings'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addCustom(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addDenomination')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: <Widget>[
          DropdownButtonFormField<String>(
            initialValue: currencyCode,
            decoration: InputDecoration(
              labelText: context.tr('currency'),
              prefixIcon: const Icon(Icons.currency_exchange),
            ),
            items: app.currencies
                .map(
                  (item) => DropdownMenuItem<String>(
                    value: item.code,
                    child: Text(
                      '${item.code} · ${context.tr('currency${item.code}')}',
                    ),
                  ),
                )
                .toList(growable: false),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedCurrencyCode = value);
              }
            },
          ),
          const SizedBox(height: 12),
          Text(
            context.tr('denominationVisibilityHelp'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          ...denominations.map((item) {
            final visible = app.isDenominationVisible(currencyCode, item.id);
            return Card(
              child: SwitchListTile(
                value: visible,
                onChanged: visible && visibleCount == 1
                    ? null
                    : (value) => app.setDenominationVisible(
                        currencyCode,
                        item.id,
                        value,
                      ),
                secondary: Icon(
                  item.isBanknote
                      ? Icons.payments_outlined
                      : Icons.toll_outlined,
                ),
                title: Text(item.label),
                subtitle: Text(
                  item.customId == null
                      ? context.tr('standardDenomination')
                      : context.tr('customDenomination'),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _addCustom(BuildContext context) async {
    final app = AppScope.read(context);
    final currencyCode = _selectedCurrencyCode!;
    final currency = CurrencyCatalog.byCode(currencyCode);
    final label = TextEditingController();
    final value = TextEditingController();
    var kind = DenominationKind.banknote;
    final created = await showDialog<CustomDenomination>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('addDenomination')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: label,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: context.tr('denominationName'),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: value,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: <TextInputFormatter>[
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9., ]')),
                ],
                decoration: InputDecoration(
                  labelText: context.tr('denominationValue', {
                    'code': currencyCode,
                  }),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<DenominationKind>(
                segments: <ButtonSegment<DenominationKind>>[
                  ButtonSegment<DenominationKind>(
                    value: DenominationKind.banknote,
                    label: Text(context.tr('banknotes')),
                  ),
                  ButtonSegment<DenominationKind>(
                    value: DenominationKind.coin,
                    label: Text(context.tr('coins')),
                  ),
                ],
                selected: <DenominationKind>{kind},
                onSelectionChanged: (values) =>
                    setDialogState(() => kind = values.first),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                final minorUnits = AppFormatters.parseMoneyToMinor(
                  value.text,
                  fractionDigits: currency.fractionDigits,
                );
                if (label.text.trim().isEmpty ||
                    minorUnits == null ||
                    minorUnits <= 0) {
                  return;
                }
                Navigator.pop(
                  dialogContext,
                  CustomDenomination.create(
                    currencyCode: currencyCode,
                    minorUnits: minorUnits,
                    label: label.text,
                    kind: kind,
                  ),
                );
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
    label.dispose();
    value.dispose();
    if (created != null) {
      await app.addCustomDenomination(created);
    }
  }
}
