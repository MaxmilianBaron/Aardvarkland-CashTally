import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/models/business_profile.dart';

void main() {
  test('business profile round-trip preserves every default field', () {
    const profile = BusinessProfile(
      businessName: 'Example Ltd.',
      registrationId: 'VAT-42',
      address: 'Main Street 1',
      locationName: 'Airport',
      tillName: 'T2',
      cashierName: 'Mia',
      managerName: 'Noah',
      shiftName: 'Night',
    );

    expect(
      BusinessProfile.fromJson(profile.toJson()).toJson(),
      profile.toJson(),
    );
    expect(profile.isEmpty, isFalse);
    expect(const BusinessProfile().isEmpty, isTrue);
  });

  test('missing profile fields migrate to empty values', () {
    final profile = BusinessProfile.fromJson(const <String, Object?>{
      'businessName': 'Legacy business',
    });

    expect(profile.businessName, 'Legacy business');
    expect(profile.registrationId, isEmpty);
    expect(profile.tillName, isEmpty);
  });
}
