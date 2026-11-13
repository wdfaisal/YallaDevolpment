import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_spacing.dart';
import '../design/app_typography.dart';

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
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
              style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _button(
            icon: Icons.add,
            enabled: value < max,
            onTap: () => onChanged(value + 1),
            dimension: dimension,
            filled: true,
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
    bool filled = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(dimension),
      onTap: enabled ? onTap : null,
      child: Container(
        width: dimension,
        height: dimension,
        decoration: BoxDecoration(
          color: filled ? AppColors.primaryContainer : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: dimension * 0.5,
          color: filled
              ? AppColors.onPrimary
              : (enabled ? AppColors.onSurface : AppColors.surfaceDim),
        ),
      ),
    );
  }
}
