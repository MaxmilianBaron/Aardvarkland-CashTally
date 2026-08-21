import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/cash_count_session.dart';

typedef DocumentsDirectoryProvider = Future<Directory> Function();

class LocalStore {
  LocalStore({DocumentsDirectoryProvider? documentsDirectoryProvider})
    : _documentsDirectoryProvider =
          documentsDirectoryProvider ?? getApplicationDocumentsDirectory;

  static const String legacySessionsFileName = 'vycetka_sessions_v1.json';
  static const String olderSessionsFileName = 'vycetka_sessions_v2.json';
  static const String previousSessionsFileName = 'vycetka_sessions_v3.json';
  static const String v4SessionsFileName = 'vycetka_sessions_v4.json';
  static const String sessionsFileName = 'vycetka_sessions_v5.json';
  static const String migrationBackupSuffix = '.pre-v5-backup';

  final DocumentsDirectoryProvider _documentsDirectoryProvider;

  Future<List<CashCountSession>> loadSessions() async {
    final directory = await _documentsDirectoryProvider();
    final current = File('${directory.path}/$sessionsFileName');
    if (await current.exists() || await File('${current.path}.bak').exists()) {
      return _loadCurrentFile(current);
    }

    // Try the newest older schema first. Each source is copied before decode
    // so support can recover data even if a migration or decode fails.
    final candidates = <File>[
      File('${directory.path}/$v4SessionsFileName'),
      File('${directory.path}/$previousSessionsFileName'),
      File('${directory.path}/$olderSessionsFileName'),
      File('${directory.path}/$legacySessionsFileName'),
    ];
    for (final source in candidates) {
      if (!await source.exists()) {
        continue;
      }
      final migrationBackup = File('${source.path}$migrationBackupSuffix');
      if (!await migrationBackup.exists()) {
        await source.copy(migrationBackup.path);
      }
      try {
        final migrated = await _decodeSessions(source);
        await saveSessions(migrated);
        return migrated;
      } on Object {
        final corrupt = File(
          '${source.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}',
        );
        await source.copy(corrupt.path);
        // A valid older schema may still be available; continue to it.
      }
    }
    return <CashCountSession>[];
  }

  Future<List<CashCountSession>> _loadCurrentFile(File file) async {
    final backup = File('${file.path}.bak');

    // Recover the last complete file if the app was terminated between the
    // two same-volume rename operations used by saveSessions().
    if (!await file.exists() && await backup.exists()) {
      await backup.rename(file.path);
    }
    if (!await file.exists()) {
      return <CashCountSession>[];
    }

    try {
      return await _decodeSessions(file);
    } on Object {
      // Preserve malformed data for support/debugging before attempting the
      // last complete atomic-save backup.
      final corrupt = File(
        '${file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}',
      );
      await file.copy(corrupt.path);

      if (await backup.exists()) {
        try {
          final recovered = await _decodeSessions(backup);
          await backup.copy(file.path);
          return recovered;
        } on Object {
          // Both files are malformed. Keep them intact and start empty.
        }
      }
      return <CashCountSession>[];
    }
  }

  Future<List<CashCountSession>> _decodeSessions(File file) async {
    final source = await file.readAsString();
    final decoded = jsonDecode(source) as List<Object?>;
    return decoded
        .map((item) {
          final raw = item! as Map<Object?, Object?>;
          final json = raw.map((key, value) => MapEntry(key! as String, value));
          return CashCountSession.fromJson(json);
        })
        .toList(growable: true)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  Future<void> saveSessions(List<CashCountSession> sessions) async {
    final file = await _sessionsFile();
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    final backup = File('${file.path}.bak');
    final payload = jsonEncode(
      sessions.map((session) => session.toJson()).toList(growable: false),
    );

    await temporary.writeAsString(payload, flush: true);
    if (await backup.exists()) {
      await backup.delete();
    }
    if (await file.exists()) {
      await file.rename(backup.path);
    }

    try {
      await temporary.rename(file.path);
      if (await backup.exists()) {
        await backup.delete();
      }
    } on Object {
      if (!await file.exists() && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    }
  }

  Future<File> _sessionsFile() async {
    final directory = await _documentsDirectoryProvider();
    return File('${directory.path}/$sessionsFileName');
  }
}
