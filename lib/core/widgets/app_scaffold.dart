import 'package:flutter/material.dart';

import '../design/app_colors.dart';

/// Standard page shell that owns safe-area handling so no screen invents its
/// own padding. Screens that need a custom header pass [header] instead of
/// relying on a Material [AppBar].
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
  });

  final Widget body;
  final Widget? header;
  final Widget? bottomBar;
  final Color? background;
  final bool resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context) {
    Widget content = SafeArea(
      top: header == null,
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
    return Scaffold(
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
    );
  }
}
