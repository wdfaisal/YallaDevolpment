import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/account.dart';
import 'wallet_entry_tile.dart';

/// Ledger filters shown above the wallet activity list.
enum WalletFilter { all, topUp, purchases, cashback }

/// "Recent activity" block from the Stitch wallet design: section header,
/// horizontally scrolling filter chips and flat white ledger rows.
class WalletActivitySection extends StatelessWidget {
  const WalletActivitySection({
    super.key,
    required this.entries,
    required this.currency,
    required this.filter,
    required this.onFilterChanged,
    required this.onViewAll,
  });

  final List<WalletEntry> entries;
  final String currency;
  final WalletFilter filter;
  final ValueChanged<WalletFilter> onFilterChanged;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final visible = entries.where(_matches).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l10n.walletRecent, style: AppTypography.headlineSm),
            ),
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xs,
                  vertical: AppSpacing.xs,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: AppTypography.labelMd,
              ),
              child: Text(l10n.walletViewAll),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: l10n.walletFilterAll,
                selected: filter == WalletFilter.all,
                onTap: () => onFilterChanged(WalletFilter.all),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: l10n.walletFilterTopUp,
                selected: filter == WalletFilter.topUp,
                onTap: () => onFilterChanged(WalletFilter.topUp),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: l10n.walletFilterPurchases,
                selected: filter == WalletFilter.purchases,
                onTap: () => onFilterChanged(WalletFilter.purchases),
              ),
              const SizedBox(width: AppSpacing.sm),
              _FilterChip(
                label: l10n.walletFilterCashback,
                selected: filter == WalletFilter.cashback,
                onTap: () => onFilterChanged(WalletFilter.cashback),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.lg),
            child: EmptyState(
              title: l10n.noWalletEntries,
              icon: Icons.receipt_long_outlined,
            ),
          )
        else
          for (final entry in visible)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: WalletEntryTile(entry: entry, currency: currency),
            ),
      ],
    );
  }

  bool _matches(WalletEntry entry) {
    return switch (filter) {
      WalletFilter.all => true,
      WalletFilter.topUp => entry.kind == 'top_up' || entry.kind == 'topup',
      WalletFilter.purchases => entry.kind == 'order',
      WalletFilter.cashback =>
        entry.kind == 'order_refund' || entry.kind == 'cashback',
    };
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusPill);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color:
            selected ? AppColors.onSurface : AppColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: selected
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderHairline),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            child: Text(
              label,
              style: AppTypography.labelMd.copyWith(
                color: selected
                    ? AppColors.surfaceContainerLowest
                    : AppColors.onSurface,
              ),
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
