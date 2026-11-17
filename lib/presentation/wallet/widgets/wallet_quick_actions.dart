import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';

/// Three quick wallet actions from the Stitch wallet design. The first tile is
/// the solid primary CTA; the other two are flat white with a hairline border.
class WalletQuickActions extends StatelessWidget {
  const WalletQuickActions({
    super.key,
    required this.onTopUp,
    required this.onGift,
    required this.onRewards,
  });

  final VoidCallback onTopUp;
  final VoidCallback onGift;
  final VoidCallback onRewards;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _WalletActionTile(
            icon: Icons.add_circle_outline,
            label: l10n.walletTopUpAction,
            background: AppColors.primary,
            foreground: AppColors.onPrimary,
            onTap: onTopUp,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _WalletActionTile(
            icon: Icons.card_giftcard,
            label: l10n.walletGift,
            background: AppColors.surfaceContainerLowest,
            foreground: AppColors.primary,
            borderColor: AppColors.borderHairline,
            onTap: onGift,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _WalletActionTile(
            icon: Icons.loyalty_outlined,
            label: l10n.walletRewards,
            background: AppColors.surfaceContainerLowest,
            foreground: AppColors.tertiary,
            borderColor: AppColors.borderHairline,
            onTap: onRewards,
          ),
        ),
      ],
    );
  }
}

class _WalletActionTile extends StatelessWidget {
  const _WalletActionTile({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppSpacing.radiusMd);
    return Material(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!),
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: foreground),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppTypography.labelMd.copyWith(color: foreground),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
