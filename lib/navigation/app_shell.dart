import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/l10n.dart';
import '../core/widgets/app_bottom_nav.dart';

/// Persistent shell for the four primary tabs. Each tab keeps its own
/// navigation stack and scroll position (indexed stack).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = L10n.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        top: false,
        child: AppBottomNav(
          items: [
            BottomNavItem(
              label: l10n.explore,
              icon: Icons.explore_outlined,
              activeIcon: Icons.explore,
            ),
            BottomNavItem(
              label: l10n.favorites,
              icon: Icons.favorite_border,
              activeIcon: Icons.favorite,
            ),
            BottomNavItem(
              label: l10n.myOrders,
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
            ),
            BottomNavItem(
              label: l10n.account,
              icon: Icons.person_outline,
              activeIcon: Icons.person,
            ),
          ],
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
