import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/app_colors.dart';
import '../design/app_system_ui.dart';

/// Standard page shell that owns safe-area handling so no screen invents its
/// own padding. Screens that need a custom header pass [header] instead of
/// relying on a Material [AppBar].
///
/// The app runs edge-to-edge, so the [Scaffold] background already paints under
/// the status bar. [statusBarStyle] lets a page choose light icons when its top
/// area is a dark image instead of a white surface.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.body,
    this.header,
    this.bottomBar,
    this.background,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.onRefresh,
    this.statusBarStyle = AppSystemUi.light,
    this.extendTop = false,
  });

  final Widget body;
  final Widget? header;
  final Widget? bottomBar;
  final Color? background;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;
  final SystemUiOverlayStyle statusBarStyle;

  /// When true the body paints under the status bar so a full-bleed hero (for
  /// example the tracking map) reaches the notch. The page is then responsible
  /// for keeping its own controls below the system inset.
  final bool extendTop;

  @override
  Widget build(BuildContext context) {
    Widget content = SafeArea(
      top: header == null && !extendTop,
      bottom: bottomBar == null,
      child: body,
    );
    if (onRefresh != null) {
      content = RefreshIndicator(
        onRefresh: onRefresh!,
        color: AppColors.primaryContainer,
        child: content,
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: statusBarStyle,
      child: Scaffold(
        backgroundColor: background ?? AppColors.surfaceContainerLowest,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        floatingActionButton: floatingActionButton,
        body: Column(
          children: [
            if (header != null)
              SafeArea(
                bottom: false,
                child: header!,
              ),
            Expanded(child: content),
          ],
        ),
        bottomNavigationBar: bottomBar == null
            ? null
            : SafeArea(
                top: false,
                child: bottomBar!,
              ),
      ),
    );
  }
}
