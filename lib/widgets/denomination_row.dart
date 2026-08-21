import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/currency_definition.dart';
import '../core/formatters.dart';

class DenominationRow extends StatelessWidget {
  const DenominationRow({
    required this.currency,
    required this.denomination,
    required this.quantity,
    required this.onChanged,
    required this.onEdit,
    this.step = 1,
    this.enabled = true,
    super.key,
  });

  final CurrencyDefinition currency;
  final Denomination denomination;
  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback onEdit;
  final int step;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final subtotal = denomination.minorUnits * quantity;
    final localeCode = Localizations.localeOf(context).toLanguageTag();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? () => onChanged(quantity + step) : null,
        onLongPress: enabled && quantity > 0
            ? () => onChanged((quantity - step).clamp(0, quantity))
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 440) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _DenominationLabel(
                            denomination,
                            localeCode: localeCode,
                            unavailableLabel: context.tr('weightUnavailable'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currency.formatMinor(
                            subtotal,
                            localeCode: localeCode,
                          ),
                          textAlign: TextAlign.end,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _QuantityStepper(
                        quantity: quantity,
                        onChanged: onChanged,
                        onEdit: onEdit,
                        enabled: enabled,
                        step: step,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: <Widget>[
                  SizedBox(
                    width: 110,
                    child: _DenominationLabel(
                      denomination,
                      localeCode: localeCode,
                      unavailableLabel: context.tr('weightUnavailable'),
                    ),
                  ),
                  _QuantityStepper(
                    quantity: quantity,
                    onChanged: onChanged,
                    onEdit: onEdit,
                    enabled: enabled,
                    step: step,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      currency.formatMinor(subtotal, localeCode: localeCode),
                      textAlign: TextAlign.end,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DenominationLabel extends StatelessWidget {
  const _DenominationLabel(
    this.denomination, {
    required this.localeCode,
    required this.unavailableLabel,
  });

  final Denomination denomination;
  final String localeCode;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          denomination.label,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          context.tr(denomination.isBanknote ? 'banknotes' : 'coins'),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (denomination.calculationWeightMilligrams != null)
          Text(
            AppFormatters.weight(
              denomination.calculationWeightMilligrams,
              localeCode: localeCode,
              approximate: denomination.weightIsApproximate,
              unavailableLabel: unavailableLabel,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.onChanged,
    required this.onEdit,
    required this.enabled,
    required this.step,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final VoidCallback onEdit;
  final bool enabled;
  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton.filledTonal(
          tooltip: '−',
          onPressed: !enabled
              ? null
              : () => onChanged((quantity - step).clamp(0, quantity)),
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 54,
          child: TextButton(
            onPressed: enabled ? onEdit : null,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: '+',
          onPressed: enabled ? () => onChanged(quantity + step) : null,
          icon: const Icon(Icons.add),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text('×$step', style: Theme.of(context).textTheme.labelMedium),
        ),
      ],
    );
  }
}
