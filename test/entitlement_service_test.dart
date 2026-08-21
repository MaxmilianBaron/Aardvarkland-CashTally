import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:vycetka/core/app_config.dart';
import 'package:vycetka/services/entitlement_service.dart';
import 'package:vycetka/services/purchase_service.dart';
import 'package:vycetka/state/app_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime.utc(2026, 7, 22, 12);

  test('Free has every feature entitlement and differs only by ads', () {
    const snapshot = EntitlementSnapshot(kind: EntitlementKind.free);

    expect(snapshot.isAdFree, isFalse);
    expect(snapshot.showsAds, isTrue);

    final controller = AppController(
      entitlementService: _FixedEntitlementService(snapshot),
    );
    addTearDown(controller.dispose);
    expect(controller.canCreateSavedSession(), isTrue);
  });

  test('one-time store purchase grants permanent ad-free', () async {
    const verifier = StoreReportedPurchaseVerifier();

    final result = await verifier.verify(
      _purchase(
        productId: AppConfig.adFreeLifetimeProductId,
        status: PurchaseStatus.purchased,
      ),
    );

    expect(result, isNotNull);
  });

  test('retired monthly store entitlement migrates to lifetime', () async {
    const verifier = StoreReportedPurchaseVerifier();

    final result = await verifier.verify(
      _purchase(
        productId: AppConfig.retiredMonthlyProductId,
        status: PurchaseStatus.restored,
      ),
    );

    expect(result, isNotNull);
  });

  test('pending and unknown purchases never unlock ad-free', () async {
    const verifier = StoreReportedPurchaseVerifier();

    expect(
      await verifier.verify(
        _purchase(
          productId: AppConfig.adFreeLifetimeProductId,
          status: PurchaseStatus.pending,
        ),
      ),
      isNull,
    );
    expect(
      await verifier.verify(
        _purchase(
          productId: 'unknown_product',
          status: PurchaseStatus.purchased,
        ),
      ),
      isNull,
    );
  });

  test(
    'purchase service offers, buys, restores and completes lifetime item',
    () async {
      final storage = _MemoryEntitlementStorage();
      final entitlement = EntitlementService(storage: storage, now: () => now);
      await entitlement.initialize();
      final store = _FakePurchaseStore();
      final purchaseService = PurchaseService(
        entitlementService: entitlement,
        purchaseStore: store,
      );
      addTearDown(() async {
        purchaseService.dispose();
        await store.close();
      });

      await purchaseService.initialize();
      expect(store.queriedIds, {AppConfig.adFreeLifetimeProductId});
      expect(purchaseService.adFreeProduct?.price, '€4.99');
      expect(store.restoreCalls, 1);

      await purchaseService.buyAdFree();
      expect(
        store.lastPurchaseParam?.productDetails.id,
        AppConfig.adFreeLifetimeProductId,
      );

      final purchase = _purchase(
        productId: AppConfig.adFreeLifetimeProductId,
        status: PurchaseStatus.purchased,
      )..pendingCompletePurchase = true;
      store.emit(<PurchaseDetails>[purchase]);
      await store.firstCompletion;

      expect(entitlement.snapshot.kind, EntitlementKind.lifetime);
      expect(entitlement.snapshot.showsAds, isFalse);
      expect(storage.values[EntitlementService.lifetimeUnlockedKey], 'true');
      expect(store.completedPurchases, contains(purchase));

      await purchaseService.restorePurchases();
      expect(store.restoreCalls, 2);
    },
  );

  test(
    'new device automatically restores a store-owned lifetime purchase',
    () async {
      final entitlement = EntitlementService(
        storage: _MemoryEntitlementStorage(),
        now: () => now,
      );
      await entitlement.initialize();
      final store = _FakePurchaseStore(
        restoredPurchase: _purchase(
          productId: AppConfig.adFreeLifetimeProductId,
          status: PurchaseStatus.restored,
        ),
      );
      final purchaseService = PurchaseService(
        entitlementService: entitlement,
        purchaseStore: store,
      );
      addTearDown(() async {
        purchaseService.dispose();
        await store.close();
      });

      await purchaseService.initialize();
      await Future<void>.delayed(Duration.zero);

      expect(store.restoreCalls, 1);
      expect(entitlement.snapshot.isAdFree, isTrue);
    },
  );

  test(
    'unexpired Alpha subscription cache migrates once to lifetime',
    () async {
      final storage = _MemoryEntitlementStorage(<String, String>{
        EntitlementService.obsoleteSubscriptionValidUntilKey: now
            .add(const Duration(days: 2))
            .toIso8601String(),
      });
      final service = EntitlementService(storage: storage, now: () => now);

      await service.initialize();

      expect(service.snapshot.kind, EntitlementKind.lifetime);
      expect(storage.values[EntitlementService.lifetimeUnlockedKey], 'true');
      expect(
        storage.values[EntitlementService.obsoleteSubscriptionValidUntilKey],
        isNull,
      );
    },
  );

  test('expired Alpha subscription cache is discarded', () async {
    final storage = _MemoryEntitlementStorage(<String, String>{
      EntitlementService.obsoleteSubscriptionValidUntilKey: now
          .subtract(const Duration(days: 1))
          .toIso8601String(),
    });
    final service = EntitlementService(storage: storage, now: () => now);

    await service.initialize();

    expect(service.snapshot.kind, EntitlementKind.free);
    expect(
      storage.values[EntitlementService.obsoleteSubscriptionValidUntilKey],
      isNull,
    );
  });

  test(
    'existing lifetime Full owners remain permanently grandfathered',
    () async {
      final storage = _MemoryEntitlementStorage(<String, String>{
        EntitlementService.lifetimeUnlockedKey: 'true',
      });
      final service = EntitlementService(storage: storage, now: () => now);

      await service.initialize();

      expect(service.snapshot.kind, EntitlementKind.lifetime);
      expect(service.snapshot.isAdFree, isTrue);
    },
  );
}

