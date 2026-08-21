import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../core/app_config.dart';

/// Owns the UMP consent lifecycle and starts the ads SDK only after Google
/// reports that ads may be requested. It never decides whether a particular
/// user should see ads; that remains the entitlement controller's job.
class AdService extends ChangeNotifier {
  bool _initializing = false;
  bool _consentChecked = false;
  bool _canRequestAds = false;
  bool _privacyOptionsRequired = false;
  bool _mobileAdsStarted = false;
  String? _error;

  bool get supported => AppConfig.adsEnabled && AppConfig.platformSupportsAds;
  bool get consentChecked => _consentChecked;
  bool get canRequestAds => supported && _canRequestAds && _mobileAdsStarted;
  bool get privacyOptionsRequired => _privacyOptionsRequired;
  String? get error => _error;

  Future<void> initialize() async {
    if (!supported || _initializing || _consentChecked) {
      return;
    }
    _initializing = true;
    _error = null;
    notifyListeners();

    final done = Completer<void>();
    Future<void> finishAttempt(String? error) async {
      if (error != null) {
        _error = error;
      }
      try {
        await _refreshState();
      } on Object catch (refreshError) {
        _canRequestAds = false;
        _error = '${_error == null ? '' : '$_error · '}$refreshError';
      } finally {
        if (!done.isCompleted) {
          done.complete();
        }
      }
    }

    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () {
          ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            unawaited(
              finishAttempt(
                formError == null
                    ? null
                    : '${formError.errorCode}: ${formError.message}',
              ),
            );
          });
        },
        (formError) {
          // A previous valid choice may still permit ads when a refresh fails.
          unawaited(
            finishAttempt('${formError.errorCode}: ${formError.message}'),
          );
        },
      );
    } on Object catch (error) {
      await finishAttempt('$error');
    }

    try {
      await done.future.timeout(const Duration(seconds: 20));
    } on TimeoutException {
      _error = 'Consent request timed out.';
      try {
        await _refreshState();
      } on Object catch (refreshError) {
        _canRequestAds = false;
        _error = '$_error · $refreshError';
      }
    } finally {
      _initializing = false;
      _consentChecked = true;
      notifyListeners();
    }
  }

  Future<void> _refreshState() async {
    _privacyOptionsRequired =
        await ConsentInformation.instance
            .getPrivacyOptionsRequirementStatus() ==
        PrivacyOptionsRequirementStatus.required;
    _canRequestAds = await ConsentInformation.instance.canRequestAds();
    if (_canRequestAds && !_mobileAdsStarted) {
      await MobileAds.instance.initialize();
      _mobileAdsStarted = true;
    }
    notifyListeners();
  }

  Future<bool> showPrivacyOptions() async {
    if (!supported || !_privacyOptionsRequired) {
      return false;
    }
    final done = Completer<bool>();
    ConsentForm.showPrivacyOptionsForm((formError) async {
      if (formError != null) {
        _error = '${formError.errorCode}: ${formError.message}';
        if (!done.isCompleted) {
          done.complete(false);
        }
        notifyListeners();
        return;
      }
      _error = null;
      try {
        await _refreshState();
        if (!done.isCompleted) {
          done.complete(true);
        }
      } on Object catch (error) {
        _error = '$error';
        if (!done.isCompleted) {
          done.complete(false);
        }
        notifyListeners();
      }
    });
    return done.future;
  }
}
