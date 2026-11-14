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

/// Restaurant summary for the checkout page: logo, name, live open status,
/// ETA/rating from the catalog API and a shortcut back to the menu.
class CheckoutRestaurantCard extends StatelessWidget {
  const CheckoutRestaurantCard({
    super.key,
    required this.cart,
    required this.detail,
    required this.l10n,
    this.onMenuTap,
  });

  final CartResponse cart;
  final CatalogRestaurantDetail? detail;
  final L10n l10n;
  final VoidCallback? onMenuTap;

  @override
  Widget build(BuildContext context) {
    final restaurant = detail?.restaurant;
    final name = restaurant?.name ?? cart.restaurantName ?? '—';
    final eta = restaurant == null
        ? null
        : (restaurant.etaMinutes ?? restaurant.prepMinutes);
    final etaLabel = eta != null && eta > 0 ? '$eta ${l10n.minutesLong}' : null;
    final ratingLabel = restaurant == null || restaurant.rating <= 0
        ? null
        : restaurant.ratingCount > 0
            ? '${Fmt.rating(restaurant.rating)} '
                '(${l10n.ratingCountLabel(restaurant.ratingCount)})'
            : Fmt.rating(restaurant.rating);
    final showEta = etaLabel != null;
    final showRating = ratingLabel != null;

    return CheckoutSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AppImage(
            url: restaurant?.logoUrl,
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            backgroundColor: AppColors.surfaceContainer,
            icon: Icons.lunch_dining,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restaurant != null) ...[
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
                        width: 6,
                        height: 6,
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
                ],
                Text(
                  name,
                  style: AppTypography.headlineSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showEta || showRating) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      if (showEta) ...[
                        const Icon(
                          Icons.schedule,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            etaLabel,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      if (showEta && showRating)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: Text(
                            '•',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ),
                      if (showRating) ...[
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.tertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            ratingLabel,
                            style: AppTypography.labelMd.copyWith(
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
          if (onMenuTap != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: l10n.menu,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Material(
                  color: AppColors.surfaceContainerLow,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: onMenuTap,
                    child: const Icon(
                      Icons.restaurant_menu,
                      size: 20,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
