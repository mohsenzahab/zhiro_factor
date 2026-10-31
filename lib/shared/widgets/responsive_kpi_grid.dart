import 'package:flutter/material.dart';

/// Responsive grid for KPI cards and stat boxes.
/// Automatically adjusts column counts from 4 columns on large screens
/// down to 2 columns on tablets and 1 column on compact mobile screens.
class ResponsiveKpiGrid extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final double minItemWidth;

  const ResponsiveKpiGrid({
    super.key,
    required this.children,
    this.spacing = 12,
    this.runSpacing = 12,
    this.minItemWidth = 220,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        // Calculate columns based on width and minimum item width
        int columns = (availableWidth / minItemWidth).floor();
        if (columns < 1) columns = 1;
        if (columns > children.length) columns = children.length;

        // Spread evenly across the available width
        final itemWidth = (availableWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children.map((child) {
            return SizedBox(
              width: itemWidth,
              child: child,
            );
          }).toList(),
        );
      },
    );
  }
}

