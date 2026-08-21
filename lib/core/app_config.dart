import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String appName = 'Výčetka';
  static const String versionLabel = '0.4.1';

  /// One-time non-consumable purchase in App Store Connect and Google Play.
  static const String adFreeLifetimeProductId = 'vycetka_full_unlock';

  /// Never offered again. A store-restored entitlement for the retired Alpha
  /// subscription is promoted to lifetime so an earlier buyer loses nothing.
  static const String retiredMonthlyProductId = 'vycetka_ad_free_monthly';

  /// Initial public release mode: every feature is free, no ads are requested
  /// and the store purchase UI is absent. A later app update may enable the
  /// existing monetization flow without changing the package ID or user data.
  static const bool monetizationEnabled = bool.fromEnvironment(
    'ENABLE_MONETIZATION',
    defaultValue: false,
  );

  /// The public Free tier has every product feature and differs only by ads.
  /// Google test identifiers are intentionally the safe Alpha defaults. A
  /// production verification script blocks release until real IDs are set.
  static const bool adsFlagEnabled = bool.fromEnvironment(
    'ENABLE_ADS',
    defaultValue: true,
  );
  static const bool adsEnabled = monetizationEnabled && adsFlagEnabled;
  static const String androidBannerAdUnitId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/9214589741',
  );
  static const String iosBannerAdUnitId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/2435281174',
  );

  static bool get platformSupportsAds =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static String get bannerAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
      ? iosBannerAdUnitId
      : androidBannerAdUnitId;

  static bool get usesGoogleTestAds =>
      bannerAdUnitId.startsWith('ca-app-pub-3940256099942544/');

  /// QA/private distribution override. FORCE_FULL remains a compatibility
  /// alias for old local scripts; neither flag may enter a public store build.
  static const bool forceAdFree = bool.fromEnvironment(
    'FORCE_AD_FREE',
    defaultValue: bool.fromEnvironment('FORCE_FULL', defaultValue: false),
  );

  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );
  static const String termsUrl = String.fromEnvironment('TERMS_URL');
}
