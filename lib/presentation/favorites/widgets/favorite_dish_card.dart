import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/favorite_button.dart';
import '../../../core/widgets/price_text.dart';
import '../../../data/models/catalog.dart';
import '../../shared/card_cta.dart';

/// One saved dish in the Favorites list, styled like the order cards: flat
/// white surface, hairline border, real menu data and one outlined action.
class FavoriteDishCard extends StatelessWidget {
  const FavoriteDishCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onView,
  });

  final CatalogMenuItem item;
  final VoidCallback onTap;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);

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
                          url: item.imageUrls.isEmpty
                              ? null
                              : item.imageUrls.first,
                          width: 64,
                          height: 64,
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd),
                          icon: Icons.restaurant_menu,
                        ),
                        PositionedDirectional(
                          bottom: 4,
                          start: 4,
                          child: FavoriteButton(
                            targetType: 'menu_item',
                            targetId: item.id,
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
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelLg.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (item.restaurantName.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_outlined,
                                size: 12,
                                color: AppColors.onSurfaceVariant,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  item.restaurantName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.labelMd.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        PriceText(
                          priceMinor: item.offerPriceMinor ?? item.priceMinor,
                          compareAtMinor: item.offerPriceMinor == null
                              ? null
                              : item.priceMinor,
                          currency: l10n.currencyDefault,
                          size: PriceSize.sm,
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
                  if (!item.available)
                    Text(
                      l10n.outOfStock,
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.error,
                      ),
                    )
                  else if (item.prepMinutes > 0) ...[
                    const Icon(
                      Icons.schedule,
                      size: 13,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      '${item.prepMinutes} ${l10n.minutesLong}',
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  CardCta(
                    label: l10n.viewDish,
                    icon: Icons.restaurant_menu,
                    onTap: onView,
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
