import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

class BottomNavItem {
  const BottomNavItem({required this.label, required this.icon, required this.activeIcon});

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

/// Persistent 4-tab navigation matching the Stitch shell.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.badgeCounts = const {},
  });

  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.surfaceContainer)),
      ),
      child: SizedBox(
        height: 64,
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++)
              Expanded(
                child: _NavButton(
                  item: items[index],
                  active: index == currentIndex,
                  badge: badgeCounts[index] ?? 0,
                  onTap: () => onTap(index),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.active,
    required this.badge,
    required this.onTap,
  });

  final BottomNavItem item;
  final bool active;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.secondary;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(active ? item.activeIcon : item.icon, size: 24, color: color),
                if (badge > 0)
                  PositionedDirectional(
                    top: -4,
                    start: -10,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: AppTypography.labelMd.copyWith(
                color: color,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
