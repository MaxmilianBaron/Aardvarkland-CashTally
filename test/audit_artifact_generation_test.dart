import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/export_banknote_catalog.dart' as banknote_export;
import '../tool/l10n_currency_audit.dart' as l10n_audit;

void main() {
  test('writes opt-in language and currency audit artifacts', () {
    const outputDirectory = String.fromEnvironment('VYCETKA_AUDIT_OUTPUT');
    if (outputDirectory.isEmpty) {
      return;
    }

    final directory = Directory(outputDirectory)..createSync(recursive: true);
    final languageAudit = File(
      '${directory.path}/language-currency-audit.json',
    );
    final banknoteCatalog = File('${directory.path}/banknote-catalog.json');
    l10n_audit.main(<String>[languageAudit.path]);
    banknote_export.main(<String>[banknoteCatalog.path]);

    expect(languageAudit.lengthSync(), greaterThan(0));
    expect(banknoteCatalog.lengthSync(), greaterThan(0));
  });
}
