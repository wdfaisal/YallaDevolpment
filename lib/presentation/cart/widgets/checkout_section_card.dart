import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';

/// Flat white checkout card: a hairline border replaces every shadow from the
/// Stitch mock so the checkout page keeps a pure white, distraction-free canvas.
class CheckoutSectionCard extends StatelessWidget {
  const CheckoutSectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: borderColor ?? AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}

/// Icon + title row shared by the checkout cards.
class CheckoutSectionHeader extends StatelessWidget {
  const CheckoutSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor = AppColors.primary,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            title,
            style: AppTypography.labelLg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
