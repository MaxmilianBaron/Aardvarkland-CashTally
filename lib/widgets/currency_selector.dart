import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/currency_definition.dart';

class CurrencySelector extends StatelessWidget {
  const CurrencySelector({
    required this.currencies,
    required this.selectedCode,
    required this.favoriteCodes,
    required this.onSelected,
    required this.onFavoriteToggled,
    super.key,
  });

  final List<CurrencyDefinition> currencies;
  final String selectedCode;
  final Set<String> favoriteCodes;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onFavoriteToggled;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: currencies
            .map((currency) {
              final favorite = favoriteCodes.contains(currency.code);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ChoiceChip(
                      avatar: CircleAvatar(
                        child: FittedBox(
                          child: Text(
                            currency.symbol.trim(),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      label: Text(currency.code),
                      selected: currency.code == selectedCode,
                      onSelected: (_) => onSelected(currency.code),
                    ),
                    IconButton(
                      key: ValueKey<String>(
                        'favorite-currency-${currency.code}',
                      ),
                      visualDensity: VisualDensity.compact,
                      tooltip: context.tr(
                        favorite
                            ? 'removeCurrencyFromFavorites'
                            : 'addCurrencyToFavorites',
                      ),
                      onPressed: () => onFavoriteToggled(currency.code),
                      icon: Icon(
                        favorite
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: favorite
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}
