import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/orders.dart';
import '../../shared/card_cta.dart';

/// One order in the My Orders list: white flat card, hairline border, a status
/// accent bar on the leading edge and a single compact call to action.
class OrderCard extends StatelessWidget {
  const OrderCard({
    super.key,
    required this.order,
    required this.onTap,
    required this.onReorder,
  });

  final OrderSummary order;
  final VoidCallback onTap;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final arabic = l10n.isArabic;
    final accent = _statusColor(order.status);
    final canReorder =
        !order.isActive && order.canReorder && order.restaurantId != null;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppSpacing.lg,
                AppSpacing.md + 2,
                AppSpacing.md,
                AppSpacing.md,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: AppColors.borderHairline),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppImage(
                        url: order.restaurantLogoUrl,
                        width: 48,
                        height: 48,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        icon: Icons.storefront_outlined,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.restaurantName ?? '—',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelLg.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.reference,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelMd.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _StatusChip(
                              label: order.statusLabel(arabic),
                              color: accent,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Fmt.money(
                              order.totalMinor,
                              currency: order.currency,
                            ),
                            style: AppTypography.labelLg.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${order.itemCount} ${l10n.items}',
                            style: AppTypography.labelMd.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(height: 1, color: AppColors.borderHairline),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          Fmt.relative(order.placedAt, isArabic: arabic),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelMd.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondary,
                          ),
                        ),
                      ),
                      if (order.canRate && !order.isActive) ...[
                        _RateShortcut(onTap: onTap),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      CardCta(
                        label: order.isActive
                            ? l10n.track
                            : canReorder
                                ? l10n.reorder
                                : l10n.viewOrder,
                        icon: order.isActive
                            ? Icons.near_me_outlined
                            : canReorder
                                ? Icons.replay
                                : Icons.receipt_long_outlined,
                        highlighted: order.isActive,
                        onTap: canReorder ? onReorder : onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        PositionedDirectional(
          start: 0,
          top: AppSpacing.lg,
          bottom: AppSpacing.lg,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'delivered' => AppColors.tertiary,
      'cancelled' || 'failed_delivery' => AppColors.secondary,
      'under_financial_review' => AppColors.warning,
      _ => AppColors.primaryContainer,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _RateShortcut extends StatelessWidget {
  const _RateShortcut({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: L10n.of(context).rateOrder,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: AppColors.borderHairline),
          ),
          child: const Icon(
            Icons.star_outline,
            size: 18,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}
