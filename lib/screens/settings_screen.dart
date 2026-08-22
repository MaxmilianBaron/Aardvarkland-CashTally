import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../data/currency_catalog.dart';
import '../l10n/app_localizations.dart';
import '../state/app_scope.dart';
import '../state/app_controller.dart';
import 'ad_free_screen.dart';
import 'backup_screen.dart';
import 'business_profile_screen.dart';
import 'denomination_settings_screen.dart';
import 'till_templates_screen.dart';

const Map<String, String> _languageLabels = <String, String>{
  'cs': 'Čeština',
  'en': 'English',
  'de': 'Deutsch',
  'fr': 'Français',
  'it': 'Italiano',
  'nl': 'Nederlands',
  'bg': 'Български',
  'hr': 'Hrvatski',
  'el': 'Ελληνικά',
  'et': 'Eesti',
  'fi': 'Suomi',
  'lv': 'Latviešu',
  'lt': 'Lietuvių',
  'lb': 'Lëtzebuergesch',
  'mt': 'Malti',
  'pt': 'Português',
  'sk': 'Slovenčina',
  'sl': 'Slovenščina',
  'es': 'Español',
  'sv': 'Svenska',
  'nb': 'Norsk bokmål',
  'uk': 'Українська',
  'ru': 'Русский',
  'da': 'Dansk',
  'hu': 'Magyar',
  'pl': 'Polski',
  'tr': 'Türkçe',
  'id': 'Bahasa Indonesia',
  'hi': 'हिन्दी',
  'ms': 'Bahasa Melayu',
  'th': 'ไทย',
  'ur': 'اردو',
  'ar': 'العربية',
  'he': 'עברית',
  'ja': '日本語',
  'ko': '한국어',
};

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: <Widget>[
          if (AppConfig.monetizationEnabled) ...<Widget>[
            Text(
              context.tr('licence'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          app.isAdFree
                              ? Icons.verified_rounded
                              : Icons.campaign_outlined,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            context.tr(
                              app.isAdFree ? 'adFreePlan' : 'freePlan',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(
                        app.isAdFree ? 'adFreeActive' : 'freePlanActive',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AdFreeScreen(),
                        ),
                      ),
                      child: Text(
                        context.tr(app.isAdFree ? 'detail' : 'removeAds'),
                      ),
                    ),
                    if (!app.isAdFree)
                      TextButton(
                        onPressed:
                            app.purchaseService.storeAvailable &&
                                !app.purchaseService.busy
                            ? app.purchaseService.restorePurchases
                            : null,
                        child: Text(context.tr('restorePurchase')),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
          Text(
            context.tr('businessProfile'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.business_outlined),
              title: Text(
                app.businessProfile.businessName.trim().isEmpty
                    ? context.tr('businessProfileNotSet')
                    : app.businessProfile.businessName,
              ),
              subtitle: Text(
                <String>[
                  app.businessProfile.locationName,
                  app.businessProfile.tillName,
                ].where((value) => value.trim().isNotEmpty).join(' · '),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const BusinessProfileScreen(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('countingSetup'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.point_of_sale_outlined),
                  title: Text(context.tr('tillTemplates')),
                  subtitle: Text(context.tr('tillTemplatesHelp')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const TillTemplatesScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.tune_outlined),
                  title: Text(context.tr('denominationSettings')),
                  subtitle: Text(context.tr('denominationSettingsHelp')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DenominationSettingsScreen(),
                    ),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.enhanced_encryption_outlined),
                  title: Text(context.tr('backupAndRestore')),
                  subtitle: Text(context.tr('backupAndRestoreHelp')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BackupScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('appearance'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<ThemeMode>(
                initialValue: app.themeMode,
                decoration: InputDecoration(
                  labelText: context.tr('colourMode'),
                  prefixIcon: const Icon(Icons.contrast),
                ),
                items: <DropdownMenuItem<ThemeMode>>[
                  DropdownMenuItem(
                    value: ThemeMode.system,
                    child: Text(context.tr('systemTheme')),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.light,
                    child: Text(context.tr('lightTheme')),
                  ),
                  DropdownMenuItem(
                    value: ThemeMode.dark,
                    child: Text(context.tr('darkTheme')),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    app.setThemeMode(value);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('defaultLanguage'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<Locale>(
                initialValue: app.locale == null
                    ? null
                    : Locale(app.locale!.languageCode),
                decoration: InputDecoration(
                  labelText: context.tr('defaultLanguage'),
                  prefixIcon: const Icon(Icons.language),
                ),
                items: AppLocalizations.supportedLocales
                    .map(
                      (locale) => DropdownMenuItem<Locale>(
                        value: locale,
                        child: Text(
                          _languageLabels[locale.languageCode] ??
                              locale.languageCode,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (locale) {
                  if (locale != null) {
                    app.setDefaultLocale(locale);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('defaultCurrency'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<String>(
                initialValue: app.selectedCurrencyCode,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: context.tr('defaultCurrency'),
                  prefixIcon: const Icon(Icons.currency_exchange),
                ),
                items: app.currencies
                    .map(
                      (currency) => DropdownMenuItem<String>(
                        value: currency.code,
                        child: Text(
                          '${currency.code} · ${context.tr('currency${currency.code}')}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (code) {
                  if (code != null) {
                    app.setDefaultCurrency(code);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: Text(
                app.selectedCountry?.flag ?? '🌍',
                style: const TextStyle(fontSize: 28),
              ),
              title: Text(
                app.selectedCountry == null
                    ? context.tr('chooseCountry')
                    : app.selectedCountry!.localName,
              ),
              subtitle: Text(context.tr('countryAndLanguage')),
              trailing: const Icon(Icons.chevron_right),
              onTap: app.showCountryPicker,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('supportedCurrencies'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (app.favoriteCurrencyOrder.isNotEmpty) ...<Widget>[
            Text(
              context.tr('favoriteCurrencyOrder'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Card(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: app.favoriteCurrencyOrder.length,
                onReorderItem: app.reorderFavoriteCurrencies,
                itemBuilder: (context, index) {
                  final code = app.favoriteCurrencyOrder[index];
                  return ListTile(
                    key: ValueKey('favorite-$code'),
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(context.tr('currency$code')),
                    subtitle: Text(code),
                    trailing: const Icon(Icons.drag_handle),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Column(
              children:
                  CurrencyCatalog.displayOrder(
                        app.selectedCurrencyCode,
                        favoriteCodes: app.favoriteCurrencyCodes,
                        favoriteOrder: app.favoriteCurrencyOrder,
                      )
                      .map(
                        (currency) => ListTile(
                          leading: CircleAvatar(child: Text(currency.code[0])),
                          title: Text(context.tr('currency${currency.code}')),
                          subtitle: Text(currency.code),
                          trailing: IconButton(
                            tooltip: context.tr('favoriteCurrency'),
                            onPressed: () =>
                                app.toggleFavoriteCurrency(currency.code),
                            icon: Icon(
                              app.favoriteCurrencyCodes.contains(currency.code)
                                  ? Icons.star
                                  : Icons.star_border,
                              color:
                                  app.favoriteCurrencyCodes.contains(
                                    currency.code,
                                  )
                                  ? Colors.amber
                                  : null,
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('privacyAndData'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: Text(context.tr('localDataOnly')),
                  subtitle: Text(context.tr('localDataOnlyBody')),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.lock_outline),
                  title: Text(context.tr('appLock')),
                  subtitle: Text(
                    context.tr(
                      app.appLockEnabled ? 'appLockEnabled' : 'appLockDisabled',
                    ),
                  ),
                  value: app.appLockEnabled,
                  onChanged: (value) => _toggleAppLock(context, app, value),
                ),
                if (app.adService.privacyOptionsRequired) ...<Widget>[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined),
                    title: Text(context.tr('privacyOptions')),
                    subtitle: Text(context.tr('privacyOptionsBody')),
                    onTap: () => _showPrivacyOptions(context),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            context.tr('updates'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.system_update_alt),
              title: Text(context.tr('stores')),
              subtitle: Text(context.tr('storesBody')),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.code),
              title: Text(context.tr('libraryLicences')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: context.tr('appTitle'),
                applicationVersion: AppConfig.versionLabel,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              '${context.tr('appTitle')} ${AppConfig.versionLabel}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showPrivacyOptions(BuildContext context) async {
    final shown = await AppScope.read(context).adService.showPrivacyOptions();
    if (!shown && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('privacyOptionsFailed'))),
      );
    }
  }

  Future<void> _toggleAppLock(
    BuildContext context,
    AppController app,
    bool enabled,
  ) async {
    final reason = context.tr('appLockReason');
    if (!enabled) {
      await app.setAppLockEnabled(false);
      return;
    }
    if (!await app.appLockService.isAvailable()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('appLockUnavailable'))),
        );
      }
      return;
    }
    final authenticated = await app.appLockService.authenticate(
      localizedReason: reason,
    );
    if (!authenticated) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('appLockFailed'))));
      }
      return;
    }
    await app.setAppLockEnabled(true);
  }
}
