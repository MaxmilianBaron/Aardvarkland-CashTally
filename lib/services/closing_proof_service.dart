import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../models/cash_count_session.dart';
import '../models/currency_definition.dart';

class ClosingProofService {
  const ClosingProofService();

  static const String proofVersion = '1';

  static String canonicalPayload(
    CashCountSession session,
    CurrencyDefinition currency,
  ) {
    final quantities = <String, Object?>{};
    final denominationProof = <String, Object?>{};
    final sortedIds = session.quantities.keys.toList(growable: false)..sort();
    for (final id in sortedIds) {
      final quantity = session.quantities[id] ?? 0;
      final denomination = currency.denominationById(id);
      quantities[id] = quantity;
      if (denomination != null) {
        denominationProof[id] = <String, Object?>{
          'label': denomination.label,
          'minorUnits': denomination.minorUnits,
          'kind': denomination.kind.name,
        };
      }
    }
    final raw = <String, Object?>{
      'proofVersion': proofVersion,
      'id': session.id,
      'documentNumber': session.documentNumber,
      'currencyCode': session.currencyCode,
      'createdAt': session.createdAt.toUtc().toIso8601String(),
      'updatedAt': session.updatedAt.toUtc().toIso8601String(),
      'quantities': quantities,
      'denominations': denominationProof,
      'expectedMinorUnits': session.expectedMinorUnits,
      'floatMinorUnits': session.floatMinorUnits,
      'posReport': session.posReport?.toJson(),
      'note': session.note,
      'closingTitle': session.closingTitle,
      'businessName': session.businessName,
      'businessRegistrationId': session.businessRegistrationId,
      'businessAddress': session.businessAddress,
      'locationName': session.locationName,
      'tillName': session.tillName,
      'cashierName': session.cashierName,
      'managerName': session.managerName,
      'shiftName': session.shiftName,
      'cashierSignaturePngBase64': session.cashierSignaturePngBase64,
      'managerSignaturePngBase64': session.managerSignaturePngBase64,
      'blindCount': session.blindCount,
      'blindCountLockedAt': session.blindCountLockedAt
          ?.toUtc()
          .toIso8601String(),
      'mode': session.mode.name,
      'customDenominations': session.customDenominations
          .map((item) => item.toSnapshotJson())
          .toList(growable: false),
      'totalMinorUnits': session.totalMinorUnits(currency),
    };
    return jsonEncode(_canonicalize(raw));
  }

  static String hashFor(CashCountSession session, CurrencyDefinition currency) {
    final bytes = utf8.encode(canonicalPayload(session, currency));
    final digest = Sha256().toSync().hashSync(bytes);
    return digest.bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Object? _canonicalize(Object? value) {
    if (value is Map<Object?, Object?>) {
      final entries =
          value.entries
              .map(
                (entry) =>
                    MapEntry(entry.key.toString(), _canonicalize(entry.value)),
              )
              .toList(growable: false)
            ..sort((a, b) => a.key.compareTo(b.key));
      return <String, Object?>{
        for (final entry in entries) entry.key: entry.value,
      };
    }
    if (value is List<Object?>) {
      return value.map(_canonicalize).toList(growable: false);
    }
    return value;
  }
}
