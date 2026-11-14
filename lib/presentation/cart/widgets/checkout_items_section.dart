import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/cart.dart';
import 'checkout_item_card.dart';

/// "Requested items" section: heading + edit shortcut, one flat card per line
/// and the "add more from this restaurant" action.
class CheckoutItemsSection extends StatelessWidget {
  const CheckoutItemsSection({
    super.key,
    required this.cart,
    required this.currency,
    required this.l10n,
    required this.onQuantity,
    required this.onRemove,
    this.onEdit,
    this.descriptions = const {},
  });

  final CartResponse cart;
  final String currency;
  final L10n l10n;
  final void Function(CartLine line, int quantity) onQuantity;
  final void Function(CartLine line) onRemove;
  final VoidCallback? onEdit;

  /// Menu item id → catalog description, sourced from the restaurant detail.
  final Map<String, String> descriptions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.requestedItems(cart.itemCount),
                style: AppTypography.headlineSm,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (onEdit != null)
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.editOrder,
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final line in cart.lines) ...[
          CheckoutItemCard(
            line: line,
            currency: currency,
            l10n: l10n,
            description: descriptions[line.menuItemId],
            onQuantity: (value) => onQuantity(line, value),
            onRemove: () => onRemove(line),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (onEdit != null)
          SizedBox(
            width: double.infinity,
            height: 40,
            child: Material(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                onTap: onEdit,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          l10n.addMoreFromRestaurant,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
