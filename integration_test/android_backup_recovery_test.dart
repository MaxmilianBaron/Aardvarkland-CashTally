import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vycetka/app.dart';
import 'package:vycetka/models/business_profile.dart';
import 'package:vycetka/models/cash_count_session.dart';
import 'package:vycetka/models/currency_definition.dart';
import 'package:vycetka/models/custom_denomination.dart';
import 'package:vycetka/models/till_template.dart';
import 'package:vycetka/services/backup_service.dart';
import 'package:vycetka/services/local_store.dart';
import 'package:vycetka/services/preference_service.dart';
import 'package:vycetka/state/app_controller.dart';

// These are compile-time arguments supplied by scripts/android_recovery_integration.sh.
// Only CI uses this entry point; no fault injection is linked into lib/main.dart.
const _mode = String.fromEnvironment(
  'CASH_TALLY_IT_MODE',
  defaultValue: 'roundtrip',
);
const _checkpoint = String.fromEnvironment('CASH_TALLY_IT_CHECKPOINT');
const _password = 'android-emulator-fixture-password';
const _markerName = 'cash_tally_android_it_checkpoint.txt';
const _fixtureName = 'cash_tally_android_it_encrypted.vycbak';

final _originalSession = CashCountSession(
  id: 'android-it-original-history',
  currencyCode: 'CZK',
  createdAt: DateTime.utc(2026, 10, 1, 8),
  updatedAt: DateTime.utc(2026, 10, 1, 9),
  quantities: const <String, int>{'banknote_500000': 2},
  note: 'Original entry must survive import',
);
final _importedSession = CashCountSession(
  id: 'android-it-imported-history',
  currencyCode: 'CZK',
  createdAt: DateTime.utc(2026, 10, 2, 8),
  updatedAt: DateTime.utc(2026, 10, 2, 9),
  quantities: const <String, int>{'banknote_500000': 1},
  note: 'Imported from encrypted file',
);

const _originalTemplate = TillTemplate(
  id: 'till-shared',
  name: 'Original register',
  currencyCode: 'CZK',
  profile: BusinessProfile(businessName: 'Original shop'),
  floatMinorUnits: 10000,
);
const _updatedTemplate = TillTemplate(
  id: 'till-shared',
  name: 'Restored register',
  currencyCode: 'CZK',
  profile: BusinessProfile(businessName: 'Restored shop'),
  floatMinorUnits: 25000,
);
const _newTemplate = TillTemplate(
  id: 'till-imported',
  name: 'Additional register',
  currencyCode: 'CZK',
  profile: BusinessProfile(businessName: 'Restored shop'),
);

const _originalCustom = CustomDenomination(
  id: 'custom-shared',
  currencyCode: 'CZK',
  minorUnits: 10000,
  label: 'Old voucher',
  kind: DenominationKind.banknote,
);
const _updatedCustom = CustomDenomination(
  id: 'custom-shared',
  currencyCode: 'CZK',
  minorUnits: 15000,
  label: 'Restored voucher',
  kind: DenominationKind.banknote,
);
const _newCustom = CustomDenomination(
  id: 'custom-imported',
  currencyCode: 'CZK',
  minorUnits: 25000,
  label: 'Additional voucher',
  kind: DenominationKind.banknote,
);

BackupBundle get _importBundle => BackupBundle(
  sessions: <CashCountSession>[_importedSession],
  templates: const <TillTemplate>[_updatedTemplate, _newTemplate],
  customDenominations: const <CustomDenomination>[
    _updatedCustom,
    _newCustom,
  ],
  hiddenDenominationIds: <String, Set<String>>{
    'CZK': <String>{'banknote_500000'},
  },
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android encrypted import / crash recovery: $_mode $_checkpoint', (
    tester,
  ) async {
    switch (_mode) {
      case 'roundtrip':
        await _testEncryptedRoundTrip(tester);
      case 'crash':
        await _interruptImportAtCheckpoint();
      case 'verify':
        await _verifyRestartAfterForceStop(tester);
      case 'history':
        await _testCorruptedHistory();
      default:
        fail('Unknown Android integration mode: $_mode');
    }
  });
}

Future<File> _marker() async {
  final documents = await getApplicationDocumentsDirectory();
  return File('${documents.path}/$_markerName');
}

Future<void> _pauseAt(String afterWrite, String selectedCheckpoint) async {
  if (afterWrite != selectedCheckpoint) return;

  // Flush to the actual app sandbox, so the host ADB runner can tell an
  // intentional process termination from a failure that happened beforehand.
  await (await _marker()).writeAsString(afterWrite, flush: true);
  await Completer<void>().future; // Only adb shell am force-stop ends this.
}

class _CheckpointLocalStore extends LocalStore {
  _CheckpointLocalStore(this.selectedCheckpoint);

  final String selectedCheckpoint;

