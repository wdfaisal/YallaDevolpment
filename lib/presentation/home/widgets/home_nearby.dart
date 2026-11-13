import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/catalog.dart';
import '../../shared/restaurant_widgets.dart';
import 'home_section_header.dart';

/// "Restaurants near you" section with the design's list/grid toggle.
class HomeNearby extends StatelessWidget {
  const HomeNearby({
    super.key,
    required this.restaurants,
    required this.isGrid,
    required this.onToggleGrid,
    required this.onSeeAll,
    required this.onTap,
  });

  final List<CatalogRestaurant> restaurants;
  final bool isGrid;
  final ValueChanged<bool> onToggleGrid;
  final VoidCallback onSeeAll;
  final ValueChanged<CatalogRestaurant> onTap;

  @override
  Widget build(BuildContext context) {
    if (restaurants.isEmpty) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: l10n.restaurantsNearYou,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ViewToggle(
                isGrid: isGrid,
                listTooltip: l10n.viewList,
                gridTooltip: l10n.viewGrid,
                onChanged: onToggleGrid,
              ),
              const SizedBox(width: AppSpacing.sm),
              InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                onTap: onSeeAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    l10n.seeAllCount(restaurants.length),
                    style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        // The design uses gap-2.5 between the section heading and the list.
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: isGrid
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return RestaurantGridCard(
                      restaurant: restaurant,
                      showShadow: false,
                      onTap: () => onTap(restaurant),
                    );
                  },
                )
              : Column(
                  children: [
                    for (var index = 0; index < restaurants.length; index++) ...[
                      if (index > 0) const SizedBox(height: AppSpacing.md),
                      RestaurantNearbyTile(
                        restaurant: restaurants[index],
                        showShadow: false,
                        onTap: () => onTap(restaurants[index]),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({
    required this.isGrid,
    required this.listTooltip,
    required this.gridTooltip,
    required this.onChanged,
  });

  final bool isGrid;
  final String listTooltip;
  final String gridTooltip;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceContainer),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            icon: Icons.view_agenda_outlined,
            tooltip: listTooltip,
            active: !isGrid,
            onTap: () => onChanged(false),
          ),
          _ToggleButton(
            icon: Icons.grid_view,
            tooltip: gridTooltip,
            active: isGrid,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: onTap,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active ? AppColors.primary : AppColors.secondary,
          ),
        ),
      ),
    );
  }
}
