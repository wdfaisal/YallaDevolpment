import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/price_text.dart';
import '../../data/models/catalog.dart';

/// Two-column best-seller card used on the home screen.
class BestSellerCard extends StatelessWidget {
  const BestSellerCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAdd,
    this.showShadow = true,
  });

  final CatalogMenuItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  /// The home screen uses a flat surface, so it disables the card shadow.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final badge = item.badge(l10n.isArabic);
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    url: item.imageUrl,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  PositionedDirectional(
                    bottom: 8,
                    end: 8,
                    child: _AddButton(
                      enabled: item.available,
                      onTap: onAdd,
                      outlined: true,
                      size: 36,
                      showShadow: showShadow,
                    ),
                  ),
                  if (!item.available)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.itemUnavailable,
                          style: AppTypography.labelMd.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              item.name,
              style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              item.restaurantName,
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  Fmt.money(item.priceMinor, currency: l10n.currencyDefault),
                  style: AppTypography.headlineSm.copyWith(
                    fontSize: 18,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (badge != null && badge.isNotEmpty) ...[
                  const Spacer(),
                  Flexible(
                    child: Text(
                      badge,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal menu row (96px thumbnail) used in restaurant menus and results.
class MenuItemRow extends StatelessWidget {
  const MenuItemRow({
    super.key,
    required this.item,
    required this.onTap,
    required this.onAdd,
    this.showFavorite = false,
  });

  final CatalogMenuItem item;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final bool showFavorite;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: AppColors.cardShadow,
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
                    url: item.imageUrl,
                    width: 96,
                    height: 96,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  if (!item.available)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.outOfStock,
                          style: AppTypography.labelSm.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  if (showFavorite)
                    PositionedDirectional(
                      bottom: 4,
                      start: 4,
                      child: FavoriteButton(
                        targetType: 'menu_item',
                        targetId: item.id,
                        size: 28,
                        background: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
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
                    style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (item.calories != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.calories} kcal',
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(child: PriceText(priceMinor: item.priceMinor, size: PriceSize.sm)),
                      _AddButton(enabled: item.available, onTap: onAdd),
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

/// Wide promotional card (320px) used by the home offers strip.
class OfferCard extends StatelessWidget {
  const OfferCard({
    super.key,
    required this.offer,
    required this.onTap,
    this.width = 320,
  });

  final CatalogOffer offer;
  final VoidCallback onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final isArabic = l10n.isArabic;
    final discountLabel = offer.discountType == 'percentage'
        ? '${offer.discountValue}%'
        : Fmt.money(offer.discountValue);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: 150,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(url: offer.imageUrl, borderRadius: BorderRadius.zero),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: AlignmentDirectional.centerStart,
                    end: AlignmentDirectional.centerEnd,
                    colors: [Color(0xE6FF591B), Color(0x66AD3300)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      child: Text(
                        '$discountLabel ${l10n.offers}',
                        style: AppTypography.labelSm.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      offer.title(isArabic),
                      style: AppTypography.headlineSm.copyWith(color: Colors.white),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      offer.restaurantName,
                      style: AppTypography.bodySm.copyWith(color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({
    required this.enabled,
    required this.onTap,
    this.outlined = false,
    this.size = 32,
    this.showShadow = true,
  });

  final bool enabled;
  final VoidCallback onTap;
  final bool outlined;
  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final filled = !outlined;
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: !enabled
                ? AppColors.surfaceContainerHigh
                : (filled ? AppColors.primary : AppColors.surfaceContainerLowest),
            shape: BoxShape.circle,
            border: outlined && enabled
                ? Border.all(color: AppColors.primary, width: 2)
                : null,
            boxShadow: outlined && enabled && showShadow ? AppColors.cardShadow : null,
          ),
          child: Icon(
            Icons.add,
            size: 20,
            color: !enabled
                ? AppColors.secondary
                : (filled ? AppColors.onPrimary : AppColors.primary),
          ),
        ),
      ),
    );
  }
}
