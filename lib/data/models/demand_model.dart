import 'package:equatable/equatable.dart';
import '../../core/extensions/number_extensions.dart';

/// Demand / Wishlist item data model representing customer requests for unstocked goods/services.
class DemandModel extends Equatable {
  static const String statusPending = 'تهیه نشده';
  static const String statusInPreparation = 'در حال تهیه';
  static const String statusProcured = 'تهیه شده';
  static const List<String> allStatuses = [statusPending, statusInPreparation, statusProcured];

  final int? id;
  final String title;
  final String? category;
  final double? buyPrice;
  final double? sellPrice;
  final String status;
  final double targetQuantity;
  final String? notes;
  final List<String> requestDates;
  final String createdAt;
  final String updatedAt;

  DemandModel({
    this.id,
    required this.title,
    this.category,
    this.buyPrice,
    this.sellPrice,
    this.status = statusPending,
    this.targetQuantity = 1.0,
    this.notes,
    this.requestDates = const [],
    String? createdAt,
    String? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now().toIso8601String(),
        updatedAt = updatedAt ?? DateTime.now().toIso8601String();

  /// Total number of customer requests recorded for this item.
  int get requestCount => requestDates.length;

  /// Earliest request ISO date string.
  String? get firstRequestDate {
    if (requestDates.isEmpty) return null;
    final sorted = List<String>.from(requestDates)..sort();
    return sorted.first;
  }

  /// Latest request ISO date string.
  String? get latestRequestDate {
    if (requestDates.isEmpty) return null;
    final sorted = List<String>.from(requestDates)..sort();
    return sorted.last;
  }

  /// Total capital required to procure the target quantity (تعداد خرید × بهای خرید).
  double get requiredCapital => (buyPrice ?? 0.0) * targetQuantity;

  /// Estimated profit per single unit (قیمت فروش - قیمت خرید).
  double? get unitProfit {
    if (sellPrice != null && buyPrice != null) {
      return sellPrice! - buyPrice!;
    }
    return null;
  }

  /// Total projected profit for procuring and selling targetQuantity (سود کل = سود واحد × تعداد).
  double? get totalProjectedProfit {
    if (unitProfit != null) {
      return unitProfit! * targetQuantity;
    }
    return null;
  }

  /// Projected profit margin percentage relative to buy price.
  double? get profitMargin {
    if (unitProfit != null && buyPrice != null && buyPrice! > 0) {
      return (unitProfit! / buyPrice!) * 100.0;
    }
    return null;
  }

  /// Average customer requests per month.
  double get averageRequestsPerMonth {
    if (requestDates.isEmpty) return 0.0;
    final first = DateTime.tryParse(firstRequestDate ?? '');
    if (first == null) return requestDates.length.toDouble();

    final now = DateTime.now();
    final days = now.difference(first).inDays;
    if (days < 30) {
      return requestDates.length.toDouble();
    }
    final months = days / 30.4375;
    return requestDates.length / months;
  }

  /// Persian display for average requests per month.
  String get averageRequestsPerMonthDisplay {
    final avg = averageRequestsPerMonth;
    if (avg == avg.toInt().toDouble()) {
      return '${avg.toInt().toString().toPersianDigits()} در ماه';
    }
    return '${avg.toStringAsFixed(1).toPersianDigits()} در ماه';
  }

  DemandModel copyWith({
    int? id,
    String? title,
    String? category,
    double? buyPrice,
    double? sellPrice,
    bool clearSellPrice = false,
    bool clearBuyPrice = false,
    String? status,
    double? targetQuantity,
    String? notes,
    List<String>? requestDates,
    String? createdAt,
    String? updatedAt,
  }) {
    return DemandModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      buyPrice: clearBuyPrice ? null : (buyPrice ?? this.buyPrice),
      sellPrice: clearSellPrice ? null : (sellPrice ?? this.sellPrice),
      status: status ?? this.status,
      targetQuantity: targetQuantity ?? this.targetQuantity,
      notes: notes ?? this.notes,
      requestDates: requestDates ?? this.requestDates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DemandModel.fromMap(Map<String, dynamic> map, {List<String>? requestDates}) {
    return DemandModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      category: map['category'] as String?,
      buyPrice: (map['buy_price'] as num?)?.toDouble(),
      sellPrice: (map['sell_price'] as num?)?.toDouble(),
      status: map['status'] as String? ?? statusPending,
      targetQuantity: (map['target_quantity'] as num?)?.toDouble() ?? 1.0,
      notes: map['notes'] as String?,
      requestDates: requestDates ?? const [],
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'category': category,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
      'status': status,
      'target_quantity': targetQuantity,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        buyPrice,
        sellPrice,
        status,
        targetQuantity,
        notes,
        requestDates,
        createdAt,
        updatedAt,
      ];
}
