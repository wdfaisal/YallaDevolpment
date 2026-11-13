import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/rating_badge.dart';
import '../../data/models/catalog.dart';

String restaurantEtaLabel(CatalogRestaurant restaurant, L10n l10n) {
  final minutes = restaurant.etaMinutes ?? restaurant.prepMinutes;
  if (minutes <= 0) return '—';
  return '$minutes ${l10n.minutesLong}';
}

String? restaurantFeeLabel(CatalogRestaurant restaurant, L10n l10n) {
  final fee = restaurant.deliveryFeeMinor;
  if (fee == null) return null;
  if (fee == 0) return l10n.freeDelivery;
  return '${l10n.delivery}: ${Fmt.money(fee, currency: l10n.currencyDefault)}';
}

String restaurantCuisine(CatalogRestaurant restaurant) {
  if (restaurant.cuisine.isNotEmpty) return restaurant.cuisine;
  return restaurant.categories.join(' • ');
}

class OfferBadge extends StatelessWidget {
  const OfferBadge({super.key, required this.count, this.onDark = false});

  final int count;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: onDark ? AppColors.primaryContainer : AppColors.primary,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 10, color: AppColors.onPrimary),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: AppTypography.labelSm.copyWith(
              color: AppColors.onPrimary,
              fontSize: 9,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal restaurant card (112px thumbnail) used by the list stream.
class RestaurantListCard extends StatelessWidget {
  const RestaurantListCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.showFavorite = true,
    this.showShadow = true,
  });

  final CatalogRestaurant restaurant;
  final VoidCallback onTap;
  final bool showFavorite;

  /// The all-restaurants screen uses a flat, shadow-free surface.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final fee = restaurantFeeLabel(restaurant, l10n);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: showShadow ? AppColors.cardShadow : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              height: 112,
              child: Stack(
                children: [
                  AppImage(
                    url: restaurant.bannerUrl ?? restaurant.logoUrl,
                    width: 112,
                    height: 112,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  if (restaurant.offerCount > 0)
                    PositionedDirectional(
                      top: 6,
                      end: 6,
                      child: OfferBadge(count: restaurant.offerCount),
                    ),
                  if (showFavorite)
                    PositionedDirectional(
                      bottom: 6,
                      start: 6,
                      child: FavoriteButton(
                        targetType: 'restaurant',
                        targetId: restaurant.id,
                        size: 30,
                        background: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                      ),
                    ),
                  if (!restaurant.isOpen)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        alignment: Alignment.center,
                        child: StatusPill(label: l10n.closed, isOpen: false),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: AppTypography.headlineSm.copyWith(fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              restaurantCuisine(restaurant),
                              style: AppTypography.bodySm.copyWith(
                                color: AppColors.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      RatingBadge(rating: restaurant.rating),
                    ],
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
                  const SizedBox(height: 4),
                  if (restaurant.minOrderMinor != null)
                    Text(
                      '${l10n.minimumOrder}: ${Fmt.money(restaurant.minOrderMinor!)}',
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-column grid card used by the home nearby section and grid mode.
class RestaurantGridCard extends StatelessWidget {
  const RestaurantGridCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.showShadow = true,
  });

  final CatalogRestaurant restaurant;
  final VoidCallback onTap;

  /// The home screen uses a flat surface, so it disables the card shadow.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: showShadow ? AppColors.cardShadow : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    url: restaurant.bannerUrl ?? restaurant.logoUrl,
                    borderRadius: BorderRadius.zero,
                  ),
                  if (restaurant.offerCount > 0)
                    PositionedDirectional(
                      top: 8,
                      end: 8,
                      child: OfferBadge(count: restaurant.offerCount),
                    ),
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: FavoriteButton(
                      targetType: 'restaurant',
                      targetId: restaurant.id,
                      size: 30,
                      background: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
                    ),
                  ),
                  if (!restaurant.isOpen)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.35),
                        alignment: Alignment.center,
                        child: StatusPill(label: l10n.closed, isOpen: false),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    restaurantCuisine(restaurant),
                    style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      RatingBadge(rating: restaurant.rating, compact: true),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                restaurantEtaLabel(restaurant, l10n),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact horizontal row (96px image) used in "near you".
class RestaurantNearbyTile extends StatelessWidget {
  const RestaurantNearbyTile({
    super.key,
    required this.restaurant,
    required this.onTap,
    this.showShadow = true,
  });

  final CatalogRestaurant restaurant;
  final VoidCallback onTap;

  /// The home screen uses a flat surface, so it disables the card shadow.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final fee = restaurant.deliveryFeeMinor;
    final feeLabel = restaurantFeeLabel(restaurant, l10n);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceContainer),
          boxShadow: showShadow ? AppColors.cardShadow : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                children: [
                  AppImage(
                    url: restaurant.bannerUrl ?? restaurant.logoUrl,
                    width: 96,
                    height: 96,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  PositionedDirectional(
                    top: 6,
                    start: 6,
                    child: StatusPill(
                      label: restaurant.isOpen ? l10n.open : l10n.closed,
                      isOpen: restaurant.isOpen,
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              restaurant.name,
                              style: AppTypography.headlineSm.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              restaurantCuisine(restaurant),
                              style: AppTypography.bodySm.copyWith(
                                fontSize: 11,
                                color: AppColors.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      FavoriteButton(
                        targetType: 'restaurant',
                        targetId: restaurant.id,
                        size: 28,
                        background: AppColors.surfaceContainerLow,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      RatingBadge(
                        rating: restaurant.rating,
                        count: restaurant.ratingCount,
                        compact: true,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.delivery_dining,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            restaurantEtaLabel(restaurant, l10n),
                            style: AppTypography.bodySm.copyWith(
                              fontSize: 11,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                      if (feeLabel != null)
                        Text(
                          feeLabel,
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 11,
                            color: fee == 0 ? AppColors.tertiary : AppColors.secondary,
                            fontWeight: fee == 0 ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square brand tile used by the "top brands" strip.
class RestaurantBrandTile extends StatelessWidget {
  const RestaurantBrandTile({
    super.key,
    required this.restaurant,
    required this.onTap,
  });

  final CatalogRestaurant restaurant;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AppImage(
                  url: restaurant.logoUrl ?? restaurant.bannerUrl,
                  width: 68,
                  height: 68,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  icon: Icons.restaurant,
                ),
                if (restaurant.offerCount > 0)
                  PositionedDirectional(
                    top: -4,
                    end: -2,
                    child: OfferBadge(count: restaurant.offerCount),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              restaurant.name,
              style: AppTypography.labelSm.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              restaurantEtaLabel(restaurant, l10n),
              style: AppTypography.labelSm.copyWith(
                color: AppColors.secondary,
                fontSize: 9,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    this.color,
    this.bold = false,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.secondary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: tint),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTypography.labelSm.copyWith(
            color: tint,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}


