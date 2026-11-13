import 'package:flutter/material.dart';

/// Yalla Talabat "Pure Orange" design tokens.
/// Source of truth: docs/DESIGN_coustmer_app.md.
class AppColors {
  const AppColors._();

  static const Color surface = Color(0xFFF9F9F9);
  static const Color surfaceDim = Color(0xFFDADADA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F3F4);
  static const Color surfaceContainer = Color(0xFFEEEEEE);
  static const Color surfaceContainerHigh = Color(0xFFE8E8E8);
  static const Color surfaceContainerHighest = Color(0xFFE2E2E2);

  static const Color onSurface = Color(0xFF1A1C1C);
  static const Color onSurfaceVariant = Color(0xFF5B4038);
  static const Color inverseSurface = Color(0xFF2F3131);
  static const Color inverseOnSurface = Color(0xFFF0F1F1);

  static const Color outline = Color(0xFF907066);
  static const Color outlineVariant = Color(0xFFE4BEB3);

  static const Color primary = Color(0xFFAD3300);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFFF591B);
  static const Color onPrimaryContainer = Color(0xFF531400);
  static const Color inversePrimary = Color(0xFFFFB59E);
  static const Color primaryFixed = Color(0xFFFFDBD0);
  static const Color primaryFixedDim = Color(0xFFFFB59E);

  static const Color secondary = Color(0xFF5B5F63);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFDDE0E5);
  static const Color onSecondaryContainer = Color(0xFF5F6368);

  static const Color tertiary = Color(0xFF006C4A);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFF00A673);
  static const Color onTertiaryContainer = Color(0xFF003220);

  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  static const Color background = Color(0xFFF9F9F9);
  static const Color onBackground = Color(0xFF1A1C1C);

  static const Color orangeTintSubtle = Color(0xFFFFF2EC);
  static const Color orangeTintSoft = Color(0xFFFFE8DD);
  static const Color orangeContainerActive = Color(0xFFFFDBD0);
  static const Color borderSubtle = Color(0xFFF1F4F9);
  static const Color borderMuted = Color(0xFFE4BEB3);
  static const Color textMuted = Color(0xFF5B4038);

  /// Warm home service tiles from the Stitch home specification.
  static const Color serviceTile = Color(0xFFF7EFE5);
  static const Color serviceTileBorder = Color(0xFFF0E6D8);

  static const Color success = Color(0xFF00A673);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFBA1A1A);

  /// Level 1 card shadow (warm, low opacity).
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color(0x0DFF591B),
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x08181C20),
      blurRadius: 3,
      offset: Offset(0, 1),
    ),
  ];

  /// Level 2 floating shadow.
  static const List<BoxShadow> floatingShadow = [
    BoxShadow(
      color: Color(0x1AFF591B),
      blurRadius: 24,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A181C20),
      blurRadius: 6,
      offset: Offset(0, 2),
    ),
  ];

  /// Level 3 modal / persistent navigation shadow.
  static const List<BoxShadow> sheetShadow = [
    BoxShadow(
      color: Color(0x0F181C20),
      blurRadius: 24,
      offset: Offset(0, -4),
    ),
  ];
}