  @override
  Future<void> writeImportJournal(Map<String, Object?> payload) async {
    await super.writeImportJournal(payload);
    await _pauseAt('journal', selectedCheckpoint);
  }

  @override
  Future<void> saveSessions(List<CashCountSession> sessions) async {
    await super.saveSessions(sessions);
    await _pauseAt('sessions', selectedCheckpoint);
  }
}

class _CheckpointPreferences extends PreferenceService {
  _CheckpointPreferences(this.selectedCheckpoint);

  final String selectedCheckpoint;

  @override
  Future<void> saveTillTemplates(List<TillTemplate> templates) async {
    await super.saveTillTemplates(templates);
    await _pauseAt('templates', selectedCheckpoint);
  }

  @override
  Future<void> saveCustomDenominations(
    List<CustomDenomination> denominations,
  ) async {
    await super.saveCustomDenominations(denominations);
    await _pauseAt('custom', selectedCheckpoint);
  }

  @override
  Future<void> saveHiddenDenominationIds(
    Map<String, Set<String>> hiddenIds,
  ) async {
    await super.saveHiddenDenominationIds(hiddenIds);
    await _pauseAt('hidden', selectedCheckpoint);
  }
}

Future<void> _seedExistingUserData() async {
  final store = LocalStore();
  // Never overwrite a pending journal: a previous failed verification must
  // fail loudly instead of silently disguising an incomplete recovery.
  expect(await store.readImportJournal(), isNull);
  await store.saveSessions(<CashCountSession>[_originalSession]);

  final preferences = PreferenceService();
  await preferences.saveTillTemplates(const <TillTemplate>[_originalTemplate]);
  await preferences.saveCustomDenominations(
    const <CustomDenomination>[_originalCustom],
  );
  await preferences.saveHiddenDenominationIds(<String, Set<String>>{
    'CZK': <String>{'coin_100'},
  });
  await preferences.saveAppLockEnabled(false);

  final marker = await _marker();
  if (await marker.exists()) await marker.delete();
}

Future<File> _writeRealEncryptedBackup() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/$_fixtureName');
  final encrypted = await BackupService(
    iterations: 100000,
  ).encrypt(bundle: _importBundle, password: _password);
  await file.writeAsBytes(encrypted, flush: true);
  expect(await file.length(), greaterThan(0));
  expect(utf8.decode(await file.readAsBytes()), isNot(contains(_importedSession.note)));
  return file;
}

Future<void> _importEncryptedFile(
  AppController controller,
  File file, {
  String password = _password,
}) async {
  // These are the same production steps as BackupScreen._import(), excluding
  // the platform file picker/password dialog (manual test matrix below).
  if (await file.length() > 64 * 1024 * 1024) {
    throw const FormatException('Backup file is too large');
  }
  final bundle = await BackupService().decrypt(
    bytes: await file.readAsBytes(),
    password: password,
  );
  await controller.importLocalData(
    sessions: bundle.sessions,
    templates: bundle.templates,
    customDenominations: bundle.customDenominations,
    hiddenDenominationIds: bundle.hiddenDenominationIds,
  );
}

Future<void> _testEncryptedRoundTrip(WidgetTester tester) async {
  await _seedExistingUserData();
  final controller = AppController();
  addTearDown(controller.dispose);
  await controller.initialize();
  expect(controller.errorMessage, isNull);
  expect(controller.sessions.single.id, _originalSession.id);

  final file = await _writeRealEncryptedBackup();
  await expectLater(
    _importEncryptedFile(controller, file, password: 'incorrect-password'),
    throwsA(anything),
  );
  // Authentication failure must not touch either the journal or history.
  expect(await LocalStore().readImportJournal(), isNull);
  expect(
    (await LocalStore().loadSessions()).single.toJson(),
    _originalSession.toJson(),
  );

  await _importEncryptedFile(controller, file);
  await _assertAllPersistedData(controller);
  await _checkFreshAppLaunch(tester);
}

Future<void> _interruptImportAtCheckpoint() async {
  const supported = <String>{
    'journal',
    'sessions',
    'templates',
    'custom',
    'hidden',
  };
  expect(supported, contains(_checkpoint));

  await _seedExistingUserData();
  final controller = AppController(
    localStore: _CheckpointLocalStore(_checkpoint),
    preferenceService: _CheckpointPreferences(_checkpoint),
  );
  await controller.initialize();
  expect(controller.errorMessage, isNull);
  expect(controller.sessions.single.id, _originalSession.id);

  final file = await _writeRealEncryptedBackup();
  await _importEncryptedFile(controller, file);

  // A successful return means fault injection was bypassed, so this must fail.
  fail('Import reached the end instead of pausing at $_checkpoint');
}

