import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import 'checkout_section_card.dart';

/// Delivery / pickup selector. Rendered as a single flat dropdown so it shares
/// the same field language as the rest of the checkout inputs.
class CheckoutFulfillmentCard extends StatelessWidget {
  const CheckoutFulfillmentCard({
    super.key,
    required this.fulfillment,
    required this.l10n,
    required this.onChanged,
  });

  final String fulfillment;
  final L10n l10n;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return CheckoutSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckoutSectionHeader(
            icon: Icons.delivery_dining,
            title: l10n.deliveryInfo,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.md,
              end: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: fulfillment,
                isExpanded: true,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                dropdownColor: AppColors.surfaceContainerLowest,
                icon: const Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: AppColors.secondary,
                ),
                items: [
                  DropdownMenuItem(
                    value: 'delivery',
                    child: _OptionRow(
                      icon: Icons.delivery_dining,
                      label: l10n.delivery,
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'pickup',
                    child: _OptionRow(
                      icon: Icons.storefront_outlined,
                      label: l10n.pickup,
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null && value != fulfillment) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionRow extends StatelessWidget {
  const _OptionRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            label,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
