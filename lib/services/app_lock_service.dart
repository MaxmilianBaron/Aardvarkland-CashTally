import 'package:local_auth/local_auth.dart';

/// Uses the operating system's biometric or device PIN/passcode gate.
/// No app-specific PIN is stored, so the app never handles a reusable secret.
class AppLockService {
  AppLockService({LocalAuthentication? authentication})
    : _authentication = authentication ?? LocalAuthentication();

  final LocalAuthentication _authentication;

  Future<bool> isAvailable() async {
    try {
      return await _authentication.canCheckBiometrics ||
          await _authentication.isDeviceSupported();
    } on Object {
      return false;
    }
  }

  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _authentication.authenticate(
        localizedReason: localizedReason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on Object {
      return false;
    }
  }
}
