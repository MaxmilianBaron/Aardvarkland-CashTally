import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../models/cash_count_session.dart';
import '../data/currency_catalog.dart';
import '../models/custom_denomination.dart';
import '../models/till_template.dart';

class BackupBundle {
  const BackupBundle({
    required this.sessions,
    required this.templates,
    required this.customDenominations,
    required this.hiddenDenominationIds,
  });

  factory BackupBundle.fromJson(Map<String, Object?> json) {
    final rawSessions = json['sessions'] as List<Object?>? ?? const <Object?>[];
    if (rawSessions.length > 10000) throw const FormatException('Backup has too many sessions');
    Map<String, Object?> stringMap(Object? source) =>
        (source! as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key! as String, value),
        );

    final sessions = rawSessions.map(
      (item) => CashCountSession.fromJson(stringMap(item)),
    ).toList(growable: false);
    for (final session in sessions) {
      if (!CurrencyCatalog.containsCode(session.currencyCode)) {
        throw const FormatException('Unknown backup currency');
      }
      final currency = session.currencyFor(CurrencyCatalog.byCode(session.currencyCode));
      for (final id in session.quantities.keys) {
        if (currency.denominationById(id) == null) {
          throw const FormatException('Unknown backup denomination');
        }
      }
    }
    return BackupBundle(
      sessions: sessions,
      templates: (json['templates'] as List<Object?>? ?? const <Object?>[])
          .map((item) => TillTemplate.fromJson(stringMap(item)))
          .toList(growable: false),
      customDenominations:
          (json['customDenominations'] as List<Object?>? ?? const <Object?>[])
              .map((item) => CustomDenomination.fromJson(stringMap(item)))
              .toList(growable: false),
      hiddenDenominationIds:
          (json['hiddenDenominationIds'] as Map<String, Object?>? ??
                  const <String, Object?>{})
              .map(
                (code, value) => MapEntry(
                  code,
                  (value as List<Object?>).whereType<String>().toSet(),
                ),
              ),
    );
  }

  final List<CashCountSession> sessions;
  final List<TillTemplate> templates;
  final List<CustomDenomination> customDenominations;
  final Map<String, Set<String>> hiddenDenominationIds;

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': 1,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'sessions': sessions.map((item) => item.toJson()).toList(growable: false),
    'templates': templates.map((item) => item.toJson()).toList(growable: false),
    'customDenominations': customDenominations
        .map((item) => item.toJson())
        .toList(growable: false),
    'hiddenDenominationIds': hiddenDenominationIds.map((code, ids) {
      final ordered = ids.toList(growable: false)..sort();
      return MapEntry(code, ordered);
    }),
  };
}

class BackupService {
  BackupService({Cipher? cipher, this._iterations = 210000, Random? random})
    : _cipher = cipher ?? AesGcm.with256bits(),
      _random = random ?? Random.secure();

  final Cipher _cipher;
  final int _iterations;
  final Random _random;

  Future<Uint8List> encrypt({
    required BackupBundle bundle,
    required String password,
  }) async {
    if (password.length < 8) {
      throw const FormatException('Backup password must have 8 characters.');
    }
    final salt = List<int>.generate(16, (_) => _random.nextInt(256));
    final key = await _deriveKey(password, salt, _iterations);
    final clearText = utf8.encode(jsonEncode(bundle.toJson()));
    final box = await _cipher.encrypt(clearText, secretKey: key);
    final envelope = <String, Object?>{
      'format': 'vycetka-encrypted-backup',
      'version': 1,
      'kdf': <String, Object?>{
        'name': 'PBKDF2-HMAC-SHA256',
        'iterations': _iterations,
        'salt': base64Encode(salt),
      },
      'cipher': <String, Object?>{
        'name': 'AES-256-GCM',
        'nonce': base64Encode(box.nonce),
        'data': base64Encode(box.cipherText),
        'mac': base64Encode(box.mac.bytes),
      },
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<BackupBundle> decrypt({
    required List<int> bytes,
    required String password,
  }) async {
    if (bytes.length > 64 * 1024 * 1024) {
      throw const FormatException('Backup file is too large');
    }
    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, Object?>;
    if (envelope['format'] != 'vycetka-encrypted-backup' ||
        envelope['version'] != 1) {
      throw const FormatException('Unsupported backup format.');
    }
    final kdf = (envelope['kdf']! as Map<Object?, Object?>).map(
      (key, value) => MapEntry(key! as String, value),
    );
    final cipher = (envelope['cipher']! as Map<Object?, Object?>).map(
      (key, value) => MapEntry(key! as String, value),
    );
    final iterations = (kdf['iterations']! as num).toInt();
    if (iterations < 100000 || iterations > 2000000) {
      throw const FormatException('Invalid backup key parameters.');
    }
    final salt = base64Decode(kdf['salt']! as String);
    final key = await _deriveKey(password, salt, iterations);
    final clearText = await _cipher.decrypt(
      SecretBox(
        base64Decode(cipher['data']! as String),
        nonce: base64Decode(cipher['nonce']! as String),
        mac: Mac(base64Decode(cipher['mac']! as String)),
      ),
      secretKey: key,
    );
    final payload = jsonDecode(utf8.decode(clearText)) as Map<String, Object?>;
    if (payload['schemaVersion'] != 1) {
      throw const FormatException('Unsupported backup payload.');
    }
    return BackupBundle.fromJson(payload);
  }

  Future<SecretKey> _deriveKey(
    String password,
    List<int> salt,
    int iterations,
  ) {
    return Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }
}
