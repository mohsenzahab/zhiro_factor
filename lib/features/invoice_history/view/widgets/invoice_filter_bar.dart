import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_colors.dart';

/// Filter bar for invoice history with status and search.
class InvoiceFilterBar extends StatelessWidget {
  final String? statusFilter;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;

  const InvoiceFilterBar({
    super.key,
    this.statusFilter,
    required this.onStatusChanged,
    required this.onSearchChanged,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerDark),
      ),
      child: Row(
        children: [
          // Search
          SizedBox(
            width: 280,
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'جستجو بر اساس مشتری یا شماره فاکتور...',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (_, v, __) {
                    if (v.text.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close, size: 16),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status filter chips
          const Text('وضعیت:', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(width: 8),
          _StatusChip(
            label: 'همه',
            isSelected: statusFilter == null,
            onTap: () => onStatusChanged(null),
          ),
          ...AppStrings.invoiceStatuses.map((s) {
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _StatusChip(
                label: s,
                isSelected: statusFilter == s,
                color: AppColors.statusColor(s),
                onTap: () => onStatusChanged(s),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? AppColors.primary).withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? AppColors.primary).withValues(alpha: 0.5)
                : AppColors.dividerDark,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (color != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? (color ?? AppColors.primary) : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
