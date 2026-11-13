import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/catalog.dart';
import '../../shared/restaurant_widgets.dart';

/// White meta card that overlaps the hero by 32px. Flat surface: a hairline
/// border replaces the shadow from the original Stitch mock.
class RestaurantMetaCard extends StatelessWidget {
  const RestaurantMetaCard({
    super.key,
    required this.detail,
    required this.l10n,
    this.onOffersTap,
  });

  final CatalogRestaurantDetail detail;
  final L10n l10n;
  final VoidCallback? onOffersTap;

  @override
  Widget build(BuildContext context) {
    final restaurant = detail.restaurant;
    final eta = restaurant.etaMinutes ?? restaurant.prepMinutes;
    final fee = detail.deliveryFeeMinor;
    final pills = <Widget>[
      if (eta > 0 && eta <= 30)
        _FeaturePill(
          icon: Icons.bolt,
          label: l10n.fastDelivery,
          color: AppColors.tertiary,
          background: AppColors.tertiaryContainer.withValues(alpha: 0.15),
        ),
      if (fee == 0)
        _FeaturePill(
          icon: Icons.delivery_dining,
          label: l10n.freeDelivery,
          color: AppColors.onSurface,
          background: AppColors.surfaceContainer,
        ),
      if (detail.offers.isNotEmpty)
        _FeaturePill(
          icon: Icons.local_offer,
          label: l10n.exclusiveYallaOffers,
          color: AppColors.onPrimaryFixedVariant,
          background: AppColors.primaryFixed.withValues(alpha: 0.5),
          onTap: onOffersTap,
        ),
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
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
                      style: AppTypography.headlineLgMobile,
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
              const SizedBox(width: AppSpacing.md),
              AppImage(
                url: restaurant.logoUrl,
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                backgroundColor:
                    AppColors.primaryContainer.withValues(alpha: 0.1),
                icon: Icons.lunch_dining,
              ),
            ],
          ),
          if (pills.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 26,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < pills.length; index++) ...[
                      if (index > 0) const SizedBox(width: AppSpacing.sm),
                      pills[index],
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: Row(
              children: [
                _Metric(
                  value: Fmt.rating(restaurant.rating),
                  icon: Icons.star,
                  label: restaurant.ratingCount > 0
                      ? l10n.ratingCountLabel(restaurant.ratingCount)
                      : l10n.rating,
                ),
                const SizedBox(width: AppSpacing.sm),
                _Metric(
                  value: eta > 0 ? '$eta' : '—',
                  label: l10n.minutesLong,
                ),
                const SizedBox(width: AppSpacing.sm),
                _Metric(
                  value: fee == null
                      ? '—'
                      : (fee == 0 ? l10n.deliveryFeeFree : Fmt.money(fee)),
                  suffix: fee == null || fee == 0 ? null : l10n.currencyDefault,
                  label: l10n.deliveryFee,
                ),
                const SizedBox(width: AppSpacing.sm),
                _Metric(
                  value: detail.minOrderMinor == null
                      ? '—'
                      : Fmt.money(detail.minOrderMinor!),
                  suffix: detail.minOrderMinor == null
                      ? null
                      : l10n.currencyDefault,
                  label: l10n.minimumOrder,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      onTap: onTap,
      child: pill,
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.value,
    required this.label,
    this.suffix,
    this.icon,
  });

  final String value;
  final String label;
  final String? suffix;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final iconData = icon;
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: AppTypography.labelLg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (suffix != null) ...[
                      const SizedBox(width: 2),
                      Text(
                        suffix!,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (iconData != null) ...[
                const SizedBox(width: 2),
                Icon(iconData, size: 16, color: AppColors.warning),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
