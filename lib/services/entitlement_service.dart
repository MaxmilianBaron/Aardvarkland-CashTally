import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/app_config.dart';

enum EntitlementKind { free, lifetime, qaOverride }

@immutable
class EntitlementSnapshot {
  const EntitlementSnapshot({required this.kind});

  final EntitlementKind kind;

  bool get isAdFree => kind != EntitlementKind.free;
  bool get showsAds => !isAdFree;
  bool get isLifetime => kind == EntitlementKind.lifetime;
  bool get isQaOverride => kind == EntitlementKind.qaOverride;
}

abstract interface class EntitlementStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureEntitlementStorage implements EntitlementStorage {
  SecureEntitlementStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Persists only the minimum offline entitlement state.
///
/// The original lifetime key is intentionally reused by the current one-time
/// product, so updates and reinstalls through the same store account can
/// restore the same entitlement without a project-owned backend.
class EntitlementService {
  EntitlementService({EntitlementStorage? storage, DateTime Function()? now})
    : _storage = storage ?? SecureEntitlementStorage(),
      _now = now ?? DateTime.now;

  static const String lifetimeUnlockedKey = 'full_unlocked_v1';

  /// Removed in 0.1.12. Retained only for a one-time, user-friendly migration
  /// of an unexpired Alpha subscription cache to the new lifetime entitlement.
  static const String obsoleteSubscriptionValidUntilKey =
      'ad_free_subscription_valid_until_v1';

  final EntitlementStorage _storage;
  final DateTime Function() _now;

  EntitlementSnapshot? _snapshot;

  EntitlementSnapshot get snapshot {
    final value = _snapshot;
    if (value == null) {
      throw StateError('EntitlementService.initialize() must be called first.');
    }
    return value;
  }

  Future<EntitlementSnapshot> initialize() async {
    if (AppConfig.forceAdFree) {
      _snapshot = const EntitlementSnapshot(kind: EntitlementKind.qaOverride);
      return snapshot;
    }

    final lifetime = await _storage.read(lifetimeUnlockedKey) == 'true';
    if (lifetime) {
      _snapshot = const EntitlementSnapshot(kind: EntitlementKind.lifetime);
      return snapshot;
    }

    final rawExpiry = await _storage.read(obsoleteSubscriptionValidUntilKey);
    final expiry = rawExpiry == null ? null : DateTime.tryParse(rawExpiry);
    if (expiry != null && expiry.isAfter(_now().toUtc())) {
      return grantLifetime();
    }

    if (rawExpiry != null) {
      await _storage.delete(obsoleteSubscriptionValidUntilKey);
    }
    _snapshot = const EntitlementSnapshot(kind: EntitlementKind.free);
    return snapshot;
  }

  Future<EntitlementSnapshot> grantLifetime() async {
    await _storage.write(lifetimeUnlockedKey, 'true');
    await _storage.delete(obsoleteSubscriptionValidUntilKey);
    _snapshot = const EntitlementSnapshot(kind: EntitlementKind.lifetime);
    return snapshot;
  }

  Future<EntitlementSnapshot> revokeLifetime() async {
    await _storage.delete(lifetimeUnlockedKey);
    await _storage.delete(obsoleteSubscriptionValidUntilKey);
    if (AppConfig.forceAdFree) {
      _snapshot = const EntitlementSnapshot(kind: EntitlementKind.qaOverride);
    } else {
      _snapshot = const EntitlementSnapshot(kind: EntitlementKind.free);
    }
    return snapshot;
  }
}
