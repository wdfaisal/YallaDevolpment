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
import '../../shared/restaurant_widgets.dart';
import 'home_section_header.dart';

/// Horizontal strip of 320px restaurant offer cards, matching the Stitch home
/// design. Items come from the backend offer payload; nothing is invented.
class HomeOffers extends StatelessWidget {
  const HomeOffers({
    super.key,
    required this.offers,
    required this.restaurants,
    required this.onRestaurantTap,
    required this.onItemTap,
  });

  final List<CatalogOffer> offers;
  final Map<String, CatalogRestaurant> restaurants;
  final ValueChanged<String> onRestaurantTap;
  final void Function(CatalogOffer offer, CatalogOfferItem item) onItemTap;

  @override
  Widget build(BuildContext context) {
    if (offers.isEmpty) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    final hours = _hoursUntilEarliestEnd();
    // Slightly wider than the original 320px card so an offer's two product
    // cards sit side by side comfortably, while the next offer still peeks in.
    final available = MediaQuery.sizeOf(context).width - (AppSpacing.lg * 2);
    final cardWidth = available.clamp(300.0, 360.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: l10n.exclusiveOffers,
          trailing: hours == null ? null : _TimerPill(label: l10n.endsInHours(hours)),
        ),
        // The design uses gap-3 between the section heading and the strip.
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < offers.length; index++) ...[
                if (index > 0) const SizedBox(width: AppSpacing.lg),
                HomeOfferCard(
                  width: cardWidth,
                  offer: offers[index],
                  restaurant: restaurants[offers[index].restaurantId],
                  onTap: () => onRestaurantTap(offers[index].restaurantId),
                  onItemTap: (item) => onItemTap(offers[index], item),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  int? _hoursUntilEarliestEnd() {
    final now = DateTime.now();
    DateTime? earliest;
    for (final offer in offers) {
      final parsed = DateTime.tryParse(offer.endsAt);
      if (parsed == null || !parsed.isAfter(now)) continue;
      if (earliest == null || parsed.isBefore(earliest)) earliest = parsed;
    }
    if (earliest == null) return null;
    final minutes = earliest.difference(now).inMinutes;
    return (minutes / 60).ceil().clamp(1, 999);
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.orangeTintSubtle,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.borderMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelMd.copyWith(
              fontSize: 12,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Offer card: restaurant header plus a single row of discounted products.
class HomeOfferCard extends StatelessWidget {
  const HomeOfferCard({
    super.key,
    required this.offer,
    required this.restaurant,
    required this.onTap,
    required this.onItemTap,
    this.width = 320,
  });

  final CatalogOffer offer;
  final CatalogRestaurant? restaurant;
  final VoidCallback onTap;
  final ValueChanged<CatalogOfferItem> onItemTap;
  final double width;

  static const double _padding = 14;

  /// Height of the product strip. Fixed so extra products scroll horizontally
  /// instead of wrapping and making the card taller.
  static const double _itemRowHeight = 148;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = l10n.isArabic;
    final columns = offer.items.length >= 3 ? 3 : 2;
    final visibleColumns = offer.items.isEmpty
        ? 1
        : (offer.items.length < columns ? offer.items.length : columns);
    final innerWidth = width - (_padding * 2);
    final itemWidth =
        (innerWidth - (AppSpacing.sm * (visibleColumns - 1))) / visibleColumns;
    final discountValue = offer.discountType == 'percentage'
        ? '${offer.discountValue}%'
        : Fmt.money(offer.discountValue, currency: l10n.currencyDefault);
    final description = restaurant == null
        ? offer.description(isArabic)
        : _description(restaurant!, offer, isArabic);

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceContainer),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _OfferHeader(
              offer: offer,
              restaurant: restaurant,
              description: description,
              discountLabel: l10n.discountBadge(discountValue),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(height: 1, color: AppColors.surfaceContainer),
            const SizedBox(height: 10),
            if (columns == 3) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.featuredDiscounts,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.discountedItems(offer.items.length),
                    style: AppTypography.labelSm.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            // One row only: the discounted products always sit side by side.
            // Any extra products scroll horizontally instead of wrapping onto a
            // second line (which used to make the card taller).
            if (offer.items.isNotEmpty)
              SizedBox(
                height: _itemRowHeight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var index = 0; index < offer.items.length; index++) ...[
                        if (index > 0) const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: itemWidth,
                          child: _OfferItemCard(
                            item: offer.items[index],
                            columns: columns,
                            onTap: () => onItemTap(offer.items[index]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _description(
    CatalogRestaurant restaurant,
    CatalogOffer offer,
    bool isArabic,
  ) {
    final cuisine = restaurantCuisine(restaurant);
    if (cuisine.isNotEmpty) return cuisine;
    return offer.description(isArabic);
  }
}

class _OfferHeader extends StatelessWidget {
  const _OfferHeader({
    required this.offer,
    required this.restaurant,
    required this.description,
    required this.discountLabel,
  });

  final CatalogOffer offer;
  final CatalogRestaurant? restaurant;
  final String description;
  final String discountLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final restaurant = this.restaurant;
    final name = restaurant?.name ?? offer.restaurantName;
    final logo = restaurant?.logoUrl ?? offer.imageUrl;
    final fee = restaurant?.deliveryFeeMinor;
    final feeLabel = fee == null
        ? null
        : fee == 0
            ? l10n.freeDelivery
            : '${l10n.delivery} ${Fmt.money(fee, currency: l10n.currencyDefault)}';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64,
          height: 64,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceContainer),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            child: AppImage(
              url: logo,
              width: 60,
              height: 60,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headlineSm.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(AppSpacing.radius),
                          ),
                          child: Text(
                            discountLabel,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.onPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  FavoriteButton(
                    targetType: 'restaurant',
                    targetId: offer.restaurantId,
                    size: 28,
                    background: AppColors.surfaceContainerLow,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (description.isNotEmpty)
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySm.copyWith(
                    fontSize: 11,
                    color: AppColors.secondary,
                  ),
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (restaurant != null)
                    RatingBadge(rating: restaurant.rating, compact: true),
                  if (restaurant != null)
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
    );
  }
}

class _OfferItemCard extends StatelessWidget {
  const _OfferItemCard({
    required this.item,
    required this.columns,
    required this.onTap,
  });

  final CatalogOfferItem item;
  final int columns;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = l10n.isArabic;
    final threeColumns = columns == 3;
    final current = item.offerPriceMinor > 0 ? item.offerPriceMinor : item.priceMinor;
    final hasDiscount = current < item.priceMinor;
    final currentText = Text(
      Fmt.money(current, currency: l10n.currencyDefault),
      style: AppTypography.headlineSm.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.primary,
      ),
    );
    final oldText = Text(
      Fmt.money(item.priceMinor, currency: l10n.currencyDefault),
      style: AppTypography.bodySm.copyWith(
        fontSize: 10,
        color: AppColors.secondary,
        decoration: TextDecoration.lineThrough,
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: threeColumns
              ? AppColors.surfaceContainerLow.withValues(alpha: 0.5)
              : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.surfaceContainer),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  child: AppImage(
                    url: item.imageUrl,
                    width: double.infinity,
                    height: 80,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                ),
                PositionedDirectional(
                  bottom: 4,
                  end: 4,
                  child: _ItemAddButton(filled: threeColumns, onTap: onTap),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // The strip has a fixed height, so the text block takes whatever
            // remains and never makes the card taller.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      item.displayName(isArabic),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSm.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    width: double.infinity,
                    height: 18,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: threeColumns
                          ? AlignmentDirectional.centerStart
                          : AlignmentDirectional.centerEnd,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: threeColumns
                            ? [
                                currentText,
                                if (hasDiscount) ...[const SizedBox(width: 4), oldText],
                              ]
                            : [
                                if (hasDiscount) ...[oldText, const SizedBox(width: 4)],
                                currentText,
                              ],
                      ),
                    ),
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

class _ItemAddButton extends StatelessWidget {
  const _ItemAddButton({required this.filled, required this.onTap});

  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : AppColors.surfaceContainerLowest,
            shape: BoxShape.circle,
            border: filled ? null : Border.all(color: AppColors.primary),
          ),
          child: Icon(
            Icons.add,
            size: 16,
            color: filled ? AppColors.onPrimary : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
