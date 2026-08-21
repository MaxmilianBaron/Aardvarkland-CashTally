import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../l10n/app_localizations.dart';
import '../services/backup_service.dart';
import '../state/app_scope.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final _service = BackupService();
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('backupAndRestore'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.tr('encryptedBackup'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(context.tr('encryptedBackupHelp')),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.save_alt),
                    label: Text(context.tr('exportBackup')),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    context.tr('restoreBackup'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(context.tr('restoreBackupHelp')),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _import,
                    icon: const Icon(Icons.settings_backup_restore),
                    label: Text(context.tr('importBackup')),
                  ),
                ],
              ),
            ),
          ),
          if (_busy) ...<Widget>[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Future<void> _export() async {
    final password = await _askPassword(confirm: true);
    if (password == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final app = AppScope.read(context);
      final bytes = await _service.encrypt(
        bundle: BackupBundle(
          sessions: app.sessions,
          templates: app.tillTemplates,
          customDenominations: app.customDenominations,
          hiddenDenominationIds: app.hiddenDenominationIds,
        ),
        password: password,
      );
      final now = DateTime.now();
      String two(int value) => value.toString().padLeft(2, '0');
      final name =
          'Vycetka-backup-${now.year}${two(now.month)}${two(now.day)}.vycbak';
      final path = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          data: bytes,
          fileName: name,
          mimeTypesFilter: const <String>['application/octet-stream'],
        ),
      );
      if (mounted && path != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('backupSaved'))));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('backupFailed'))));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _import() async {
    final path = await FlutterFileDialog.pickFile(
      params: const OpenFileDialogParams(
        fileExtensionsFilter: <String>['vycbak'],
        mimeTypesFilter: <String>['application/octet-stream'],
        copyFileToCacheDir: true,
      ),
    );
    if (path == null || !mounted) {
      return;
    }
    final password = await _askPassword();
    if (password == null || !mounted) {
      return;
    }
    setState(() => _busy = true);
    try {
      final bundle = await _service.decrypt(
        bytes: await File(path).readAsBytes(),
        password: password,
      );
      if (!mounted) {
        return;
      }
      await AppScope.read(context).importLocalData(
        sessions: bundle.sessions,
        templates: bundle.templates,
        customDenominations: bundle.customDenominations,
        hiddenDenominationIds: bundle.hiddenDenominationIds,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr('backupImported'))));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('backupPasswordOrFileInvalid'))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<String?> _askPassword({bool confirm = false}) async {
    final password = TextEditingController();
    final repeated = TextEditingController();
    String? error;
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(context.tr('backupPassword')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: password,
                autofocus: true,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: context.tr('password'),
                  helperText: context.tr('backupPasswordHelp'),
                  errorText: error,
                ),
              ),
              if (confirm) ...<Widget>[
                const SizedBox(height: 10),
                TextField(
                  controller: repeated,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.tr('repeatPassword'),
                  ),
                ),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            FilledButton(
              onPressed: () {
                if (password.text.length < 8) {
                  setDialogState(() => error = context.tr('passwordTooShort'));
                  return;
                }
                if (confirm && password.text != repeated.text) {
                  setDialogState(
                    () => error = context.tr('passwordsDoNotMatch'),
                  );
                  return;
                }
                Navigator.pop(dialogContext, password.text);
              },
              child: Text(context.tr('confirm')),
            ),
          ],
        ),
      ),
    );
    password.dispose();
    repeated.dispose();
    return result;
  }
}
