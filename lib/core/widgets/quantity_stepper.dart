import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

/// Quantity pill used by the cart and the restaurant menu. Pure white with a
/// hairline border; the `+` control is outlined instead of filled so the pill
/// stays flat against the white checkout canvas.
class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    this.compact = false,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dimension = compact ? 30.0 : 38.0;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(
            icon: Icons.remove,
            enabled: value > min,
            onTap: () => onChanged(value - 1),
            dimension: dimension,
          ),
          SizedBox(
            width: compact ? 26 : 34,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style:
                  AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _button(
            icon: Icons.add,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
            dimension: dimension,
            outlined: true,
          ),
        ],
      ),
    );
  }

  Widget _button({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
    required double dimension,
    bool outlined = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(dimension),
      onTap: enabled ? onTap : null,
      child: Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          shape: BoxShape.circle,
          border: outlined
              ? Border.all(
                  color: enabled
                      ? AppColors.primary.withValues(alpha: 0.4)
                      : AppColors.borderSubtle,
                )
              : null,
        ),
        child: Icon(
          icon,
          size: dimension * 0.5,
          color: outlined
              ? (enabled ? AppColors.primary : AppColors.surfaceDim)
              : (enabled ? AppColors.onSurface : AppColors.surfaceDim),
        ),
      ),
    );
  }
}
