import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/catalog.dart';

/// Horizontal menu row from the Stitch restaurant design: text + price +
/// quantity stepper on the start side, 96px image on the end side. Flat white
/// card separated by a hairline border instead of a shadow.
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
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  Fmt.money(item.priceMinor),
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
                        ),
                        const SizedBox(width: 8),
                        _QuantityStepper(
                          quantity: quantity,
                          canAdd: canAdd,
                          l10n: l10n,
                          onIncrement: onIncrement,
                          onDecrement: onDecrement,
                        ),
                      ],
                    ),
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
                      backgroundColor: AppColors.surfaceContainer,
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
                        bottom: 4,
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

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
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
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove,
            tooltip: l10n.decreaseQuantity,
            background: AppColors.surfaceContainer,
            foreground: quantity > 0
                ? AppColors.onSurface
                : AppColors.surfaceDim,
            onTap: quantity > 0 ? onDecrement : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: AppTypography.labelLg.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _StepButton(
            icon: Icons.add,
            tooltip: l10n.increaseQuantity,
            background: canAdd
                ? AppColors.primary
                : AppColors.surfaceContainerHigh,
            foreground: canAdd ? AppColors.onPrimary : AppColors.secondary,
            onTap: canAdd ? onIncrement : null,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 32,
            child: Icon(icon, size: 16, color: foreground),
          ),
        ),
      ),
    );
  }
}
