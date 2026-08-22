import 'package:flutter/material.dart';

import '../core/formatters.dart';
import '../data/currency_catalog.dart';
import '../l10n/app_localizations.dart';
import '../models/count_mode.dart';
import '../models/till_template.dart';
import '../state/app_scope.dart';
import '../widgets/currency_selector.dart';
import 'count_screen.dart';
import 'session_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final matchingSessions = controller.sessions.where(
      (session) => session.currencyCode == controller.selectedCurrencyCode,
    );
    final latest = matchingSessions.isEmpty ? null : matchingSessions.first;
    final localeCode = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                'assets/branding/vycetka_logo.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                context.tr('appTitle'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                context.tr(controller.isAdFree ? 'adFreeBadge' : 'freeBadge'),
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            if (controller.errorMessage != null) ...<Widget>[
              MaterialBanner(
                content: Text(controller.errorMessage!),
                actions: <Widget>[
                  TextButton(
                    onPressed: controller.clearError,
                    child: Text(context.tr('close')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Text(
              context.tr('currency'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            CurrencySelector(
              currencies: controller.currencies,
              selectedCode: controller.selectedCurrencyCode,
              favoriteCodes: controller.favoriteCurrencyCodes,
              onSelected: controller.selectCurrency,
              onFavoriteToggled: controller.toggleFavoriteCurrency,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(58),
              ),
              onPressed: () => _openNewCount(context),
              icon: const Icon(Icons.add_circle_outline),
              label: Text(context.tr('newCount')),
            ),
            const SizedBox(height: 28),
            _FeatureCard(
              icon: Icons.wifi_off_outlined,
              title: context.tr('offlineTitle'),
              body: context.tr('offlineBody'),
            ),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    context.tr('latestCount'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (latest != null)
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            SessionDetailScreen(sessionId: latest.id),
                      ),
                    ),
                    child: Text(context.tr('detail')),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (latest == null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(context.tr('nothingYet')),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final currency = latest.currencyFor(
                    CurrencyCatalog.byCode(latest.currencyCode),
                  );
                  final total = latest.totalMinorUnits(currency);
                  final difference = latest.differenceMinorUnits(currency);
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      title: Text(
                        currency.formatMinor(total, localeCode: localeCode),
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      subtitle: Text(
                        '${latest.currencyCode} · '
                        '${AppFormatters.dateTime(latest.updatedAt, localeCode: localeCode)}'
                        '${difference == null ? '' : '\n${context.tr('difference')}: ${currency.formatMinor(difference, localeCode: localeCode)}'}'
                        '',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              SessionDetailScreen(sessionId: latest.id),
                        ),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openNewCount(BuildContext context) async {
    final app = AppScope.read(context);
    var selectedTemplate = app.tillTemplates.isEmpty
        ? null
        : app.tillTemplates.first;
    final choice = await showModalBottomSheet<_CountStartChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  context.tr('chooseCountMode'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (app.tillTemplates.isNotEmpty) ...<Widget>[
                  DropdownButtonFormField<TillTemplate?>(
                    initialValue: selectedTemplate,
                    decoration: InputDecoration(
                      labelText: context.tr('tillTemplate'),
                      prefixIcon: const Icon(Icons.point_of_sale_outlined),
                    ),
                    items: <DropdownMenuItem<TillTemplate?>>[
                      DropdownMenuItem<TillTemplate?>(
                        child: Text(context.tr('withoutTemplate')),
                      ),
                      ...app.tillTemplates.map(
                        (item) => DropdownMenuItem<TillTemplate?>(
                          value: item,
                          child: Text(
                            '${item.name} · ${item.currencyCode}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => selectedTemplate = value),
                  ),
                  const SizedBox(height: 12),
                ],
                _ModeChoiceCard(
                  icon: Icons.flash_on_outlined,
                  title: context.tr('quickCount'),
                  subtitle: context.tr('quickCountHelp'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _CountStartChoice(CountMode.quick, selectedTemplate),
                  ),
                ),
                const SizedBox(height: 8),
                _ModeChoiceCard(
                  icon: Icons.assignment_turned_in_outlined,
                  title: context.tr('professionalClose'),
                  subtitle: context.tr('professionalCloseHelp'),
                  onTap: () => Navigator.pop(
                    sheetContext,
                    _CountStartChoice(CountMode.professional, selectedTemplate),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (choice == null || !context.mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CountScreen(
          initialCurrencyCode:
              choice.template?.currencyCode ?? app.selectedCurrencyCode,
          mode: choice.mode,
          template: choice.template,
        ),
      ),
    );
  }
}

class _CountStartChoice {
  const _CountStartChoice(this.mode, this.template);

  final CountMode mode;
  final TillTemplate? template;
}

class _ModeChoiceCard extends StatelessWidget {
  const _ModeChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        minVerticalPadding: 16,
        leading: Icon(icon, size: 30),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
