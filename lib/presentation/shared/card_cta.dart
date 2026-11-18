import 'package:flutter/material.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';

/// Compact outlined action used at the end of a list card (orders, favorites).
/// The primary action keeps the orange outline; secondary actions use the
/// hairline border. Both share one width so cards line up down the list.
class CardCta extends StatelessWidget {
  const CardCta({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    // A tight box, not `minimumSize`: the app theme uses a compact visual
    // density, which would otherwise shrink the button's minimum width.
    return SizedBox(
      width: 132,
      height: 38,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor:
              highlighted ? AppColors.primary : AppColors.onSurface,
          side: BorderSide(
            color: highlighted ? AppColors.primary : AppColors.borderHairline,
          ),
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
          ),
          textStyle: AppTypography.labelMd.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        icon: Icon(icon, size: 15),
        label: Text(label),
      ),
    );
  }
}
