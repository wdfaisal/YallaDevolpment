import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/cart.dart';
import '../../../data/models/catalog.dart';
import 'checkout_section_card.dart';

/// Compact restaurant summary for the checkout page: logo, name, live open
/// status, ETA, distance to the customer and the restaurant rating badge.
class CheckoutRestaurantCard extends StatelessWidget {
  const CheckoutRestaurantCard({
    super.key,
    required this.cart,
    required this.detail,
    required this.l10n,
  });

  final CartResponse cart;
  final CatalogRestaurantDetail? detail;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final restaurant = detail?.restaurant;
    final name = restaurant?.name ?? cart.restaurantName ?? '—';
    final eta = restaurant == null
        ? null
        : (restaurant.etaMinutes ?? restaurant.prepMinutes);
    final etaLabel = eta != null && eta > 0 ? '$eta ${l10n.minutesLong}' : null;
    final distance = restaurant?.distanceKm;
    final distanceLabel =
        distance == null ? null : '${Fmt.number(distance)} ${l10n.km}';
    final rating = restaurant?.rating ?? 0;
    final showEta = etaLabel != null;
    final showDistance = distanceLabel != null;

    return CheckoutSectionCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppImage(
            url: restaurant?.logoUrl,
            width: 48,
            height: 48,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            backgroundColor: AppColors.surfaceContainer,
            icon: Icons.lunch_dining,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restaurant != null)
                  Row(
                    children: [
                      Text(
                        l10n.orderFrom,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: restaurant.isOpen
                              ? AppColors.tertiary
                              : AppColors.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          restaurant.isOpen ? l10n.openForOrders : l10n.closed,
                          style: AppTypography.labelSm.copyWith(
                            color: restaurant.isOpen
                                ? AppColors.tertiary
                                : AppColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                Text(
                  name,
                  style: AppTypography.headlineSm.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showEta || showDistance) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (showEta) ...[
                        const Icon(
                          Icons.schedule,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            etaLabel,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (showEta && showDistance)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            '•',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      if (showDistance) ...[
                        const Icon(
                          Icons.near_me_outlined,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            distanceLabel,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _RatingBadge(rating: rating, l10n: l10n),
        ],
      ),
    );
  }
}

/// Compact rating chip shown where the design had the menu shortcut icon.
class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating, required this.l10n});

  final double rating;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final hasRating = rating > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: hasRating
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, size: 14, color: AppColors.tertiary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  Fmt.rating(rating),
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          : Text(
              l10n.newBadge,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.secondary,
              ),
            ),
    );
  }
}
