import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/core/app_config.dart';

void main() {
  test('default public launch mode has no ads or purchases', () {
    expect(AppConfig.monetizationEnabled, isFalse);
    expect(AppConfig.adsEnabled, isFalse);
  });
}
