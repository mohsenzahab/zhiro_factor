import 'package:equatable/equatable.dart';
import '../../../shared/widgets/date_range_filter_bar.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final double totalGross;
  final double totalProfit;
  final double totalDiscounts;
  final double totalInitialBuyCost;
  final double totalCurrentBuyCost;
  final double pendingAmount;
  final int pendingCount;
  final String? dateFrom;
  final String? dateTo;
  final DateRangePreset preset;
  final List<Map<String, dynamic>> bestSellersByVolume;
  final List<Map<String, dynamic>> bestSellersByRevenue;
  final List<Map<String, dynamic>> recentInvoices;

  const DashboardState({
    this.isLoading = true,
    this.totalGross = 0,
    this.totalProfit = 0,
    this.totalDiscounts = 0,
    this.totalInitialBuyCost = 0,
    this.totalCurrentBuyCost = 0,
    this.pendingAmount = 0,
    this.pendingCount = 0,
    this.dateFrom,
    this.dateTo,
    this.preset = DateRangePreset.thisMonth,
    this.bestSellersByVolume = const [],
    this.bestSellersByRevenue = const [],
    this.recentInvoices = const [],
  });

  /// Total profit margin relative to gross sales (حاشیه سود از کل فروش)
  double get profitPercentOfSales => totalGross > 0 ? (totalProfit / totalGross) * 100.0 : 0.0;

  /// Total profit markup relative to current replacement buy cost (درصد سود روی هزینه خرید)
  double get profitPercentOfCost => totalCurrentBuyCost > 0 ? (totalProfit / totalCurrentBuyCost) * 100.0 : 0.0;

  /// Total discount percentage relative to gross sales (درصد تخفیف از کل فروش)
  double get discountPercentOfSales => totalGross > 0 ? (totalDiscounts / totalGross) * 100.0 : 0.0;

  /// Net sales after settled discounts (فروش خالص پس از تخفیف)
  double get netSales => (totalGross - totalDiscounts).clamp(0.0, double.infinity);

  DashboardState copyWith({
    bool? isLoading,
    double? totalGross,
    double? totalProfit,
    double? totalDiscounts,
    double? totalInitialBuyCost,
    double? totalCurrentBuyCost,
    double? pendingAmount,
    int? pendingCount,
    String? dateFrom,
    String? dateTo,
    bool clearDates = false,
    DateRangePreset? preset,
    List<Map<String, dynamic>>? bestSellersByVolume,
    List<Map<String, dynamic>>? bestSellersByRevenue,
    List<Map<String, dynamic>>? recentInvoices,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalGross: totalGross ?? this.totalGross,
      totalProfit: totalProfit ?? this.totalProfit,
      totalDiscounts: totalDiscounts ?? this.totalDiscounts,
      totalInitialBuyCost: totalInitialBuyCost ?? this.totalInitialBuyCost,
      totalCurrentBuyCost: totalCurrentBuyCost ?? this.totalCurrentBuyCost,
      pendingAmount: pendingAmount ?? this.pendingAmount,
      pendingCount: pendingCount ?? this.pendingCount,
      dateFrom: clearDates ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDates ? null : (dateTo ?? this.dateTo),
      preset: preset ?? this.preset,
      bestSellersByVolume: bestSellersByVolume ?? this.bestSellersByVolume,
      bestSellersByRevenue: bestSellersByRevenue ?? this.bestSellersByRevenue,
      recentInvoices: recentInvoices ?? this.recentInvoices,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        totalGross,
        totalProfit,
        totalDiscounts,
        totalInitialBuyCost,
        totalCurrentBuyCost,
        pendingAmount,
        pendingCount,
        dateFrom,
        dateTo,
        preset,
        bestSellersByVolume,
        bestSellersByRevenue,
        recentInvoices,
      ];
}
