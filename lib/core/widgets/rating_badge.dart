import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_typography.dart';
import '../formatting/formatters.dart';

/// Green rating chip (`4.8` + optional review count).
class RatingBadge extends StatelessWidget {
  const RatingBadge({
    super.key,
    required this.rating,
    this.count,
    this.compact = false,
  });

  final double rating;
  final int? count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tertiary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: compact ? 12 : 14, color: AppColors.tertiary),
          const SizedBox(width: 2),
          Text(
            Fmt.rating(rating),
            style: AppTypography.labelMd.copyWith(
              color: AppColors.tertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 2),
            Text(
              '(${_compactCount(count!)})',
              style: AppTypography.labelSm.copyWith(
                color: AppColors.secondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _compactCount(int value) {
    if (value >= 1000) {
      final thousands = value / 1000;
      return '${thousands.toStringAsFixed(1)}k';
    }
    return value.toString();
  }
}

/// Status pill (`مفتوح` / `مغلق`).
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.isOpen});

  final String label;
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    final background = isOpen ? AppColors.tertiary : AppColors.surfaceContainerHighest;
    final foreground = isOpen ? AppColors.onTertiary : AppColors.secondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(color: foreground, fontWeight: FontWeight.w700),
      ),
    );
  }
}
