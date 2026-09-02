import 'package:shamsi_date/shamsi_date.dart';

/// Utility helpers for Jalali (Shamsi / Solar Hijri) dates.
class JalaliUtils {
  JalaliUtils._();

  /// Current Jalali date.
  static Jalali get now => Jalali.now();

  /// Formats a Jalali date as "YYYY/MM/DD" (e.g., "1405/06/08").
  static String format(Jalali date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y/$m/$d';
  }

  /// Formats a Jalali date with month name: "8 شهریور 1405".
  static String formatLong(Jalali date) {
    return '${date.day} ${_monthName(date.month)} ${date.year}';
  }

  /// Parses a "YYYY/MM/DD" string to Jalali.
  static Jalali? tryParse(String text) {
    try {
      final parts = text.split('/');
      if (parts.length != 3) return null;
      return Jalali(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return null;
    }
  }

  /// Converts Jalali to Gregorian DateTime for storage.
  static DateTime toGregorian(Jalali date) {
    return date.toGregorian().toDateTime();
  }

  /// Converts Gregorian DateTime to Jalali.
  static Jalali fromGregorian(DateTime dateTime) {
    return Jalali.fromDateTime(dateTime);
  }

  /// Converts Jalali to ISO 8601 string for database storage.
  static String toIso(Jalali date) {
    return toGregorian(date).toIso8601String();
  }

  /// Converts ISO 8601 string from database to Jalali.
  static Jalali fromIso(String isoString) {
    return fromGregorian(DateTime.parse(isoString));
  }

  /// Returns the Persian name of a Jalali month.
  static String _monthName(int month) {
    const months = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    return months[month - 1];
  }

  /// Returns Persian day-of-week name.
  static String dayOfWeekName(Jalali date) {
    const days = [
      'شنبه',
      'یکشنبه',
      'دوشنبه',
      'سه‌شنبه',
      'چهارشنبه',
      'پنجشنبه',
      'جمعه',
    ];
    return days[date.weekDay - 1];
  }
}
