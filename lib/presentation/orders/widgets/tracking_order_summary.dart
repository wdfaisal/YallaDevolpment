import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/orders.dart';
import 'order_labels.dart';

/// Collapsible order summary from the Stitch tracking design. The card is pure
/// white with hairline separators; no grey panel and no shadow.
class TrackingOrderSummary extends StatefulWidget {
  const TrackingOrderSummary({
    super.key,
    required this.detail,
    required this.l10n,
    required this.onShareReceipt,
    required this.onSupport,
  });

  final OrderDetail detail;
  final L10n l10n;
  final VoidCallback onShareReceipt;
  final VoidCallback onSupport;

  @override
  State<TrackingOrderSummary> createState() => _TrackingOrderSummaryState();
}

class _TrackingOrderSummaryState extends State<TrackingOrderSummary> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final detail = widget.detail;
    final summary = detail.summary;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: AppColors.borderHairline),
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      size: 20,
                      color: AppColors.primary,
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
                                l10n.orderDetails,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.headlineSm,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusPill,
                                ),
                                border: Border.all(
                                  color: AppColors.borderHairline,
                                ),
                              ),
                              child: Text(
                                '#${summary.reference}',
                                style: AppTypography.labelSm.copyWith(
                                  color: AppColors.secondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${summary.itemCount} ${l10n.items} • ${summary.restaurantName ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.expand_more,
                      size: 22,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  const Divider(height: 1, color: AppColors.borderHairline),
                  const SizedBox(height: AppSpacing.sm),
                  for (final item in detail.items)
                    _ItemRow(item: item, currency: summary.currency),
                  const SizedBox(height: AppSpacing.xs),
                  const Divider(height: 1, color: AppColors.borderHairline),
                  const SizedBox(height: AppSpacing.sm),
                  _PriceRow(
                    label: l10n.subtotal,
                    value: Fmt.money(
                      detail.subtotalMinor,
                      currency: summary.currency,
                    ),
                  ),
                  if (detail.fulfillment == 'delivery')
                    _PriceRow(
                      label: l10n.deliveryFee,
                      value: detail.deliveryFeeMinor == 0
                          ? l10n.deliveryFeeFree
                          : Fmt.money(
                              detail.deliveryFeeMinor,
                              currency: summary.currency,
                            ),
                      highlight: detail.deliveryFeeMinor == 0,
                    ),
                  if (detail.discountMinor > 0)
                    _PriceRow(
                      label: detail.couponCode == null
                          ? l10n.discount
                          : '${l10n.discount} (${detail.couponCode})',
                      value:
                          '-${Fmt.money(detail.discountMinor, currency: summary.currency)}',
                      highlight: true,
                    ),
                  _PriceRow(
                    label: l10n.vat,
                    value: Fmt.money(
                      detail.vatMinor,
                      currency: summary.currency,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.totalPaid,
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        Fmt.moneyExact(
                          summary.totalMinor,
                          currency: summary.currency,
                        ),
                        style: AppTypography.labelLg.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        orderPaymentIcon(summary.paymentMethod),
                        size: 15,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${orderPaymentMethodLabel(l10n, summary.paymentMethod)} • ${orderPaymentStatusLabel(l10n, summary.paymentStatus)}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onShareReceipt,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            side: const BorderSide(
                              color: AppColors.borderHairline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.ios_share, size: 16),
                          label: Text(l10n.fullReceipt),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: widget.onSupport,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.onSurface,
                            side: const BorderSide(
                              color: AppColors.borderHairline,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusMd,
                              ),
                            ),
                          ),
                          icon: const Icon(Icons.support_agent, size: 16),
                          label: Text(l10n.helpAndSupport),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.currency});

  final OrderItemLine item;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Text(
              '${item.quantity}×',
              style: AppTypography.labelSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: AppTypography.bodyMd),
                if (item.options.isNotEmpty)
                  Text(
                    item.options,
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
                if (item.notes.isNotEmpty)
                  Text(
                    item.notes,
                    style: AppTypography.labelSm.copyWith(
                      color: AppColors.secondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            Fmt.money(item.lineTotalMinor, currency: currency),
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w700,
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
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
            ),
          ),
          Text(
            value,
            style: AppTypography.labelMd.copyWith(
              color: highlight ? AppColors.tertiary : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
