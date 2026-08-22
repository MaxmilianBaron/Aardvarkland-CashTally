import 'package:flutter/foundation.dart';

@immutable
class PosReconciliation {
  const PosReconciliation({
    required this.id,
    required this.sourceFileName,
    required this.currencyCode,
    required this.importedAt,
    required this.sourceSha256,
    this.expectedCashMinorUnits,
    this.cardMinorUnits,
    this.totalSalesMinorUnits,
    this.tillName = '',
    this.cashierName = '',
    this.reportAt,
  });

  factory PosReconciliation.fromJson(Map<String, Object?> json) {
    return PosReconciliation(
      id: json['id']! as String,
      sourceFileName: json['sourceFileName'] as String? ?? '',
      currencyCode: json['currencyCode']! as String,
      importedAt: DateTime.parse(json['importedAt']! as String),
      sourceSha256: json['sourceSha256'] as String? ?? '',
      expectedCashMinorUnits: (json['expectedCashMinorUnits'] as num?)?.toInt(),
      cardMinorUnits: (json['cardMinorUnits'] as num?)?.toInt(),
      totalSalesMinorUnits: (json['totalSalesMinorUnits'] as num?)?.toInt(),
      tillName: json['tillName'] as String? ?? '',
      cashierName: json['cashierName'] as String? ?? '',
      reportAt: json['reportAt'] == null
          ? null
          : DateTime.tryParse(json['reportAt']! as String),
    );
  }

  final String id;
  final String sourceFileName;
  final String currencyCode;
  final DateTime importedAt;
  final String sourceSha256;
  final int? expectedCashMinorUnits;
  final int? cardMinorUnits;
  final int? totalSalesMinorUnits;
  final String tillName;
  final String cashierName;
  final DateTime? reportAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'sourceFileName': sourceFileName,
    'currencyCode': currencyCode,
    'importedAt': importedAt.toIso8601String(),
    'sourceSha256': sourceSha256,
    'expectedCashMinorUnits': expectedCashMinorUnits,
    'cardMinorUnits': cardMinorUnits,
    'totalSalesMinorUnits': totalSalesMinorUnits,
    'tillName': tillName,
    'cashierName': cashierName,
    'reportAt': reportAt?.toIso8601String(),
  };
}
