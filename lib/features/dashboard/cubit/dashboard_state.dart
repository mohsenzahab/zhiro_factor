import 'package:equatable/equatable.dart';

class DashboardState extends Equatable {
  final bool isLoading;
  final double totalGross;
  final double totalNet;
  final double totalDiscounts;
  final int outstandingCount;
  final List<Map<String, dynamic>> bestSellersByVolume;
  final List<Map<String, dynamic>> bestSellersByRevenue;
  final List<Map<String, dynamic>> recentInvoices;

  const DashboardState({
    this.isLoading = true,
    this.totalGross = 0,
    this.totalNet = 0,
    this.totalDiscounts = 0,
    this.outstandingCount = 0,
    this.bestSellersByVolume = const [],
    this.bestSellersByRevenue = const [],
    this.recentInvoices = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    double? totalGross,
    double? totalNet,
    double? totalDiscounts,
    int? outstandingCount,
    List<Map<String, dynamic>>? bestSellersByVolume,
    List<Map<String, dynamic>>? bestSellersByRevenue,
    List<Map<String, dynamic>>? recentInvoices,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      totalGross: totalGross ?? this.totalGross,
      totalNet: totalNet ?? this.totalNet,
      totalDiscounts: totalDiscounts ?? this.totalDiscounts,
      outstandingCount: outstandingCount ?? this.outstandingCount,
      bestSellersByVolume: bestSellersByVolume ?? this.bestSellersByVolume,
      bestSellersByRevenue: bestSellersByRevenue ?? this.bestSellersByRevenue,
      recentInvoices: recentInvoices ?? this.recentInvoices,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        totalGross,
        totalNet,
        totalDiscounts,
        outstandingCount,
        bestSellersByVolume,
        bestSellersByRevenue,
        recentInvoices,
      ];
}
