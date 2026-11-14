import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/catalog.dart';

/// Horizontal menu row from the Stitch restaurant design: text + price on the
/// start side and a 96px image on the end side. The add control is outlined and
/// floats over the bottom-right corner of the photo; once the item is in the
/// cart it becomes a white outlined stepper. Flat white card separated by a
/// hairline border instead of a shadow.
class RestaurantMenuItemCard extends StatelessWidget {
  const RestaurantMenuItemCard({
    super.key,
    required this.item,
    required this.l10n,
    required this.quantity,
    required this.onTap,
    required this.onIncrement,
    required this.onDecrement,
    this.busy = false,
    this.enabled = true,
  });

  final CatalogMenuItem item;
  final L10n l10n;
  final int quantity;
  final VoidCallback onTap;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final bool busy;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final canAdd = enabled && item.available && !busy;
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: AppColors.surfaceContainerHigh),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTypography.headlineSm,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.secondary,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    _PriceBlock(item: item, l10n: l10n),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
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
                      backgroundColor: AppColors.surfaceContainerLowest,
                      icon: Icons.fastfood_outlined,
                    ),
                    if (!item.available)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.outOfStock,
                            style: AppTypography.labelSm.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (item.calories != null)
                      PositionedDirectional(
                        top: 4,
                        start: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            l10n.caloriesLabel(item.calories!),
                            style: AppTypography.labelSm.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      bottom: 4,
                      start: 4,
                      child: _MenuQuantityControl(
                        quantity: quantity,
                        canAdd: canAdd,
                        l10n: l10n,
                        onIncrement: onIncrement,
                        onDecrement: onDecrement,
                      ),
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

class _PriceBlock extends StatelessWidget {
  const _PriceBlock({required this.item, required this.l10n});

  final CatalogMenuItem item;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                Fmt.money(item.effectivePriceMinor),
                style: AppTypography.headlineMd.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              l10n.currencyDefault,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        if (item.hasOffer) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Fmt.money(item.priceMinor),
                style: AppTypography.labelMd.copyWith(
                  color: AppColors.secondary,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.orangeTintSoft,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  '${item.offerDiscountPercent ?? 0}%',
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Outlined add button that turns into a white quantity stepper once the item
/// is in the cart. It sits on the bottom-right corner of the product photo.
class _MenuQuantityControl extends StatelessWidget {
  const _MenuQuantityControl({
    required this.quantity,
    required this.canAdd,
    required this.l10n,
    required this.onIncrement,
    required this.onDecrement,
  });

  final int quantity;
  final bool canAdd;
  final L10n l10n;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    if (quantity == 0) {
      return _OutlineStepButton(
        icon: Icons.add,
        tooltip: l10n.increaseQuantity,
        onTap: canAdd ? onIncrement : null,
        emphasized: true,
        size: 34,
      );
    }
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _OutlineStepButton(
            icon: Icons.remove,
            tooltip: l10n.decreaseQuantity,
            onTap: onDecrement,
          ),
          SizedBox(
            width: 24,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTypography.labelMd.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _OutlineStepButton(
            icon: Icons.add,
            tooltip: l10n.increaseQuantity,
            onTap: canAdd ? onIncrement : null,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _OutlineStepButton extends StatelessWidget {
  const _OutlineStepButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.emphasized = false,
    this.size = 28,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final bool emphasized;
  final double size;

  @override
  Widget build(BuildContext context) {
    final active = onTap != null;
    final borderColor = !active
        ? AppColors.surfaceContainerHigh
        : (emphasized ? AppColors.primary : AppColors.surfaceContainerHigh);
    final iconColor = !active
        ? AppColors.surfaceDim
        : (emphasized ? AppColors.primary : AppColors.onSurface);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surfaceContainerLowest,
        shape: CircleBorder(
          side: BorderSide(
            color: borderColor,
            width: emphasized && active ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: size * 0.55, color: iconColor),
          ),
        ),
      ),
    );
  }
}