PurchaseDetails _purchase({
  required String productId,
  required PurchaseStatus status,
}) => PurchaseDetails(
  purchaseID: 'purchase-$productId',
  productID: productId,
  verificationData: PurchaseVerificationData(
    localVerificationData: 'local',
    serverVerificationData: 'store-token',
    source: 'test',
  ),
  transactionDate: '${DateTime.utc(2026, 7, 22).millisecondsSinceEpoch}',
  status: status,
);

class _FixedEntitlementService extends EntitlementService {
  _FixedEntitlementService(this.value);

  final EntitlementSnapshot value;

  @override
  EntitlementSnapshot get snapshot => value;

  @override
  Future<EntitlementSnapshot> initialize() async => value;
}

class _MemoryEntitlementStorage implements EntitlementStorage {
  _MemoryEntitlementStorage([Map<String, String>? initial])
    : values = <String, String>{...?initial};

  final Map<String, String> values;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class _FakePurchaseStore implements PurchaseStore {
  _FakePurchaseStore({this.restoredPurchase});

  final PurchaseDetails? restoredPurchase;
  final StreamController<List<PurchaseDetails>> _updates =
      StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  final Completer<void> _firstCompletion = Completer<void>();

  Set<String>? queriedIds;
  PurchaseParam? lastPurchaseParam;
  int restoreCalls = 0;
  final List<PurchaseDetails> completedPurchases = <PurchaseDetails>[];

  Future<void> get firstCompletion => _firstCompletion.future;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  void emit(List<PurchaseDetails> purchases) => _updates.add(purchases);

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    queriedIds = identifiers;
    return ProductDetailsResponse(
      productDetails: <ProductDetails>[
        ProductDetails(
          id: AppConfig.adFreeLifetimeProductId,
          title: 'Ad-free forever',
          description: 'One-time purchase',
          price: '€4.99',
          rawPrice: 4.99,
          currencyCode: 'EUR',
          currencySymbol: '€',
        ),
      ],
      notFoundIDs: const <String>[],
    );
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    lastPurchaseParam = purchaseParam;
    return true;
  }

  @override
  Future<void> restorePurchases() async {
    restoreCalls += 1;
    final purchase = restoredPurchase;
    if (purchase != null) {
      _updates.add(<PurchaseDetails>[purchase]);
    }
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completedPurchases.add(purchase);
    if (!_firstCompletion.isCompleted) {
      _firstCompletion.complete();
    }
  }

  Future<void> close() => _updates.close();
}
