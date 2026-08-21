import 'package:flutter/foundation.dart';

@immutable
class BusinessProfile {
  const BusinessProfile({
    this.businessName = '',
    this.registrationId = '',
    this.address = '',
    this.locationName = '',
    this.tillName = '',
    this.cashierName = '',
    this.managerName = '',
    this.shiftName = '',
  });

  factory BusinessProfile.fromJson(Map<String, Object?> json) {
    return BusinessProfile(
      businessName: json['businessName'] as String? ?? '',
      registrationId: json['registrationId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      locationName: json['locationName'] as String? ?? '',
      tillName: json['tillName'] as String? ?? '',
      cashierName: json['cashierName'] as String? ?? '',
      managerName: json['managerName'] as String? ?? '',
      shiftName: json['shiftName'] as String? ?? '',
    );
  }

  final String businessName;
  final String registrationId;
  final String address;
  final String locationName;
  final String tillName;
  final String cashierName;
  final String managerName;
  final String shiftName;

  bool get isEmpty => <String>[
    businessName,
    registrationId,
    address,
    locationName,
    tillName,
    cashierName,
    managerName,
    shiftName,
  ].every((value) => value.trim().isEmpty);

  Map<String, Object?> toJson() => <String, Object?>{
    'businessName': businessName.trim(),
    'registrationId': registrationId.trim(),
    'address': address.trim(),
    'locationName': locationName.trim(),
    'tillName': tillName.trim(),
    'cashierName': cashierName.trim(),
    'managerName': managerName.trim(),
    'shiftName': shiftName.trim(),
  };
}
