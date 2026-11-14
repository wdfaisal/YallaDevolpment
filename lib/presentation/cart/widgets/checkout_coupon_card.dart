import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/cart.dart';
import 'checkout_section_card.dart';

/// Coupon card with the applied-badge view from the Stitch design and a real
/// code field when no coupon is active.
class CheckoutCouponCard extends StatelessWidget {
  const CheckoutCouponCard({
    super.key,
    required this.controller,
    required this.quote,
    required this.l10n,
    required this.quoting,
    required this.onApply,
    required this.onRemove,
  });

  final TextEditingController controller;
  final CartQuote? quote;
  final L10n l10n;
  final bool quoting;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final applied = quote?.coupon;
    final couponError = quote?.couponError;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      borderSide: const BorderSide(color: AppColors.borderSubtle),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
    );

    return CheckoutSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckoutSectionHeader(
            icon: Icons.confirmation_number,
            title: l10n.couponCode,
          ),
          const SizedBox(height: AppSpacing.xs),
          if (applied != null)
            _AppliedCoupon(
              coupon: applied,
              currency: quote?.currency ?? l10n.currencyDefault,
              l10n: l10n,
              onRemove: onRemove,
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => onApply(),
                    style: AppTypography.bodyMd,
                    decoration: InputDecoration(
                      hintText: l10n.couponCode,
                      hintStyle: AppTypography.bodySm.copyWith(
                        color: AppColors.secondary,
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 12,
                      ),
                      border: border,
                      enabledBorder: border,
                      focusedBorder: focusedBorder,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: quoting ? null : onApply,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceContainerLowest,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                      ),
                      textStyle: AppTypography.labelLg,
                    ),
                    child: Text(l10n.applyCoupon),
                  ),
                ),
              ],
            ),
          if (couponError != null && couponError.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                couponError,
                style: AppTypography.bodySm.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }
}

class _AppliedCoupon extends StatelessWidget {
  const _AppliedCoupon({
    required this.coupon,
    required this.currency,
    required this.l10n,
    required this.onRemove,
  });

  final AppliedCoupon coupon;
  final String currency;
  final L10n l10n;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.tertiaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              size: 18,
              color: AppColors.onTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        coupon.code,
                        style: AppTypography.labelLg.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tertiary,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusPill,
                        ),
                      ),
                      child: Text(
                        l10n.couponAppliedBadge,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.onTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  coupon.description.isNotEmpty
                      ? coupon.description
                      : l10n.couponSaved(
                          Fmt.moneyExact(
                            coupon.discountMinor,
                            currency: currency,
                          ),
                        ),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.tertiary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onRemove,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(44, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.cancel,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
