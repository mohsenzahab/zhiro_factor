import 'package:intl/intl.dart';

/// Extension on [num] for Persian-style comma-separated formatting.
extension NumberFormatting on num {
  /// Formats number with comma separators: 1000000 → "1,000,000"
  String get formatted {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(this);
  }

  /// Formats number with comma separators and تومان suffix.
  String get toman {
    return '${formatted} تومان';
  }

  /// Formats number as integer with comma separators (truncates decimals).
  String get formattedInt {
    final formatter = NumberFormat('#,###', 'en_US');
    return formatter.format(toInt());
  }
}

/// Extension on [String] for parsing formatted numbers back.
extension NumberParsing on String {
  /// Removes comma separators and parses to double.
  double? tryParseFormatted() {
    final cleaned = replaceAll(',', '').replaceAll(' ', '').replaceAll('تومان', '').trim();
    return double.tryParse(cleaned);
  }

  /// Removes comma separators and parses to double (throws if invalid).
  double parseFormatted() {
    final result = tryParseFormatted();
    if (result == null) throw FormatException('Cannot parse "$this" as number');
    return result;
  }
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

