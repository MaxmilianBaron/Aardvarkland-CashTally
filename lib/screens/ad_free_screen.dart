import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_config.dart';
import '../l10n/app_localizations.dart';
import '../services/purchase_service.dart';
import '../state/app_scope.dart';

class AdFreeScreen extends StatelessWidget {
  const AdFreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final purchase = app.purchaseService;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('lifetimePurchaseTitle'))),
      body: AnimatedBuilder(
        animation: purchase,
        builder: (context, _) {
          if (app.isAdFree) {
            return _ActiveAdFree(purchase: purchase);
          }

          final product = purchase.adFreeProduct;
          final price = product?.price ?? context.tr('purchaseUnavailable');
          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
            children: <Widget>[
              Icon(
                Icons.workspace_premium_outlined,
                size: 72,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('lifetimePurchaseTitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('lifetimePurchaseIntro'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _Benefit(
                icon: Icons.block_outlined,
                title: context.tr('lifetimeBenefitNoAdsTitle'),
                body: context.tr('lifetimeBenefitNoAdsBody'),
              ),
              _Benefit(
                icon: Icons.lock_open_outlined,
                title: context.tr('lifetimeBenefitAllFeaturesTitle'),
                body: context.tr('lifetimeBenefitAllFeaturesBody'),
              ),
              _Benefit(
                icon: Icons.favorite_outline,
                title: context.tr('lifetimeBenefitSupportTitle'),
                body: context.tr('lifetimeBenefitSupportBody'),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: <Widget>[
                      Text(
                        context.tr('oneTimePurchase'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('lifetimePurchaseTerms'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              if (purchase.issue != null) ...<Widget>[
                const SizedBox(height: 12),
                _IssueCard(issue: purchase.issue!),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                ),
                onPressed: purchase.busy || product == null
                    ? null
                    : purchase.buyAdFree,
                icon: purchase.busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.visibility_off_outlined),
                label: Text('${context.tr('removeAds')} · $price'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: purchase.busy || !purchase.storeAvailable
                    ? null
                    : purchase.restorePurchases,
                child: Text(context.tr('restorePurchase')),
              ),
              const _LegalLinks(),
            ],
          );
        },
      ),
    );
  }
}

class _ActiveAdFree extends StatelessWidget {
  const _ActiveAdFree({required this.purchase});

  final PurchaseService purchase;

  @override
  Widget build(BuildContext context) {
    final entitlement = AppScope.of(context).entitlement;
    final detailKey = entitlement.isQaOverride
        ? 'qaAdFreeActive'
        : 'lifetimeAdFreeActive';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Icon(
          Icons.verified_rounded,
          size: 72,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 20),
        Text(
          context.tr('adFreeActive'),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Text(context.tr(detailKey), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        TextButton(
          onPressed: purchase.busy || !purchase.storeAvailable
              ? null
              : purchase.restorePurchases,
          child: Text(context.tr('restorePurchase')),
        ),
        const _LegalLinks(),
      ],
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final PurchaseIssue issue;

  @override
  Widget build(BuildContext context) {
    final detail = issue.detail?.trim();
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          '${context.tr(issue.localizationKey)}'
          '${detail == null || detail.isEmpty ? '' : '\n$detail'}',
        ),
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CircleAvatar(child: Icon(icon)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: <Widget>[
        if (AppConfig.privacyPolicyUrl.isNotEmpty)
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(AppConfig.privacyPolicyUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(context.tr('privacyPolicy')),
          ),
        if (AppConfig.termsUrl.isNotEmpty)
          TextButton(
            onPressed: () => launchUrl(
              Uri.parse(AppConfig.termsUrl),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(context.tr('termsOfUse')),
          ),
      ],
    );
  }
}
