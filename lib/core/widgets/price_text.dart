import 'package:flutter/material.dart';

import '../design/app_colors.dart';
import '../design/app_typography.dart';
import '../formatting/formatters.dart';

/// Price row: current price plus an optional struck-through original price.
class PriceText extends StatelessWidget {
  const PriceText({
    super.key,
    required this.priceMinor,
    this.compareAtMinor,
    this.currency = 'SAR',
    this.size = PriceSize.md,
    this.alignEnd = false,
  });

  final int priceMinor;
  final int? compareAtMinor;
  final String currency;
  final PriceSize size;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final style = switch (size) {
      PriceSize.sm => AppTypography.labelMd,
      PriceSize.md => AppTypography.headlineSm,
      PriceSize.lg => AppTypography.headlineMd,
    };
    final children = <Widget>[
      Text(
        Fmt.money(priceMinor, currency: currency),
        style: style.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
      ),
      if (compareAtMinor != null && compareAtMinor! > priceMinor) ...[
        const SizedBox(width: 6),
        Text(
          Fmt.money(compareAtMinor!, currency: currency),
          style: AppTypography.labelSm.copyWith(
            color: AppColors.secondary,
            decoration: TextDecoration.lineThrough,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: alignEnd ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: children,
    );
  }
}

enum PriceSize { sm, md, lg }
