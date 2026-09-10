import 'package:intl/intl.dart';

const _englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
const _persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

/// Extension for converting digits between Persian and English/Arabic.
extension PersianDigitConversion on String {
  /// Converts ASCII digits (0-9) and Arabic-Indic digits to Persian digits (۰-۹).
  String toPersianDigits() {
    var result = this;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(_englishDigits[i], _persianDigits[i]);
      result = result.replaceAll(_arabicDigits[i], _persianDigits[i]);
    }
    return result;
  }

  /// Converts Persian and Arabic-Indic digits to standard ASCII English digits (0-9).
  String toEnglishDigits() {
    var result = this;
    for (var i = 0; i < 10; i++) {
      result = result.replaceAll(_persianDigits[i], _englishDigits[i]);
      result = result.replaceAll(_arabicDigits[i], _englishDigits[i]);
    }
    return result;
  }
}

/// Extension on [num] for Persian-style comma-separated formatting with Persian digits.
extension NumberFormatting on num {
  /// Formats number with comma separators and Persian digits: 1000000 → "۱,۰۰۰,۰۰۰"
  String get formatted {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(this).toPersianDigits();
  }

  /// Formats number with comma separators, Persian digits and تومان suffix: 1000000 → "۱,۰۰۰,۰۰۰ تومان"
  String get toman {
    return '$formatted تومان';
  }

  /// Formats number as integer with comma separators and Persian digits (truncates decimals): 1000 → "۱,۰۰۰"
  String get formattedInt {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(toInt()).toPersianDigits();
  }

  /// Formats number with fixed decimal places and Persian digits: 12.5 → "۱۲.۵"
  String formattedFixed([int fractionDigits = 1]) {
    return toStringAsFixed(fractionDigits).toPersianDigits();
  }

  /// Formats number as percentage with Persian digits: 12.5 → "۱۲.۵٪"
  String get percentDisplay {
    final s = this % 1 == 0 ? toInt().toString() : toStringAsFixed(1);
    return '${s.toPersianDigits()}٪';
  }
}

/// Extension on [String] for parsing formatted numbers back.
extension NumberParsing on String {
  /// Removes comma separators and parses to double (handles Persian and Arabic digits).
  double? tryParseFormatted() {
    final ascii = toEnglishDigits();
    final cleaned = ascii
        .replaceAll(',', '')
        .replaceAll('،', '')
        .replaceAll(' ', '')
        .replaceAll('تومان', '')
        .trim();
    return double.tryParse(cleaned);
  }

  /// Removes comma separators and parses to double (throws if invalid).
  double parseFormatted() {
    final result = tryParseFormatted();
    if (result == null) throw FormatException('Cannot parse "$this" as number');
    return result;
  }

  /// Whether this string represents a valid formatted number.
  bool get isValidNumber => tryParseFormatted() != null;
}

/// Extension on [num] for price rounding in retail.
extension PriceRounding on num {
  /// Rounds a price to the nearest multiple of 5,000 (standard Iranian retail rounding).
  /// E.g. 77000 or 77400 → 75000, 77500 or 78000 → 80000, 72000 → 70000, 72600 or 73000 → 75000.
  double get roundTo5000 {
    if (this <= 0) return 0.0;
    final rounded = (this / 5000.0).round() * 5000.0;
    if (rounded > 0) return rounded;
    return this >= 2500 ? 5000.0 : ((this / 1000.0).round() * 1000.0);
  }
}

