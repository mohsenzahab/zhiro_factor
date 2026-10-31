import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Responsive page header combining title, icon, search field, and action buttons.
/// Adapts gracefully from a single desktop row to a structured multi-row layout on mobile.
class ResponsivePageHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? searchField;
  final List<Widget>? actions;
  final Widget? trailing;

  const ResponsivePageHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.searchField,
    this.actions,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 750;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Row 1: Icon + Title + Trailing
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: iconColor ?? AppColors.primary, size: 24),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),

              // Row 2: Search field (full-width on mobile if present)
              if (searchField != null) ...[
                const SizedBox(height: 12),
                searchField!,
              ],

              // Row 3: Action buttons (horizontally scrollable if present)
              if (actions != null && actions!.isNotEmpty) ...[
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!.map(
                      (action) => Padding(
                        padding: const EdgeInsetsDirectional.only(end: 8),
                        child: action,
                      ),
                    ).toList(),
                  ),
                ),
              ],
            ],
          );
        }

        // Desktop & Wide Tablet: Single row with horizontal scrolling if actions exceed available width
        return Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? AppColors.primary, size: 28),
              const SizedBox(width: 12),
            ],
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (searchField != null) ...[
                        searchField!,
                        const SizedBox(width: 8),
                      ],
                      if (actions != null && actions!.isNotEmpty) ...[
                        ...actions!.map(
                          (action) => Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: action,
                          ),
                        ),
                      ],
                      if (trailing != null) ...[
                        const SizedBox(width: 8),
                        trailing!,
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

