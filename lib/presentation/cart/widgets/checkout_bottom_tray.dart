import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/cart.dart';

/// Sticky confirm & pay tray from the Stitch design. Flat white surface with a
/// single hairline top border instead of the mock's drop shadow.
class CheckoutBottomTray extends StatelessWidget {
  const CheckoutBottomTray({
    super.key,
    required this.quote,
    required this.l10n,
    required this.placing,
    required this.enabled,
    required this.onPressed,
  });

  final CartQuote? quote;
  final L10n l10n;
  final bool placing;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final currentQuote = quote;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Center(
          // heightFactor keeps the tray at its intrinsic height: inside
          // Scaffold.bottomNavigationBar a plain Center would expand to the
          // full screen height and collapse the page body to 0px.
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (currentQuote != null && !currentQuote.meetsMinimum)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      '${l10n.minimumNotMet}: ${l10n.minimumRemaining} '
                      '${Fmt.money(currentQuote.remainingForMinimum, currency: currentQuote.currency)}',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  height: 56,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: enabled ? onPressed : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryContainer,
                      foregroundColor: AppColors.onPrimary,
                      disabledBackgroundColor: AppColors.surfaceContainerHigh,
                      disabledForegroundColor: AppColors.secondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xxl,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusMd,
                        ),
                      ),
                      textStyle: AppTypography.headlineSm,
                    ),
                    child: placing
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Flexible(
                                child: Text(
                                  l10n.placingOrder,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Flexible(
                                child: Text(
                                  l10n.confirmAndPay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              const Icon(Icons.arrow_back, size: 20),
                              const Spacer(),
                              if (currentQuote != null)
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(
                                          AppSpacing.radius,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            Fmt.moneyExact(
                                              currentQuote.totalMinor,
                                            ),
                                            style:
                                                AppTypography.headlineSm.copyWith(
                                              color: AppColors.onPrimary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            currentQuote.currency,
                                            style:
                                                AppTypography.labelMd.copyWith(
                                              color: AppColors.onPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
