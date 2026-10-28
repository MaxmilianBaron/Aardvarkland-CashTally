import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/services/local_store.dart';

void main() {
  test(
    'v1 sessions migrate once to v5 while preserving two legacy copies',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'vycetka-local-store-test-',
      );
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final legacy = File(
        '${directory.path}/${LocalStore.legacySessionsFileName}',
      );
      final payload = <Map<String, Object?>>[
        <String, Object?>{
          'id': 'legacy-session',
          'currencyCode': 'CZK',
          'createdAt': '2026-07-21T08:00:00.000Z',
          'updatedAt': '2026-07-21T08:01:00.000Z',
          'quantities': <String, int>{'banknote_500000': 2},
          'expectedMinorUnits': 1000000,
          'floatMinorUnits': 200000,
          'note': 'Původní záznam',
          'ocrScans': 1,
        },
      ];
      await legacy.writeAsString(jsonEncode(payload));
      final store = LocalStore(
        documentsDirectoryProvider: () async => directory,
      );

      final migrated = await store.loadSessions();
      final current = File('${directory.path}/${LocalStore.sessionsFileName}');
      final migrationBackup = File(
        '${legacy.path}${LocalStore.migrationBackupSuffix}',
      );

      expect(migrated, hasLength(1));
      expect(migrated.single.id, 'legacy-session');
      expect(migrated.single.documentNumber, startsWith('VYC-20260721-'));
      expect(migrated.single.businessName, isEmpty);
      expect(await legacy.exists(), isTrue);
      expect(await migrationBackup.exists(), isTrue);
      expect(await migrationBackup.readAsString(), await legacy.readAsString());
      expect(await current.exists(), isTrue);
      final written = jsonDecode(await current.readAsString()) as List<Object?>;
      final first = written.single! as Map<String, Object?>;
      expect(first['schemaVersion'], 5);

      await store.loadSessions();
      expect(await migrationBackup.readAsString(), await legacy.readAsString());
    },
  );

  test('v5 atomic-save backup recovers the last complete payload', () async {
    final directory = await Directory.systemTemp.createTemp(
      'vycetka-local-store-recovery-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final current = File('${directory.path}/${LocalStore.sessionsFileName}');
    final backup = File('${current.path}.bak');
    await current.writeAsString('{malformed');
    await backup.writeAsString(
      jsonEncode(<Map<String, Object?>>[
        <String, Object?>{
          'id': 'backup-session',
          'currencyCode': 'EUR',
          'createdAt': '2026-07-21T09:00:00.000Z',
          'updatedAt': '2026-07-21T09:00:00.000Z',
          'quantities': <String, int>{},
        },
      ]),
    );
    final store = LocalStore(documentsDirectoryProvider: () async => directory);

    final recovered = await store.loadSessions();

    expect(recovered.single.id, 'backup-session');
    expect(await current.readAsString(), await backup.readAsString());
    expect(
      directory.listSync().whereType<File>().any(
        (file) => file.path.contains('.corrupt-'),
      ),
      isTrue,
    );
  });

  test('corrupt history without a valid backup requires recovery', () async {
    final directory = await Directory.systemTemp.createTemp('vycetka-corrupt-');
    addTearDown(() async { if (await directory.exists()) await directory.delete(recursive: true); });
    final current = File('${directory.path}/${LocalStore.sessionsFileName}');
    await current.writeAsString('{broken');
    final store = LocalStore(documentsDirectoryProvider: () async => directory);
    await expectLater(store.loadSessions(), throwsA(isA<StateError>()));
    expect(await current.exists(), isTrue);
    expect(directory.listSync().whereType<File>().any(
      (file) => file.path.contains('.corrupt-'),
    ), isTrue);
  });

  test('a successful save retains the previous complete version as backup', () async {
    final directory = await Directory.systemTemp.createTemp('vycetka-backup-retain-');
    addTearDown(() async { if (await directory.exists()) await directory.delete(recursive: true); });
    final store = LocalStore(documentsDirectoryProvider: () async => directory);
    await store.saveSessions([]);
    final current = File('${directory.path}/${LocalStore.sessionsFileName}');
    await store.saveSessions([]);
    expect(await File('${current.path}.bak').exists(), isTrue);
  });

  test('pending import journal is durable and can be replayed after restart', () async {
    final directory = await Directory.systemTemp.createTemp('vycetka-import-journal-');
    addTearDown(() async { if (await directory.exists()) await directory.delete(recursive: true); });
    final first = LocalStore(documentsDirectoryProvider: () async => directory);
    final payload = <String, Object?>{
      'schemaVersion': 1, 'sessions': <Object?>[], 'templates': <Object?>[],
      'customDenominations': <Object?>[], 'hiddenDenominationIds': <String, Object?>{},
    };
    await first.writeImportJournal(payload);
    final reopened = LocalStore(documentsDirectoryProvider: () async => directory);
    expect(await reopened.readImportJournal(), payload);
    await reopened.clearImportJournal();
    expect(await reopened.readImportJournal(), isNull);
  });

  test('v4 sessions migrate to v5 and drop obsolete OCR counters', () async {
    final directory = await Directory.systemTemp.createTemp(
      'vycetka-local-store-v4-',
    );
    addTearDown(() async {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    final source = File('${directory.path}/${LocalStore.v4SessionsFileName}');
    await source.writeAsString(
      jsonEncode(<Map<String, Object?>>[
        <String, Object?>{
          'schemaVersion': 4,
          'id': 'v4-session',
          'currencyCode': 'CZK',
          'createdAt': '2026-07-21T09:00:00.000Z',
          'updatedAt': '2026-07-21T09:00:00.000Z',
          'quantities': <String, int>{'banknote_500000': 1},
          'ocrScans': 4,
        },
      ]),
    );

    final migrated = await LocalStore(
      documentsDirectoryProvider: () async => directory,
    ).loadSessions();
    final current = File('${directory.path}/${LocalStore.sessionsFileName}');

    expect(migrated.single.id, 'v4-session');
    expect(migrated.single.closingTitle, isEmpty);
    expect(jsonDecode(await current.readAsString()), isA<List<Object?>>());
    expect(
      await File('${source.path}${LocalStore.migrationBackupSuffix}').exists(),
      isTrue,
    );
    expect(
      (jsonDecode(await current.readAsString()) as List<Object?>).single,
      isNot(contains('ocrScans')),
    );
  });
}
