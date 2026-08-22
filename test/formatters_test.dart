import 'package:flutter_test/flutter_test.dart';
import 'package:vycetka/core/formatters.dart';

void main() {
  test('money parsing accepts Czech decimal comma', () {
    expect(AppFormatters.parseMoneyToMinor('1 234,56'), 123456);
  });

  test('money parsing accepts Czech and English grouping', () {
    expect(AppFormatters.parseMoneyToMinor('1.234,56 Kč'), 123456);
    expect(AppFormatters.parseMoneyToMinor(r'$1,234.56'), 123456);
    expect(AppFormatters.parseMoneyToMinor('1.234'), 123400);
  });

  test('money parsing uses exact minor units rather than floating point', () {
    expect(AppFormatters.parseMoneyToMinor('0,10'), 10);
    expect(AppFormatters.parseMoneyToMinor('-0.50'), -50);
  });

  test('money input formatting keeps a negative sub-unit sign', () {
    expect(AppFormatters.moneyInputFromMinor(-50), '-0.50');
    expect(AppFormatters.moneyInputFromMinor(-150), '-1.50');
  });

  test('zero-fraction currencies never multiply values by one hundred', () {
    expect(AppFormatters.parseMoneyToMinor('50 000', fractionDigits: 0), 50000);
    expect(AppFormatters.parseMoneyToMinor('1,000', fractionDigits: 0), 1000);
    expect(
      AppFormatters.moneyInputFromMinor(10000, fractionDigits: 0),
      '10000',
    );
  });

  test(
    'formats exact and approximate weights without floating point storage',
    () {
      expect(AppFormatters.weight(7700, localeCode: 'en'), '7.7 g');
      expect(
        AppFormatters.weight(
          null,
          localeCode: 'en',
          unavailableLabel: 'Unavailable',
        ),
        'Unavailable',
      );
      expect(
        AppFormatters.weight(1250000, localeCode: 'cs', approximate: true),
        '≈ 1,3 kg',
      );
    },
  );

  test(
    'capitalizes the first letter and the first letter after punctuation',
    () {
      const formatter = SentenceCaseTextFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(),
        const TextEditingValue(
          text: 'ahoj. další věta! česky? ano\nnový řádek',
        ),
      );

      expect(result.text, 'Ahoj. Další věta! Česky? Ano\nNový řádek');
    },
  );

  test('capitalization leaves leading numbers intact in pasted text', () {
    const formatter = SentenceCaseTextFormatter();
    final result = formatter.formatEditUpdate(
      const TextEditingValue(),
      const TextEditingValue(text: '123 abc_42. 7 dní'),
    );

    expect(result.text, '123 Abc_42. 7 Dní');
  });
}
