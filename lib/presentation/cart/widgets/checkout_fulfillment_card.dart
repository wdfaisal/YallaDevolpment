import 'package:flutter/material.dart';

import '../../../core/design/app_spacing.dart';
import '../../../core/localization/l10n.dart';
import '../../shared/sheets.dart';
import 'checkout_section_card.dart';

/// Delivery / pickup switch. This is a real checkout capability kept from the
/// previous screen; it stays inside a flat white card to match the design.
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
          Row(
            children: [
              Expanded(
                child: AppChoiceChip(
                  label: l10n.delivery,
                  selected: fulfillment == 'delivery',
                  icon: Icons.delivery_dining,
                  onTap: () {
                    if (fulfillment != 'delivery') onChanged('delivery');
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppChoiceChip(
                  label: l10n.pickup,
                  selected: fulfillment == 'pickup',
                  icon: Icons.storefront_outlined,
                  onTap: () {
                    if (fulfillment != 'pickup') onChanged('pickup');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
