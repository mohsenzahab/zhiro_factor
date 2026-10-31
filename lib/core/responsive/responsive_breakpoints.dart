import 'package:flutter/material.dart';

/// Screen type categorization for responsive layouts.
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

/// Central definition of responsive breakpoints and layout utilities.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Maximum width for mobile devices (phones).
  static const double mobileMax = 650;

  /// Maximum width for tablets / small laptops.
  static const double tabletMax = 1024;

  /// Determine screen type from width.
  static ScreenType fromWidth(double width) {
    if (width < mobileMax) return ScreenType.mobile;
    if (width < tabletMax) return ScreenType.tablet;
    return ScreenType.desktop;
  }
}

/// Convenience extensions on [BuildContext] for responsive checks and values.
extension ResponsiveContext on BuildContext {
  /// Screen size of current context.
  Size get screenSize => MediaQuery.sizeOf(this);

  /// Width of current screen.
  double get screenWidth => screenSize.width;

  /// Height of current screen.
  double get screenHeight => screenSize.height;

  /// Current [ScreenType].
  ScreenType get screenType => ResponsiveBreakpoints.fromWidth(screenWidth);

  /// True if current device is mobile width (< 650px).
  bool get isMobile => screenType == ScreenType.mobile;

  /// True if current device is tablet width (650px - 1024px).
  bool get isTablet => screenType == ScreenType.tablet;

  /// True if current device is desktop width (>= 1024px).
  bool get isDesktop => screenType == ScreenType.desktop;

  /// True if device is handheld (mobile or tablet).
  bool get isHandheld => isMobile || isTablet;

  /// Return a responsive value depending on current screen type.
  T responsiveValue<T>({
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    switch (screenType) {
      case ScreenType.mobile:
        return mobile;
      case ScreenType.tablet:
        return tablet ?? mobile;
      case ScreenType.desktop:
        return desktop;
    }
  }

  /// Responsive page padding (16 on mobile, 20 on tablet, 24 on desktop).
  EdgeInsets get responsivePagePadding => EdgeInsets.all(
        responsiveValue<double>(mobile: 14, tablet: 18, desktop: 24),
      );
}

/// Declarative widget builder based on current [ScreenType].
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenType screenType) builder;

  const ResponsiveBuilder({
    super.key,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = ResponsiveBreakpoints.fromWidth(constraints.maxWidth);
        return builder(context, screenType);
      },
    );
  }
}

