import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/app_config.dart';
import 'entitlement_service.dart';

@immutable
class VerifiedEntitlement {
  const VerifiedEntitlement.lifetime();
}

abstract interface class PurchaseVerifier {
  Future<VerifiedEntitlement?> verify(PurchaseDetails purchase);
}

/// Client-only validation for the deliberately low-risk lifetime ad removal.
///
/// Google Play or StoreKit reports the transaction through the official store
/// plugin. This avoids a project-owned receipt server, but it is weaker against
/// a modified client and delayed refund/revocation updates than server-side
/// verification. No cash-counting feature or user data depends on this result.
class StoreReportedPurchaseVerifier implements PurchaseVerifier {
  const StoreReportedPurchaseVerifier();

  @override
  Future<VerifiedEntitlement?> verify(PurchaseDetails purchase) async {
    final acceptedStatus =
        purchase.status == PurchaseStatus.purchased ||
        purchase.status == PurchaseStatus.restored;
    final acceptedProduct =
        purchase.productID == AppConfig.adFreeLifetimeProductId ||
        purchase.productID == AppConfig.retiredMonthlyProductId;
    if (!acceptedStatus || !acceptedProduct) {
      return null;
    }
    return const VerifiedEntitlement.lifetime();
  }
}

/// Small adapter that keeps the store replaceable in deterministic tests.
abstract interface class PurchaseStore {
  Stream<List<PurchaseDetails>> get purchaseStream;
  Future<bool> isAvailable();
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers);
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam});
  Future<void> restorePurchases();
  Future<void> completePurchase(PurchaseDetails purchase);
}

class PlatformPurchaseStore implements PurchaseStore {
  PlatformPurchaseStore() : _client = InAppPurchase.instance;

  final InAppPurchase _client;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _client.purchaseStream;

  @override
  Future<bool> isAvailable() => _client.isAvailable();

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) =>
      _client.queryProductDetails(identifiers);

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) =>
      _client.buyNonConsumable(purchaseParam: purchaseParam);

  @override
  Future<void> restorePurchases() => _client.restorePurchases();

  @override
  Future<void> completePurchase(PurchaseDetails purchase) =>
      _client.completePurchase(purchase);
}

@immutable
class PurchaseIssue {
  const PurchaseIssue(this.localizationKey, {this.detail});

  final String localizationKey;
  final String? detail;
}

class PurchaseService extends ChangeNotifier {
  PurchaseService({
    required this.entitlementService,
    PurchaseVerifier? verifier,
    PurchaseStore? purchaseStore,
  }) : _verifier = verifier ?? const StoreReportedPurchaseVerifier(),
       _store = purchaseStore;

  final EntitlementService entitlementService;
  final PurchaseVerifier _verifier;
  PurchaseStore? _store;

  StreamSubscription<List<PurchaseDetails>>? _purchaseUpdatesSubscription;
  ProductDetails? _adFreeProduct;
  bool _storeAvailable = false;
  bool _busy = false;
  bool _restoreAttemptedThisSession = false;
  PurchaseIssue? _issue;

  ProductDetails? get adFreeProduct => _adFreeProduct;
  bool get storeAvailable => _storeAvailable;
  bool get busy => _busy;
  PurchaseIssue? get issue => _issue;

  PurchaseStore get _activeStore => _store ??= PlatformPurchaseStore();

  Future<void> initialize() async {
    final store = _activeStore;
    _purchaseUpdatesSubscription ??= store.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) {
        _issue = PurchaseIssue('purchaseStreamError', detail: '$error');
        _busy = false;
        notifyListeners();
      },
    );

    try {
      _storeAvailable = await store.isAvailable();
      if (!_storeAvailable) {
        _issue = const PurchaseIssue('storeUnavailable');
        notifyListeners();
        return;
      }

      final response = await store.queryProductDetails(const <String>{
        AppConfig.adFreeLifetimeProductId,
      });
      if (response.error != null) {
        _issue = PurchaseIssue(
          'productQueryFailed',
          detail: response.error!.message,
        );
      }
      for (final product in response.productDetails) {
        if (product.id == AppConfig.adFreeLifetimeProductId) {
          _adFreeProduct = product;
          break;
        }
      }
      if (_adFreeProduct == null) {
        _issue = const PurchaseIssue('adFreeProductMissing');
      } else if (response.error == null) {
        _issue = null;
        // A new phone has no local entitlement. Ask the official store once
        // during this process lifetime so the same store account restores the
        // non-consumable without a project-owned receipt server.
        if (!entitlementService.snapshot.isAdFree &&
            !_restoreAttemptedThisSession) {
          await _restorePurchasesInternal(automatic: true);
        }
      }
    } on Object catch (error) {
      _issue = PurchaseIssue('storeConnectionFailed', detail: '$error');
    }
    notifyListeners();
  }

  Future<void> buyAdFree() async {
    final product = _adFreeProduct;
    if (!_storeAvailable || product == null || _busy) {
      return;
    }
    _busy = true;
    _issue = null;
    notifyListeners();
    try {
      final started = await _activeStore.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _issue = const PurchaseIssue('purchaseNotStarted');
        _busy = false;
        notifyListeners();
      }
    } on Object catch (error) {
      _issue = PurchaseIssue('purchaseStartFailed', detail: '$error');
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!_storeAvailable || _busy) {
      return;
    }
    await _restorePurchasesInternal();
  }

  Future<void> _restorePurchasesInternal({bool automatic = false}) async {
    if (!_storeAvailable ||
        _busy ||
        (automatic && _restoreAttemptedThisSession)) {
      return;
    }
    _restoreAttemptedThisSession = true;
    _busy = true;
    _issue = null;
    notifyListeners();
    try {
      await _activeStore.restorePurchases();
      _busy = false;
      notifyListeners();
    } on Object catch (error) {
      _issue = PurchaseIssue('restoreFailed', detail: '$error');
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      var delivered = false;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _busy = true;
          _issue = const PurchaseIssue('purchasePending');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          try {
            final verified = await _verifier.verify(purchase);
            if (verified == null) {
              _issue = const PurchaseIssue('purchaseVerificationFailed');
            } else {
              await entitlementService.grantLifetime();
              delivered = true;
              _issue = null;
            }
          } on Object catch (error) {
            _issue = PurchaseIssue(
              'purchaseVerificationFailed',
              detail: '$error',
            );
          }
          _busy = false;
          break;
        case PurchaseStatus.error:
          _issue = PurchaseIssue(
            'purchaseFailed',
            detail: purchase.error?.message,
          );
          _busy = false;
          break;
        case PurchaseStatus.canceled:
          _issue = const PurchaseIssue('purchaseCanceled');
          _busy = false;
          break;
      }

      if (delivered && purchase.pendingCompletePurchase) {
        try {
          await _activeStore.completePurchase(purchase);
        } on Object catch (error) {
          _issue = PurchaseIssue('purchaseCompletionFailed', detail: '$error');
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_purchaseUpdatesSubscription?.cancel());
    super.dispose();
  }
}
