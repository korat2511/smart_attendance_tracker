import 'package:flutter/material.dart';

/// Breakpoints and responsive helpers (mobile, tablet, desktop).
abstract class ResponsiveUtils {
  ResponsiveUtils._();

  /// Breakpoints (logical pixels width)
  static const double breakpointMobile = 600;
  static const double breakpointTablet = 900;
  static const double breakpointDesktop = 1200;

  /// Whether current context is considered mobile (< 600).
  static bool isMobile(BuildContext context) {
    return MediaQuery.sizeOf(context).width < breakpointMobile;
  }

  /// Whether current context is tablet or larger (>= 600).
  static bool isTabletOrLarger(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= breakpointTablet;
  }

  /// Whether current context is desktop (>= 1200).
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= breakpointDesktop;
  }

  /// Screen width.
  static double width(BuildContext context) => MediaQuery.sizeOf(context).width;

  /// Screen height.
  static double height(BuildContext context) => MediaQuery.sizeOf(context).height;

  /// Padding / spacing that scales with screen (e.g. horizontal padding).
  static double horizontalPadding(BuildContext context) {
    final w = width(context);
    if (w >= breakpointDesktop) return 48;
    if (w >= breakpointTablet) return 32;
    if (w >= breakpointMobile) return 24;
    return 16;
  }

  /// Safe padding from [MediaQueryData.padding] (notch, status bar).
  static EdgeInsets padding(BuildContext context) {
    return MediaQuery.paddingOf(context);
  }

  /// View insets (keyboard, etc.)
  static EdgeInsets viewInsets(BuildContext context) {
    return MediaQuery.viewInsetsOf(context);
  }

  /// Select value by screen size: [mobile], [tablet], [desktop].
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final w = width(context);
    if (w >= breakpointDesktop && desktop != null) return desktop;
    if (w >= breakpointTablet && tablet != null) return tablet;
    return mobile;
  }

  /// Max content width for large screens (e.g. 800 for forms).
  static const double maxContentWidth = 800;

  /// Constrained width for centered content.
  static double constrainedWidth(BuildContext context) {
    return width(context).clamp(0, maxContentWidth);
  }
}
