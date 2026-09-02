import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Styled data table wrapper with zebra-striping and custom scrollbars.
class DataTableWrapper extends StatelessWidget {
  final List<DataColumn> columns;
  final List<DataRow> rows;
  final bool showBottomBorder;

  const DataTableWrapper({
    super.key,
    required this.columns,
    required this.rows,
    this.showBottomBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    // Apply zebra striping
    final styledRows = List<DataRow>.generate(rows.length, (index) {
      final row = rows[index];
      return DataRow(
        key: row.key,
        selected: row.selected,
        onSelectChanged: row.onSelectChanged,
        onLongPress: row.onLongPress,
        color: row.color ?? WidgetStateProperty.all(
          index.isEven ? AppColors.tableRowEven : AppColors.tableRowOdd,
        ),
        cells: row.cells,
      );
    });

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      clipBehavior: Clip.antiAlias,
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columns: columns,
              rows: styledRows,
              showBottomBorder: showBottomBorder,
              headingRowHeight: 48,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 52,
              columnSpacing: 24,
              horizontalMargin: 16,
            ),
          ),
        ),
      ),
    );
  }
}
