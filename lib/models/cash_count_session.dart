import 'dart:math';

import 'package:flutter/foundation.dart';

import 'business_profile.dart';
import 'count_mode.dart';
import 'currency_definition.dart';
import 'pos_reconciliation.dart';

@immutable
class CashCountSession {
  // v5 adds the optional custom closing title. LocalStore migrates older files
  // with a recoverable pre-v5 copy.
  static const int currentSchemaVersion = 5;
  static final Random _secureRandom = Random.secure();

  static String generateId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = _secureRandom
        .nextInt(0x100000000)
        .toRadixString(36)
        .padLeft(7, '0');
    return '$timestamp-$entropy';
  }

  static String generateDocumentNumber(DateTime createdAt, String id) {
    String two(int value) => value.toString().padLeft(2, '0');
    final date =
        '${createdAt.year}${two(createdAt.month)}${two(createdAt.day)}';
    final suffix = id
        .replaceAll(RegExp('[^A-Za-z0-9]'), '')
        .toUpperCase()
        .padLeft(6, '0');
    return 'VYC-$date-${suffix.substring(suffix.length - 6)}';
  }

  CashCountSession({
    required this.id,
    required this.currencyCode,
    required this.createdAt,
    DateTime? updatedAt,
    String? documentNumber,
    Map<String, int>? quantities,
    this.expectedMinorUnits,
    this.floatMinorUnits,
    this.note = '',
    this.closingTitle = '',
    this.businessName = '',
    this.businessRegistrationId = '',
    this.businessAddress = '',
    this.locationName = '',
    this.tillName = '',
    this.cashierName = '',
    this.managerName = '',
    this.shiftName = '',
    this.cashierSignaturePngBase64,
    this.managerSignaturePngBase64,
    this.blindCount = false,
    this.blindCountLockedAt,
    this.mode = CountMode.professional,
    List<Denomination>? customDenominations,
    this.posReport,
    this.closingHash,
  }) : updatedAt = updatedAt ?? createdAt,
       documentNumber = documentNumber ?? generateDocumentNumber(createdAt, id),
       quantities = Map<String, int>.unmodifiable(
         quantities ?? const <String, int>{},
       ),
       customDenominations = List<Denomination>.unmodifiable(
         customDenominations ?? const <Denomination>[],
       );

  factory CashCountSession.create(
    String currencyCode, {
    BusinessProfile profile = const BusinessProfile(),
    CountMode mode = CountMode.professional,
    int? floatMinorUnits,
    List<Denomination> customDenominations = const <Denomination>[],
  }) {
    final now = DateTime.now();
    return CashCountSession(
      id: generateId(),
      currencyCode: currencyCode,
      createdAt: now,
      businessName: profile.businessName,
      businessRegistrationId: profile.registrationId,
      businessAddress: profile.address,
      locationName: profile.locationName,
      tillName: profile.tillName,
      cashierName: profile.cashierName,
      managerName: profile.managerName,
      shiftName: profile.shiftName,
      mode: mode,
      floatMinorUnits: floatMinorUnits,
      customDenominations: customDenominations,
    );
  }

  factory CashCountSession.fromJson(Map<String, Object?> json) {
    final rawQuantities =
        json['quantities'] as Map<String, Object?>? ??
        const <String, Object?>{};
    return CashCountSession(
      id: json['id']! as String,
      currencyCode: json['currencyCode']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String),
      updatedAt: DateTime.parse(json['updatedAt']! as String),
      documentNumber: json['documentNumber'] as String?,
      quantities: rawQuantities.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      expectedMinorUnits: (json['expectedMinorUnits'] as num?)?.toInt(),
      floatMinorUnits: (json['floatMinorUnits'] as num?)?.toInt(),
      note: json['note'] as String? ?? '',
      closingTitle: json['closingTitle'] as String? ?? '',
      // Unknown legacy fields such as `ocrScans` are intentionally ignored.
      businessName: json['businessName'] as String? ?? '',
      businessRegistrationId: json['businessRegistrationId'] as String? ?? '',
      businessAddress: json['businessAddress'] as String? ?? '',
      locationName: json['locationName'] as String? ?? '',
      tillName: json['tillName'] as String? ?? '',
      cashierName: json['cashierName'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      shiftName: json['shiftName'] as String? ?? '',
      cashierSignaturePngBase64: json['cashierSignaturePngBase64'] as String?,
      managerSignaturePngBase64: json['managerSignaturePngBase64'] as String?,
      blindCount: json['blindCount'] as bool? ?? false,
      blindCountLockedAt: json['blindCountLockedAt'] == null
          ? null
          : DateTime.parse(json['blindCountLockedAt']! as String),
      mode: CountMode.fromStored(json['mode'] as String?),
      customDenominations:
          (json['customDenominations'] as List<Object?>? ?? const <Object?>[])
              .map(
                (item) => Denomination.fromSnapshotJson(
                  (item! as Map<Object?, Object?>).map(
                    (key, value) => MapEntry(key! as String, value),
                  ),
                ),
              )
              .toList(growable: false),
      posReport: json['posReport'] == null
          ? null
          : PosReconciliation.fromJson(
              (json['posReport']! as Map<Object?, Object?>).map(
                (key, value) => MapEntry(key! as String, value),
              ),
            ),
      closingHash: json['closingHash'] as String?,
    );
  }

  final String id;
  final String documentNumber;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int> quantities;
  final int? expectedMinorUnits;
  final int? floatMinorUnits;
  final String note;
  final String closingTitle;
  final String businessName;
  final String businessRegistrationId;
  final String businessAddress;
  final String locationName;
  final String tillName;
  final String cashierName;
  final String managerName;
  final String shiftName;
  final String? cashierSignaturePngBase64;
  final String? managerSignaturePngBase64;
  final bool blindCount;
  final DateTime? blindCountLockedAt;
  final CountMode mode;
  final List<Denomination> customDenominations;
  final PosReconciliation? posReport;
  final String? closingHash;

  bool get hasBusinessIdentity => <String>[
    businessName,
    businessRegistrationId,
    businessAddress,
    locationName,
    tillName,
    cashierName,
    managerName,
    shiftName,
  ].any((value) => value.trim().isNotEmpty);

  bool get quantitiesAreLocked => blindCount && blindCountLockedAt != null;

  int quantityFor(Denomination denomination) =>
      quantities[denomination.id] ?? 0;

  CurrencyDefinition currencyFor(CurrencyDefinition base) {
    if (customDenominations.isEmpty) {
      return base;
    }
    final knownIds = base.denominations.map((item) => item.id).toSet();
    return base.copyWithDenominations(<Denomination>[
      ...base.denominations,
      ...customDenominations.where((item) => knownIds.add(item.id)),
    ]);
  }

  int totalMinorUnits(CurrencyDefinition currency) {
    var total = 0;
    for (final entry in quantities.entries) {
      final denomination = currency.denominationById(entry.key);
      if (denomination != null) {
        total += denomination.minorUnits * entry.value;
      }
    }
    return total;
  }

  int? totalWeightMilligrams(CurrencyDefinition currency) {
    var total = 0;
    for (final entry in quantities.entries) {
      if (entry.value <= 0) {
        continue;
      }
      final denomination = currency.denominationById(entry.key);
      if (denomination != null) {
        final weight = denomination.calculationWeightMilligrams;
        if (weight == null) {
          return null;
        }
        total += weight * entry.value;
      }
    }
    return total;
  }

  bool hasApproximateWeight(CurrencyDefinition currency) {
    for (final entry in quantities.entries) {
      final denomination = currency.denominationById(entry.key);
      if (entry.value > 0 && denomination?.weightIsApproximate == true) {
        return true;
      }
    }
    return false;
  }

  int? differenceMinorUnits(CurrencyDefinition currency) {
    if (expectedMinorUnits == null) {
      return null;
    }
    return totalMinorUnits(currency) - expectedMinorUnits!;
  }

  int? depositMinorUnits(CurrencyDefinition currency) {
    if (floatMinorUnits == null) {
      return null;
    }
    return totalMinorUnits(currency) - floatMinorUnits!;
  }

  CashCountSession copyWith({
    String? currencyCode,
    Map<String, int>? quantities,
    int? expectedMinorUnits,
    bool clearExpected = false,
    int? floatMinorUnits,
    bool clearFloat = false,
    String? note,
    String? closingTitle,
    bool clearClosingTitle = false,
    DateTime? updatedAt,
    String? documentNumber,
    String? businessName,
    String? businessRegistrationId,
    String? businessAddress,
    String? locationName,
    String? tillName,
    String? cashierName,
    String? managerName,
    String? shiftName,
    String? cashierSignaturePngBase64,
    bool clearCashierSignature = false,
    String? managerSignaturePngBase64,
    bool clearManagerSignature = false,
    bool? blindCount,
    DateTime? blindCountLockedAt,
    bool clearBlindCountLock = false,
    CountMode? mode,
    List<Denomination>? customDenominations,
    PosReconciliation? posReport,
    bool clearPosReport = false,
    String? closingHash,
    bool clearClosingHash = false,
  }) {
    return CashCountSession(
      id: id,
      documentNumber: documentNumber ?? this.documentNumber,
      currencyCode: currencyCode ?? this.currencyCode,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      quantities: quantities ?? this.quantities,
      expectedMinorUnits: clearExpected
          ? null
          : expectedMinorUnits ?? this.expectedMinorUnits,
      floatMinorUnits: clearFloat
          ? null
          : floatMinorUnits ?? this.floatMinorUnits,
      note: note ?? this.note,
      closingTitle: clearClosingTitle ? '' : closingTitle ?? this.closingTitle,
      businessName: businessName ?? this.businessName,
      businessRegistrationId:
          businessRegistrationId ?? this.businessRegistrationId,
      businessAddress: businessAddress ?? this.businessAddress,
      locationName: locationName ?? this.locationName,
      tillName: tillName ?? this.tillName,
      cashierName: cashierName ?? this.cashierName,
      managerName: managerName ?? this.managerName,
      shiftName: shiftName ?? this.shiftName,
      cashierSignaturePngBase64: clearCashierSignature
          ? null
          : cashierSignaturePngBase64 ?? this.cashierSignaturePngBase64,
      managerSignaturePngBase64: clearManagerSignature
          ? null
          : managerSignaturePngBase64 ?? this.managerSignaturePngBase64,
      blindCount: blindCount ?? this.blindCount,
      blindCountLockedAt: clearBlindCountLock
          ? null
          : blindCountLockedAt ?? this.blindCountLockedAt,
      mode: mode ?? this.mode,
      customDenominations: customDenominations ?? this.customDenominations,
      posReport: clearPosReport ? null : posReport ?? this.posReport,
      closingHash: clearClosingHash ? null : closingHash ?? this.closingHash,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': currentSchemaVersion,
      'id': id,
      'documentNumber': documentNumber,
      'currencyCode': currencyCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'quantities': quantities,
      'expectedMinorUnits': expectedMinorUnits,
      'floatMinorUnits': floatMinorUnits,
      'note': note,
      'closingTitle': closingTitle,
      'businessName': businessName,
      'businessRegistrationId': businessRegistrationId,
      'businessAddress': businessAddress,
      'locationName': locationName,
      'tillName': tillName,
      'cashierName': cashierName,
      'managerName': managerName,
      'shiftName': shiftName,
      'cashierSignaturePngBase64': cashierSignaturePngBase64,
      'managerSignaturePngBase64': managerSignaturePngBase64,
      'blindCount': blindCount,
      'blindCountLockedAt': blindCountLockedAt?.toIso8601String(),
      'mode': mode.name,
      'customDenominations': customDenominations
          .map((item) => item.toSnapshotJson())
          .toList(growable: false),
      'posReport': posReport?.toJson(),
      'closingHash': closingHash,
    };
  }
}
