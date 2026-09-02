import 'package:equatable/equatable.dart';

class ReportState extends Equatable {
  final bool isLoading;
  final List<Map<String, dynamic>> ledgerData;
  final String? dateFrom;
  final String? dateTo;

  const ReportState({
    this.isLoading = false,
    this.ledgerData = const [],
    this.dateFrom,
    this.dateTo,
  });

  ReportState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? ledgerData,
    String? dateFrom,
    String? dateTo,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      ledgerData: ledgerData ?? this.ledgerData,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
    );
  }

  @override
  List<Object?> get props => [isLoading, ledgerData, dateFrom, dateTo];
}
