/// 4/8pt spacing grid shared by every screen.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  static const double gutter = 16;
  static const double gutterSm = 12;
  static const double margin = 16;
  static const double marginLg = 24;

  static const double radiusSm = 4;
  static const double radius = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusPill = 999;

  /// Minimum accessible tap target.
  static const double minTapTarget = 44;
}

/// Responsive breakpoints from the design system.
class AppBreakpoints {
  const AppBreakpoints._();

  static const double tablet = 640;
  static const double desktop = 1024;

  static bool isTablet(double width) => width >= tablet && width < desktop;
  static bool isDesktop(double width) => width >= desktop;

  /// Horizontal page padding: fluid margins on mobile, generous on wide
  /// screens, with content capped for readability.
  static double pagePadding(double width) {
    if (width >= desktop) return 24;
    if (width >= tablet) return 24;
    return 16;
  }

  static double maxContentWidth(double width) {
    if (width >= desktop) return 1200;
    return width;
  }
}
