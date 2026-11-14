import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../data/models/cart.dart';
import 'checkout_section_card.dart';

/// One cart line: name, options, line total, quantity stepper and the real
/// product image on the inline-end side.
class CheckoutItemCard extends StatelessWidget {
  const CheckoutItemCard({
    super.key,
    required this.line,
    required this.currency,
    required this.l10n,
    required this.onQuantity,
    required this.onRemove,
  });

  final CartLine line;
  final String currency;
  final L10n l10n;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return CheckoutSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        line.name,
                        style: AppTypography.labelLg.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Tooltip(
                      message: l10n.deleteItem,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                        onTap: onRemove,
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (line.options.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      line.optionsSummary(l10n.isArabic),
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (line.notes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      line.notes,
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.secondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (!line.available)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      line.unavailableReason ?? l10n.itemUnavailable,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Flexible(
                            child: Text(
                              Fmt.moneyExact(line.lineTotalMinor),
                              style: AppTypography.headlineSm.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currency,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    QuantityStepper(
                      value: line.quantity,
                      compact: true,
                      onChanged: onQuantity,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          AppImage(
            url: line.imageUrl,
            width: 80,
            height: 80,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            backgroundColor: AppColors.surfaceContainer,
          ),
        ],
      ),
    );
  }
}