Future<void> _verifyRestartAfterForceStop(WidgetTester tester) async {
  final marker = await _marker();
  expect(await marker.exists(), isTrue);
  expect(await marker.readAsString(), _checkpoint);

  // This controller is constructed in a NEW Android application process after
  // the CI runner sent adb shell am force-stop to the previous one.
  final controller = AppController();
  await controller.initialize();
  expect(controller.errorMessage, isNull);
  await _assertAllPersistedData(controller);

  final encryptedFile = File(
    '${(await getApplicationDocumentsDirectory()).path}/$_fixtureName',
  );
  expect(await encryptedFile.exists(), isTrue);
  final decrypted = await BackupService().decrypt(
    bytes: await encryptedFile.readAsBytes(),
    password: _password,
  );
  expect(decrypted.sessions.single.toJson(), _importedSession.toJson());

  // Re-running the next startup must be idempotent, not duplicate histories.
  final secondLaunch = AppController();
  await secondLaunch.initialize();
  await _assertAllPersistedData(secondLaunch);
  secondLaunch.dispose();

  await tester.pumpWidget(VycetkaApp(controller: controller));
  await tester.pump();
  expect(find.byType(MaterialApp), findsOneWidget);
  expect(find.textContaining('CASH_TALLY_RECOVERY_REQUIRED'), findsNothing);
  await tester.pumpWidget(const SizedBox.shrink());
  controller.dispose();
  await marker.delete();
}

Future<void> _assertAllPersistedData(AppController controller) async {
  expect(controller.errorMessage, isNull);
  expect(controller.sessions, hasLength(2));
  expect(
    controller.sessions.map((item) => item.toJson()).toList(),
    <Map<String, Object?>>[
      _importedSession.toJson(),
      _originalSession.toJson(),
    ],
  );
  expect(
    controller.tillTemplates.map((item) => item.toJson()).toList(),
    <Map<String, Object?>>[
      _updatedTemplate.toJson(),
      _newTemplate.toJson(),
    ],
  );
  expect(
    controller.customDenominations.map((item) => item.toJson()).toList(),
    <Map<String, Object?>>[
      _updatedCustom.toJson(),
      _newCustom.toJson(),
    ],
  );
  expect(controller.hiddenDenominationIds, <String, Set<String>>{
    'CZK': <String>{'coin_100', 'banknote_500000'},
  });

  final store = LocalStore();
  expect(await store.readImportJournal(), isNull);
  expect(
    (await store.loadSessions()).map((item) => item.toJson()).toList(),
    controller.sessions.map((item) => item.toJson()).toList(),
  );

  final documents = await getApplicationDocumentsDirectory();
  final current = File('${documents.path}/${LocalStore.sessionsFileName}');
  final backup = File('${current.path}.bak');
  expect(await current.exists(), isTrue);
  expect(await backup.exists(), isTrue);
  expect(jsonDecode(await current.readAsString()), hasLength(2));
  expect(jsonDecode(await backup.readAsString()), isA<List<Object?>>());
}

Future<void> _checkFreshAppLaunch(WidgetTester tester) async {
  final fresh = AppController();
  await fresh.initialize();
  await _assertAllPersistedData(fresh);
  await tester.pumpWidget(VycetkaApp(controller: fresh));
  await tester.pump();
  expect(find.byType(MaterialApp), findsOneWidget);
  await tester.pumpWidget(const SizedBox.shrink());
  fresh.dispose();
}

Future<void> _testCorruptedHistory() async {
  await _seedExistingUserData();
  final store = LocalStore();
  // Create a known-good .bak snapshot as well as the primary history.
  await store.saveSessions(<CashCountSession>[_originalSession]);
  final directory = await getApplicationDocumentsDirectory();
  final primary = File('${directory.path}/${LocalStore.sessionsFileName}');
  final backup = File('${primary.path}.bak');
  expect(await backup.exists(), isTrue);

  await primary.writeAsString('{invalid-primary', flush: true);
  final recovered = AppController();
  await recovered.initialize();
  expect(recovered.errorMessage, isNull);
  expect(recovered.sessions.single.toJson(), _originalSession.toJson());
  expect(await primary.readAsString(), await backup.readAsString());
  recovered.dispose();

  expect(
    directory.listSync().whereType<File>().any(
      (file) => file.path.contains('.corrupt-'),
    ),
    isTrue,
  );

  // With BOTH copies damaged, startup must fail closed and a subsequent save
  // must not overwrite the original evidence or create an empty history.
  await primary.writeAsString('{invalid-primary-again', flush: true);
  await backup.writeAsString('{invalid-backup', flush: true);
  final blocked = AppController();
  await blocked.initialize();
  expect(blocked.errorMessage, contains('CASH_TALLY_RECOVERY_REQUIRED'));
  await expectLater(
    blocked.saveSession(_importedSession),
    throwsA(isA<StateError>()),
  );
  expect(await primary.readAsString(), '{invalid-primary-again');
  expect(await backup.readAsString(), '{invalid-backup');
  blocked.dispose();
}
