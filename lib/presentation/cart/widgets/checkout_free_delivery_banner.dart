import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/cart.dart';
import 'checkout_section_card.dart';

/// "Free delivery saved" progress banner. Only rendered when the backend quote
/// confirms free delivery, so the percentage is always backed by real data.
class CheckoutFreeDeliveryBanner extends StatelessWidget {
  const CheckoutFreeDeliveryBanner({
    super.key,
    required this.quote,
    required this.l10n,
  });

  final CartQuote quote;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final saved = quote.deliveryFeeOriginalMinor - quote.deliveryFeeMinor;
    final message = saved > 0
        ? l10n.freeDeliverySaved(
            Fmt.moneyExact(saved, currency: quote.currency),
          )
        : l10n.freeDeliveryApplied;

    return CheckoutSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_shipping,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  message,
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text(
                  l10n.completedPercent(100),
                  style: AppTypography.labelSm.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            child: LinearProgressIndicator(
              value: 1,
              minHeight: 6,
              backgroundColor: AppColors.surfaceContainerHigh,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
