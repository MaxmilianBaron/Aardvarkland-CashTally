import 'dart:math';

import 'package:flutter/foundation.dart';

import 'business_profile.dart';

@immutable
class TillTemplate {
  const TillTemplate({
    required this.id,
    required this.name,
    required this.currencyCode,
    required this.profile,
    this.floatMinorUnits,
  });

  static final Random _random = Random.secure();

  factory TillTemplate.create({
    required String name,
    required String currencyCode,
    required BusinessProfile profile,
    int? floatMinorUnits,
  }) {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final entropy = _random.nextInt(0x100000000).toRadixString(36);
    return TillTemplate(
      id: 'till_${timestamp}_$entropy',
      name: name.trim(),
      currencyCode: currencyCode,
      profile: profile,
      floatMinorUnits: floatMinorUnits,
    );
  }

  factory TillTemplate.fromJson(Map<String, Object?> json) {
    return TillTemplate(
      id: json['id']! as String,
      name: json['name']! as String,
      currencyCode: json['currencyCode']! as String,
      profile: BusinessProfile.fromJson(
        (json['profile']! as Map<Object?, Object?>).map(
          (key, value) => MapEntry(key! as String, value),
        ),
      ),
      floatMinorUnits: (json['floatMinorUnits'] as num?)?.toInt(),
    );
  }

  final String id;
  final String name;
  final String currencyCode;
  final BusinessProfile profile;
  final int? floatMinorUnits;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'name': name,
    'currencyCode': currencyCode,
    'profile': profile.toJson(),
    'floatMinorUnits': floatMinorUnits,
  };
}
