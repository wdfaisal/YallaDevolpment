import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/account.dart';

/// One flat wallet ledger row: white card, hairline border, round icon chip,
/// description and a signed amount. Positive rows get a "completed" pill.
class WalletEntryTile extends StatelessWidget {
  const WalletEntryTile({
    super.key,
    required this.entry,
    required this.currency,
  });

  final WalletEntry entry;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final positive = entry.amountMinor >= 0;
    final tint = _tint(positive);
    final hasNote = entry.note != null && entry.note!.isNotEmpty;
    final title = hasNote ? entry.note! : _kindLabel(l10n);
    final subtitle = <String>[
      if (hasNote) _kindLabel(l10n),
      if (entry.reference != null && entry.reference!.isNotEmpty)
        entry.reference!,
      Fmt.dateTime(entry.createdAt),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderHairline),
            ),
            child: Icon(_icon(), size: 20, color: tint),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.secondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  positive
                      ? '+${Fmt.moneyExact(entry.amountMinor, currency: currency)}'
                      : Fmt.moneyExact(entry.amountMinor, currency: currency),
                  style: AppTypography.labelLg.copyWith(
                    color: positive ? AppColors.tertiary : AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (positive) ...[
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tertiaryFixed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.walletCompleted,
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.onTertiaryFixed,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _tint(bool positive) {
    return switch (entry.kind) {
      'order' => AppColors.primary,
      'order_refund' || 'cashback' => AppColors.tertiary,
      'top_up' || 'topup' => AppColors.tertiary,
      'withdrawal' => AppColors.error,
      _ => positive ? AppColors.tertiary : AppColors.secondary,
    };
  }

  IconData _icon() {
    return switch (entry.kind) {
      'order' => Icons.restaurant_outlined,
      'order_refund' || 'cashback' => Icons.stars_outlined,
      'top_up' || 'topup' => Icons.payments_outlined,
      'withdrawal' => Icons.account_balance_outlined,
      'adjustment' => Icons.tune,
      _ => Icons.receipt_long_outlined,
    };
  }

  String _kindLabel(L10n l10n) {
    return switch (entry.kind) {
      'order' => l10n.orderPayment,
      'order_refund' || 'cashback' => l10n.orderRefund,
      'top_up' || 'topup' => l10n.walletTopUp,
      'withdrawal' => l10n.walletWithdrawal,
      'adjustment' => l10n.walletAdjustment,
      _ => entry.kind,
    };
  }
}
