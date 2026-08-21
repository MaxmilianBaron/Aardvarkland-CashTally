import 'package:flutter/material.dart';

import '../data/country_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/country_profile.dart';
import '../state/app_scope.dart';

class CountrySelectionScreen extends StatefulWidget {
  const CountrySelectionScreen({super.key});

  @override
  State<CountrySelectionScreen> createState() => _CountrySelectionScreenState();
}

class _CountrySelectionScreenState extends State<CountrySelectionScreen> {
  String? _savingCountryId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final selectedId = controller.selectedCountry?.id;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
              children: <Widget>[
                Center(
                  child: Image.asset(
                    'assets/branding/vycetka_logo.png',
                    width: 86,
                    height: 86,
                  ),
                ),
                const SizedBox(height: 24),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.78,
                      children: CountryCatalog.topLevelByPopulation
                          .map(
                            (country) => _CountryCard(
                              country: country,
                              selected:
                                  country.id == selectedId ||
                                  (country.id == CountryCatalog.euroArea.id &&
                                      controller
                                              .selectedCountry
                                              ?.currencyCode ==
                                          'EUR'),
                              saving: country.id == _savingCountryId,
                              enabled: _savingCountryId == null,
                              onTap: () =>
                                  country.id == CountryCatalog.euroArea.id
                                  ? _openEuroArea()
                                  : _select(country),
                            ),
                          )
                          .toList(growable: false),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEuroArea() async {
    final selected = await Navigator.of(context).push<CountryProfile>(
      MaterialPageRoute<CountryProfile>(
        builder: (_) => const _EuroAreaSelectionScreen(),
      ),
    );
    if (selected != null && mounted) {
      await _select(selected);
    }
  }

  Future<void> _select(CountryProfile country) async {
    setState(() => _savingCountryId = country.id);
    try {
      await AppScope.read(context).selectCountry(country);
    } on Object {
      if (mounted) {
        setState(() => _savingCountryId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('selectionSaveFailed'))),
        );
      }
    }
  }
}

class _EuroAreaSelectionScreen extends StatelessWidget {
  const _EuroAreaSelectionScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🇪🇺  Eurozone · EUR')),
      body: SafeArea(
        child: GridView.count(
          padding: const EdgeInsets.all(16),
          crossAxisCount: 4,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.78,
          children: CountryCatalog.euroAreaMembers
              .map(
                (country) => _CountryCard(
                  country: country,
                  selected: false,
                  saving: false,
                  enabled: true,
                  onTap: () => Navigator.of(context).pop(country),
                ),
              )
              .toList(growable: false),
        ),
      ),
    );
  }
}

class _CountryCard extends StatelessWidget {
  const _CountryCard({
    required this.country,
    required this.selected,
    required this.saving,
    required this.enabled,
    required this.onTap,
  });

  final CountryProfile country;
  final bool selected;
  final bool saving;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      color: selected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (saving)
                const SizedBox.square(
                  dimension: 30,
                  child: CircularProgressIndicator(),
                )
              else
                Text(country.flag, style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                height: 24,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    country.localName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ),
              Text(
                country.currencyCode,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
