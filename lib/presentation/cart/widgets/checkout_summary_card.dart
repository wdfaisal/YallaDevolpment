import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/cart.dart';
import 'checkout_section_card.dart';

/// Price breakdown. Every amount is rendered straight from the backend quote.
class CheckoutSummaryCard extends StatelessWidget {
  const CheckoutSummaryCard({
    super.key,
    required this.quote,
    required this.l10n,
  });

  final CartQuote? quote;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final currentQuote = quote;
    if (currentQuote == null) {
      return const CheckoutSectionCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: LoadingState(),
        ),
      );
    }
    final currency = currentQuote.currency;
    final vatPercent = currentQuote.taxRateBasisPoints / 100;
    final vatLabel = vatPercent == vatPercent.roundToDouble()
        ? vatPercent.toStringAsFixed(0)
        : vatPercent.toStringAsFixed(1);

    return CheckoutSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.priceDetails, style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          _PriceRow(
            label: l10n.subtotal,
            value: Fmt.moneyExact(currentQuote.subtotalMinor),
            currency: currency,
          ),
          if (currentQuote.fulfillment == 'delivery')
            _PriceRow(
              label: l10n.deliveryFee,
              value: currentQuote.deliveryFeeMinor == 0
                  ? l10n.deliveryFeeFree
                  : Fmt.moneyExact(currentQuote.deliveryFeeMinor),
              currency: currentQuote.deliveryFeeMinor == 0 ? null : currency,
              original: currentQuote.deliveryFeeOriginalMinor >
                      currentQuote.deliveryFeeMinor
                  ? Fmt.moneyExact(
                      currentQuote.deliveryFeeOriginalMinor,
                      currency: currency,
                    )
                  : null,
              highlight: currentQuote.deliveryFeeMinor == 0,
            ),
          if (currentQuote.discountMinor > 0)
            _PriceRow(
              label: currentQuote.coupon == null
                  ? l10n.discount
                  : '${l10n.discount} (${currentQuote.coupon!.code})',
              value: '-${Fmt.moneyExact(currentQuote.discountMinor)}',
              currency: currency,
              highlight: true,
            ),
          _PriceRow(
            label: '${l10n.vat} ($vatLabel%)',
            value: Fmt.moneyExact(currentQuote.vatMinor),
            currency: currency,
            showInfo: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.finalTotal, style: AppTypography.headlineSm),
                      Text(
                        l10n.finalTotalHint,
                        style: AppTypography.labelSm.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          Fmt.moneyExact(currentQuote.totalMinor),
                          style: AppTypography.headlineXlMobile.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          currency,
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.currency,
    this.original,
    this.highlight = false,
    this.showInfo = false,
  });

  final String label;
  final String value;
  final String? currency;
  final String? original;
  final bool highlight;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    final color = highlight ? AppColors.tertiary : AppColors.onSurface;
    return Padding(
      // 4 top + 4 bottom = the design's 8px rhythm between price rows.
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: AppTypography.bodyMd.copyWith(
                      color:
                          highlight ? AppColors.tertiary : AppColors.secondary,
                      fontWeight: highlight ? FontWeight.w600 : FontWeight.w400,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (showInfo) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.secondary,
                  ),
                ],
              ],
            ),
          ),
          if (original != null) ...[
            Text(
              original!,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.secondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            value,
            style: AppTypography.bodyMd.copyWith(
              color: color,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          if (currency != null) ...[
            const SizedBox(width: 4),
            Text(
              currency!,
              style: AppTypography.labelMd.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
