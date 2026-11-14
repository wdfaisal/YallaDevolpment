import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Single source of truth for the system status/navigation bars.
///
/// The app is always light and edge-to-edge, so every page paints its own
/// background under the status bar. Pages with a light surface use [light];
/// pages that draw a dark image under the notch use [overDark] so the clock and
/// battery icons stay readable.
class AppSystemUi {
  const AppSystemUi._();

  static const SystemUiOverlayStyle light = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  static const SystemUiOverlayStyle overDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );
}
