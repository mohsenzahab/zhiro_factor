import 'package:equatable/equatable.dart';
import '../../core/extensions/number_extensions.dart';
import '../../core/utils/jalali_utils.dart';

/// Represents a historical record of a product's buy price modification.
class PriceChangeModel extends Equatable {
  final int? id;
  final int productId;
  final String? productName;
  final String? productCode;
  final String? category;
  final double oldPrice;
  final double newPrice;
  final double changeAmount;
  final String changeType; // 'manual' | 'batch_adjustment' | 'purchase'
  final String? changeSource;
  final String createdAt;

  const PriceChangeModel({
    this.id,
    required this.productId,
    this.productName,
    this.productCode,
    this.category,
    required this.oldPrice,
    required this.newPrice,
    required this.changeAmount,
    required this.changeType,
    this.changeSource,
    required this.createdAt,
  });

  /// Dynamically computed change percentage (not stored in DB).
  double get changePercent =>
      oldPrice > 0 ? ((changeAmount / oldPrice) * 100.0) : 0.0;

  bool get isIncrease => changeAmount > 0;
  bool get isDecrease => changeAmount < 0;

  /// Human readable Persian change amount with sign (e.g. "+۵,۰۰۰ تومان" or "-۲,۰۰۰ تومان").
  String get changeAmountDisplay {
    final prefix = isIncrease ? '+' : (isDecrease ? '' : '');
    return '$prefix${changeAmount.round().formatted} تومان';
  }

  /// Human readable change percentage (e.g. "+۱۵.۵٪" or "-۱۰٪").
  String get changePercentDisplay {
    final prefix = isIncrease ? '+' : '';
    final pct = changePercent;
    if ((pct - pct.roundToDouble()).abs() < 0.05) {
      return '$prefix${pct.round().toString().toPersianDigits()}٪';
    }
    return '$prefix${pct.toStringAsFixed(1).toPersianDigits()}٪';
  }

  /// Persian translated change type label.
  String get changeTypeDisplay {
    switch (changeType) {
      case 'manual':
        return 'ویرایش دستی';
      case 'batch_adjustment':
        return 'تغییر گروهی';
      case 'purchase':
        return 'فاکتور خرید';
      default:
        return changeType;
    }
  }

  /// Jalali date representation formatted as "YYYY/MM/DD".
  String get createdAtJalali {
    try {
      return JalaliUtils.formatIso(createdAt);
    } catch (_) {
      return createdAt;
    }
  }

  /// Jalali date and time representation (e.g. "۱۴۰۳/۰۵/۱۲ ۱4:۳۰").
  String get createdAtJalaliWithTime {
    try {
      final j = JalaliUtils.fromIso(createdAt);
      final dt = DateTime.parse(createdAt);
      final timeStr =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
              .toPersianDigits();
      return '${JalaliUtils.format(j)} $timeStr';
    } catch (_) {
      return createdAtJalali;
    }
  }

  factory PriceChangeModel.fromMap(Map<String, dynamic> map) {
    return PriceChangeModel(
      id: map['id'] as int?,
      productId: map['product_id'] as int,
      productName: map['product_name'] as String?,
      productCode: map['product_code'] as String?,
      category: map['category'] as String?,
      oldPrice: (map['old_price'] as num?)?.toDouble() ?? 0.0,
      newPrice: (map['new_price'] as num?)?.toDouble() ?? 0.0,
      changeAmount: (map['change_amount'] as num?)?.toDouble() ?? 0.0,
      changeType: (map['change_type'] as String?) ?? 'manual',
      changeSource: map['change_source'] as String?,
      createdAt: map['created_at'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'product_id': productId,
      'old_price': oldPrice,
      'new_price': newPrice,
      'change_amount': changeAmount,
      'change_type': changeType,
      'change_source': changeSource,
      'created_at': createdAt,
    };
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

  PriceChangeModel copyWith({
    int? id,
    int? productId,
    String? productName,
    String? productCode,
    String? category,
    double? oldPrice,
    double? newPrice,
    double? changeAmount,
    String? changeType,
    String? changeSource,
    String? createdAt,
  }) {
    return PriceChangeModel(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productCode: productCode ?? this.productCode,
      category: category ?? this.category,
      oldPrice: oldPrice ?? this.oldPrice,
      newPrice: newPrice ?? this.newPrice,
      changeAmount: changeAmount ?? this.changeAmount,
      changeType: changeType ?? this.changeType,
      changeSource: changeSource ?? this.changeSource,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productCode,
        category,
        oldPrice,
        newPrice,
        changeAmount,
        changeType,
        changeSource,
        createdAt,
      ];
}
