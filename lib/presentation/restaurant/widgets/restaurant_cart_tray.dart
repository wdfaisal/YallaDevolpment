import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/cart.dart';

/// Flat sticky cart tray from the Stitch restaurant design. Only lines that
/// belong to this restaurant are counted; a cart from another restaurant shows
/// as empty here.
class RestaurantCartTray extends StatelessWidget {
  const RestaurantCartTray({
    super.key,
    required this.cart,
    required this.restaurantId,
    required this.l10n,
    required this.onCheckout,
  });

  final CartResponse cart;
  final String restaurantId;
  final L10n l10n;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final belongs = cart.restaurantId == restaurantId;
    final count = belongs ? cart.itemCount : 0;
    final total = belongs
        ? (cart.quote?.totalMinor ??
            cart.lines.fold<int>(0, (sum, line) => sum + line.lineTotalMinor))
        : 0;
    final currency = belongs
        ? (cart.quote?.currency ?? l10n.currencyDefault)
        : l10n.currencyDefault;
    final enabled = count > 0;

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.surfaceContainerHigh),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            // heightFactor keeps the tray at its intrinsic height: inside
            // Scaffold.bottomNavigationBar a plain Center would expand to the
            // full screen height and collapse the page body to 0px.
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 448),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.tertiary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                l10n.cartItemsCount(count),
                                style: AppTypography.labelMd,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              Fmt.money(total),
                              style: AppTypography.headlineMd.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currency,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                l10n.includesVat,
                                style: AppTypography.bodySm.copyWith(
                                  color: AppColors.secondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 210),
                    child: SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: enabled ? onCheckout : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryContainer,
                          disabledForegroundColor: AppColors.surfaceDim,
                          side: BorderSide(
                            color: enabled
                                ? AppColors.primaryContainer
                                : AppColors.surfaceContainerHigh,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          textStyle: AppTypography.labelLg,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                l10n.checkout,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_back, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
