import 'package:flutter/material.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/jalali_utils.dart';

enum DateRangePreset {
  allTime,
  today,
  thisWeek,
  thisMonth,
  custom,
}

/// Shared Persian date range filter bar with presets and calendar picker.
class DateRangeFilterBar extends StatefulWidget {
  final DateRangePreset initialPreset;
  final String? initialDateFrom;
  final String? initialDateTo;
  final void Function({
    required DateRangePreset preset,
    String? dateFrom,
    String? dateTo,
  }) onRangeChanged;

  const DateRangeFilterBar({
    super.key,
    this.initialPreset = DateRangePreset.thisMonth,
    this.initialDateFrom,
    this.initialDateTo,
    required this.onRangeChanged,
  });

  @override
  State<DateRangeFilterBar> createState() => _DateRangeFilterBarState();
}

class _DateRangeFilterBarState extends State<DateRangeFilterBar> {
  late DateRangePreset _selectedPreset;
  Jalali? _customFromJalali;
  Jalali? _customToJalali;

  @override
  void initState() {
    super.initState();
    _selectedPreset = widget.initialPreset;
    if (widget.initialDateFrom != null && widget.initialDateFrom!.isNotEmpty) {
      try {
        _customFromJalali = JalaliUtils.fromIso(widget.initialDateFrom!);
      } catch (_) {}
    }
    if (widget.initialDateTo != null && widget.initialDateTo!.isNotEmpty) {
      try {
        _customToJalali = JalaliUtils.fromIso(widget.initialDateTo!);
      } catch (_) {}
    }
  }

  void _selectPreset(DateRangePreset preset) {
    setState(() => _selectedPreset = preset);
    String? dateFrom;
    String? dateTo;

    switch (preset) {
      case DateRangePreset.allTime:
        dateFrom = null;
        dateTo = null;
        break;
      case DateRangePreset.today:
        final r = JalaliUtils.todayRange;
        dateFrom = r.$1;
        dateTo = r.$2;
        break;
      case DateRangePreset.thisWeek:
        final r = JalaliUtils.thisWeekRange;
        dateFrom = r.$1;
        dateTo = r.$2;
        break;
      case DateRangePreset.thisMonth:
        final r = JalaliUtils.thisMonthRange;
        dateFrom = r.$1;
        dateTo = r.$2;
        break;
      case DateRangePreset.custom:
        if (_customFromJalali != null) {
          dateFrom = JalaliUtils.startOfDayIso(_customFromJalali!);
        }
        if (_customToJalali != null) {
          dateTo = JalaliUtils.endOfDayIso(_customToJalali!);
        }
        break;
    }

    widget.onRangeChanged(
      preset: preset,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  Future<void> _pickFromDate() async {
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: _customFromJalali ?? Jalali.now(),
      firstDate: Jalali(1400, 1, 1),
      lastDate: Jalali(1430, 12, 29),
    );
    if (picked != null) {
      setState(() {
        _customFromJalali = picked;
        _selectedPreset = DateRangePreset.custom;
      });
      _notifyCustomRange();
    }
  }

  Future<void> _pickToDate() async {
    final picked = await showPersianDatePicker(
      context: context,
      initialDate: _customToJalali ?? _customFromJalali ?? Jalali.now(),
      firstDate: Jalali(1400, 1, 1),
      lastDate: Jalali(1430, 12, 29),
    );
    if (picked != null) {
      setState(() {
        _customToJalali = picked;
        _selectedPreset = DateRangePreset.custom;
      });
      _notifyCustomRange();
    }
  }

  void _notifyCustomRange() {
    final dateFrom = _customFromJalali != null
        ? JalaliUtils.startOfDayIso(_customFromJalali!)
        : null;
    final dateTo = _customToJalali != null
        ? JalaliUtils.endOfDayIso(_customToJalali!)
        : null;

    widget.onRangeChanged(
      preset: DateRangePreset.custom,
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Icon and Label
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_outlined, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                AppStrings.dateRange,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          // Preset Chips
          _buildPresetChip(DateRangePreset.allTime, AppStrings.allTime),
          _buildPresetChip(DateRangePreset.thisMonth, AppStrings.thisMonth),
          _buildPresetChip(DateRangePreset.thisWeek, AppStrings.thisWeek),
          _buildPresetChip(DateRangePreset.today, AppStrings.today),
          _buildPresetChip(DateRangePreset.custom, AppStrings.customRange),

          // Custom Date Range pickers (visible or emphasized when custom selected)
          if (_selectedPreset == DateRangePreset.custom) ...[
            const SizedBox(width: 4),
            _buildDatePickerButton(
              label: AppStrings.fromDate,
              date: _customFromJalali,
              onTap: _pickFromDate,
            ),
            const Icon(Icons.arrow_back, size: 16, color: AppColors.textMuted),
            _buildDatePickerButton(
              label: AppStrings.toDate,
              date: _customToJalali,
              onTap: _pickToDate,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetChip(DateRangePreset preset, String label) {
    final isSelected = _selectedPreset == preset;
    return InkWell(
      onTap: () => _selectPreset(preset),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.2)
              : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.dividerDark,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerButton({
    required String label,
    required Jalali? date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.dividerDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              date != null ? JalaliUtils.format(date) : label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: date != null ? FontWeight.w600 : FontWeight.normal,
                color: date != null ? AppColors.textPrimary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
