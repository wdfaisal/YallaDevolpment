import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../../data/models/catalog.dart';
import '../../shared/card_cta.dart';
import '../../shared/restaurant_widgets.dart';

/// One saved restaurant in the Favorites list. It keeps the same flat geometry
/// as the order cards: white surface, hairline border, a meta row built from
/// backend fields only, and one compact outlined action.
class FavoriteRestaurantCard extends StatelessWidget {
  const FavoriteRestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.onOpenMenu,
  });

  final CatalogRestaurant restaurant;
  final VoidCallback onTap;
  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final fee = restaurantFeeLabel(restaurant, l10n);

    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppSpacing.lg,
            AppSpacing.md + 2,
            AppSpacing.md,
            AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: Stack(
                      children: [
                        AppImage(
                          url: restaurant.bannerUrl ?? restaurant.logoUrl,
                          width: 64,
                          height: 64,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          icon: Icons.storefront_outlined,
                        ),
                        PositionedDirectional(
                          bottom: 4,
                          start: 4,
                          child: FavoriteButton(
                            targetType: 'restaurant',
                            targetId: restaurant.id,
                            size: 24,
                            background: AppColors.surfaceContainerLowest
                                .withValues(alpha: 0.92),
                            borderColor: AppColors.borderHairline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                restaurant.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelLg.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            RatingBadge(
                              rating: restaurant.rating,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          restaurantCuisine(restaurant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _Meta(
                              icon: Icons.schedule,
                              label: restaurantEtaLabel(restaurant, l10n),
                              color: AppColors.primary,
                            ),
                            if (restaurant.distanceKm != null)
                              _Meta(
                                icon: Icons.near_me_outlined,
                                label: Fmt.distance(restaurant.distanceKm),
                              ),
                            if (fee != null)
                              _Meta(
                                icon: Icons.delivery_dining,
                                label: fee,
                                color: restaurant.deliveryFeeMinor == 0
                                    ? AppColors.tertiary
                                    : AppColors.secondary,
                                bold: restaurant.deliveryFeeMinor == 0,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Container(height: 1, color: AppColors.borderHairline),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _OpenTag(open: restaurant.isOpen),
                  const Spacer(),
                  CardCta(
                    label: l10n.menu,
                    icon: Icons.restaurant_menu,
                    highlighted: true,
                    onTap: onOpenMenu,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    this.color = AppColors.secondary,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.labelMd.copyWith(
            fontSize: 11,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Backend-driven open/closed indicator. It never guesses the status locally.
class _OpenTag extends StatelessWidget {
  const _OpenTag({required this.open});

  final bool open;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final color = open ? AppColors.tertiary : AppColors.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs + 2),
        Text(
          open ? l10n.openNow : l10n.closed,
          style: AppTypography.labelMd.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
