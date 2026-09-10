import 'package:flutter_test/flutter_test.dart';
import 'package:sales_box/core/extensions/number_extensions.dart';
import 'package:sales_box/core/utils/jalali_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';

void main() {
  group('Persian Numbers and Digit Formatting Tests', () {
    test('NumberFormatting.formatted outputs Persian digits with commas', () {
      expect((1000).formatted, equals('۱,۰۰۰'));
      expect((1000000).formatted, equals('۱,۰۰۰,۰۰۰'));
      expect((0).formatted, equals('۰'));
    });

    test('NumberFormatting.toman outputs Persian digits with تومان', () {
      expect((50000).toman, equals('۵۰,۰۰۰ تومان'));
      expect((0).toman, equals('۰ تومان'));
    });

    test('NumberFormatting.formattedInt truncates decimals and outputs Persian digits', () {
      expect((1250.75).formattedInt, equals('۱,۲۵۰'));
      expect((5).formattedInt, equals('۵'));
    });

    test('NumberFormatting.percentDisplay formats percentages in Persian', () {
      expect((25).percentDisplay, equals('۲۵٪'));
      expect((12.5).percentDisplay, equals('۱۲.۵٪'));
    });

    test('PersianDigitConversion converts bidirectionally', () {
      expect('INV-2026-0042'.toPersianDigits(), equals('INV-۲۰۲۶-۰۰۴۲'));
      expect('INV-۲۰۲۶-۰۰۴۲'.toEnglishDigits(), equals('INV-2026-0042'));
    });

    test('NumberParsing.tryParseFormatted handles Persian and Arabic digits and تومان', () {
      expect('۱,۵۰۰,۰۰۰ تومان'.tryParseFormatted(), equals(1500000.0));
      expect('۵۰,۰۰۰'.tryParseFormatted(), equals(50000.0));
      expect('١٢.٥'.tryParseFormatted(), equals(12.5));
      expect('1,000'.tryParseFormatted(), equals(1000.0));
    });

    test('JalaliUtils formats and parses Persian digits', () {
      final date = Jalali(1405, 6, 8);
      expect(JalaliUtils.format(date), equals('۱۴۰۵/۰۶/۰۸'));
      expect(JalaliUtils.formatLong(date), equals('۸ شهریور ۱۴۰۵'));

      final parsed = JalaliUtils.tryParse('۱۴۰۵/۰۶/۰۸');
      expect(parsed, isNotNull);
      expect(parsed!.year, equals(1405));
      expect(parsed.month, equals(6));
      expect(parsed.day, equals(8));
    });

    test('NumberParsing.isValidNumber validates Persian and English numbers', () {
      expect('۱,۵۰۰,۰۰۰'.isValidNumber, isTrue);
      expect('۵۰'.isValidNumber, isTrue);
      expect('۲۵.۵'.isValidNumber, isTrue);
      expect('25.5'.isValidNumber, isTrue);
      expect('abc'.isValidNumber, isFalse);
      expect(''.isValidNumber, isFalse);
    });
  });
}
