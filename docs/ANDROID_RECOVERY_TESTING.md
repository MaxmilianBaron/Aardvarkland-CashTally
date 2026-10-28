# Android encrypted-backup recovery test matrix

The `android-recovery` GitHub Actions job runs the Flutter `integration_test`
suite on an **Android API 35 x86_64 emulator**. The existing `flutter` unit,
static-analysis and APK-build job, and the iOS build job, stay unchanged.

## Automated on the Android emulator

| Scenario | Actual behavior validated |
| --- | --- |
| Encrypted backup, correct password | AES-GCM/PBKDF2 encrypted `.vycbak` fixture is written and decrypted using production `BackupService`; `AppController.importLocalData` persists the merge |
| Wrong password | Import fails before touching the journal or original history |
| Forced stop after durable journal | Android process killed with `adb shell am force-stop`; next process replays journal |
| Forced stop after session write | Original and imported history remain complete and are not duplicated |
| Forced stop after template write | Both template ID update and additional template survive restart |
| Forced stop after custom-denomination write | Updated and new custom denominations survive restart |
| Forced stop after hidden-denomination write | Hidden denomination IDs merge without losing existing choices |
| All five restarts | `AppController.initialize()` automatically resolves the pending journal, reads real filesystem/Android secure storage, clears the journal and stays idempotent after another initialization |
| Corrupt history with valid `.bak` | App restores the last valid history and preserves corrupt evidence |
| Both copies corrupted | App surfaces a recovery-required error and blocks subsequent writes instead of overwriting history |

The runner uses a **fresh driver invocation for each launch**, sharing the
Android app sandbox between invocations. All runs use `flutter drive --keep-app-running`
so the host runner controls process termination between launches. The test process pauses immediately
after the selected persisted write; the host checks a flushed marker via
`adb shell run-as` before terminating the **whole app process** using
`am force-stop`. Merely throwing an exception or calling
`tester.restartAndRestore()` would not provide this coverage.

Test artifacts are synthetic; no real customer exports or signatures are used.
Intentional app-driver disconnects during crash stages are expected. The CI
job passes only when the selected marker was observed **and** the independent
cold-start verification proves data completeness.
Every driver invocation has a host-side timeout, including installation and
VM-service connection. CI retains stage logs and emulator diagnostics for
failed launches as well as completed tests. Set `CASH_TALLY_TEST_DEVICE` to
select a specific disposable emulator when several are connected.
Each launch stops the previous test process, archives and clears its log,
and resets only that emulator's debugger forwards. The driver connects
directly through a fixed local VM-service port, avoiding a stale proxy from
a preceding forced termination.

## Run locally

Install Flutter 3.44+, Android SDK/emulator (API 35, x86_64), and start the
emulator. From the repository root:

```bash
flutter pub get
bash scripts/android_recovery_integration.sh
```

For a quick non-crash smoke test on a running emulator:

```bash
flutter drive --driver=test_driver/integration_test.dart \
  --target=integration_test/android_backup_recovery_test.dart \
  --dart-define=CASH_TALLY_IT_MODE=roundtrip
```

The complete suite deliberately leaves a corrupt history in the disposable
emulator at the end; use a **test emulator, never a personal production app
installation**. CI also runs existing `flutter test` unit tests separately.

## Still requires physical-device/manual verification

- **Android and iOS biometric gating:** real fingerprint/Face ID enrollment,
  route/dialog overlay protection, app-switching and unlock failure handling.
- **Android and iOS backup file chooser/export:** file-provider permissions,
  picker and sharing targets, external storage, iCloud/Files integration, and
  user-facing password dialogs. The emulator suite exercises the production
  cryptography/import-controller path, not the OS picker UI.
- **Actual printing and PDF/file export:** supported printers, share sheets,
  platform-specific output handling and large rendered documents.
- **Large production-size histories/backups:** memory, latency, storage-full,
  power loss, app upgrades and OS interruption during a single low-level file
  rename/write (the emulator suite stops *after* completed write boundaries).
- **iOS process termination/relaunch:** Android's ADB force-stop cannot
  substitute for iOS device testing.

Do not treat the green emulator job as evidence that these physical-device
scenarios have passed.
