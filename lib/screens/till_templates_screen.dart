import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/formatters.dart';
import '../data/currency_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/business_profile.dart';
import '../models/till_template.dart';
import '../state/app_scope.dart';

class TillTemplatesScreen extends StatelessWidget {
  const TillTemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('tillTemplates'))),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createTemplate(context),
        icon: const Icon(Icons.add),
        label: Text(context.tr('addTemplate')),
      ),
      body: app.tillTemplates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  context.tr('templatesEmpty'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: app.tillTemplates.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = app.tillTemplates[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.point_of_sale_outlined),
                    title: Text(item.name),
                    subtitle: Text(
                      <String>[
                        item.currencyCode,
                        item.profile.locationName,
                        item.profile.tillName,
                      ].where((value) => value.trim().isNotEmpty).join(' · '),
                    ),
                    trailing: IconButton(
                      tooltip: context.tr('delete'),
                      onPressed: () => _deleteTemplate(context, item),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _createTemplate(BuildContext context) async {
    final app = AppScope.read(context);
    final name = TextEditingController();
    final location = TextEditingController(
      text: app.businessProfile.locationName,
    );
    final till = TextEditingController(text: app.businessProfile.tillName);
    final cashier = TextEditingController(
      text: app.businessProfile.cashierName,
    );
    final manager = TextEditingController(
      text: app.businessProfile.managerName,
    );
    final shift = TextEditingController(text: app.businessProfile.shiftName);
    final floatValue = TextEditingController();
    var currencyCode = app.selectedCurrencyCode;

    final created = await showDialog<TillTemplate>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('addTemplate')),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextField(
                    controller: name,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: context.tr('templateName'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: currencyCode,
                    decoration: InputDecoration(
                      labelText: context.tr('currency'),
                    ),
                    items: app.currencies
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.code,
                            child: Text(
                              '${item.code} · '
                              '${context.tr('currency${item.code}')}',
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => currencyCode = value);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: location,
                    decoration: InputDecoration(
                      labelText: context.tr('locationName'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: till,
                    decoration: InputDecoration(
                      labelText: context.tr('tillName'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: shift,
                    decoration: InputDecoration(
                      labelText: context.tr('shiftName'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: cashier,
                    decoration: InputDecoration(
                      labelText: context.tr('cashierName'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: manager,
                    decoration: InputDecoration(
                      labelText: context.tr('managerName'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: floatValue,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]')),
                    ],
                    decoration: InputDecoration(
                      labelText: context.tr('leaveInTill', {
                        'code': currencyCode,
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty) {
                  return;
                }
                final currency = CurrencyCatalog.byCode(currencyCode);
                Navigator.pop(
                  dialogContext,
                  TillTemplate.create(
                    name: name.text,
                    currencyCode: currencyCode,
                    profile: BusinessProfile(
                      businessName: app.businessProfile.businessName,
                      registrationId: app.businessProfile.registrationId,
                      address: app.businessProfile.address,
                      locationName: location.text,
                      tillName: till.text,
                      cashierName: cashier.text,
                      managerName: manager.text,
                      shiftName: shift.text,
                    ),
                    floatMinorUnits: AppFormatters.parseMoneyToMinor(
                      floatValue.text,
                      fractionDigits: currency.fractionDigits,
                    ),
                  ),
                );
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );

    name.dispose();
    location.dispose();
    till.dispose();
    cashier.dispose();
    manager.dispose();
    shift.dispose();
    floatValue.dispose();
    if (created != null) {
      await app.saveTillTemplate(created);
    }
  }

  Future<void> _deleteTemplate(
    BuildContext context,
    TillTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.tr('deleteTitle')),
        content: Text(template.name),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(context.tr('keep')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AppScope.read(context).deleteTillTemplate(template.id);
    }
  }
}
