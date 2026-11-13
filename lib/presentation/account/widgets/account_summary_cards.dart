import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';

/// One quick-summary card (wallet, points, offers).
class AccountSummaryCardData {
  const AccountSummaryCardData({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
    required this.actionLabel,
    required this.onAction,
    this.accentAction = false,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  final String actionLabel;
  final VoidCallback onAction;

  /// Wallet uses the soft-red action; the other cards use a neutral one.
  final bool accentAction;
}

/// The three equal-height summary cards from the Stitch profile design.
class AccountSummaryCards extends StatelessWidget {
  const AccountSummaryCards({super.key, required this.cards});

  final List<AccountSummaryCardData> cards;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              if (index > 0) const SizedBox(width: 10),
              Expanded(child: _SummaryCard(data: cards[index])),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.data});

  final AccountSummaryCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.profileBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.profileCardShadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data.label,
                  style: AppTypography.labelMd.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.profileSecondaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(data.icon, size: 18, color: data.iconColor),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  data.value,
                  style: AppTypography.labelLg.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.profileHeading,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                data.unit,
                style: AppTypography.labelSm.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.profileSecondaryText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _CardAction(
            label: data.actionLabel,
            accent: data.accentAction,
            onTap: data.onAction,
          ),
        ],
      ),
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color:
          accent ? AppColors.profileAccentTint : AppColors.profileSurfaceMuted,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          height: 24,
          width: double.infinity,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: accent ? null : Border.all(color: AppColors.profileBorder),
          ),
          child: Text(
            label,
            style: AppTypography.labelMd.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color:
                  accent ? AppColors.profileAccent : AppColors.profileHeading,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
