import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/extensions/number_extensions.dart';

/// Reusable category filter bar with responsive horizontal scroll and "All" option.
class CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;
  final String allLabel;
  final String title;
  final IconData icon;
  final Map<String, int>? categoryCounts;
  final int? totalCount;

  const CategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    this.allLabel = 'همه',
    this.title = 'دسته‌بندی:',
    this.icon = Icons.category_outlined,
    this.categoryCounts,
    this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty && (totalCount == null || totalCount == 0)) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(width: 8),
          CategoryChip(
            label: allLabel,
            count: totalCount,
            isSelected: selectedCategory == null,
            onTap: () => onCategorySelected(null),
          ),
          const SizedBox(width: 6),
          ...categories.map(
            (cat) => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: CategoryChip(
                label: cat,
                count: categoryCounts?[cat],
                isSelected: selectedCategory == cat,
                onTap: () => onCategorySelected(cat),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Styled category pill chip for filter bars.
class CategoryChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip({
    super.key,
    required this.label,
    this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : AppColors.cardDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.dividerDark,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
              ),
              if (count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    count!.formattedInt,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
