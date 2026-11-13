import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/price_text.dart';
import '../../../core/widgets/snack.dart';
import '../../../data/models/catalog.dart';
import '../../shared/meal_launcher.dart';

/// Lists the restaurant offers behind the "exclusive offers" pill.
Future<void> showRestaurantOffersSheet(
  BuildContext context, {
  required List<CatalogOffer> offers,
  required ValueChanged<CatalogOffer> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (sheetContext) {
      final l10n = L10n.of(context);
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(
              title: l10n.offers,
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 420),
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                itemCount: offers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  final discount = offer.discountType == 'percentage'
                      ? '${offer.discountValue}%'
                      : Fmt.money(
                          offer.discountValue,
                          currency: l10n.currencyDefault,
                        );
                  return InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      onSelect(offer);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                          color: AppColors.surfaceContainerHigh,
                        ),
                      ),
                      child: Row(
                        children: [
                          AppImage(
                            url: offer.imageUrl,
                            width: 56,
                            height: 56,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                            backgroundColor: AppColors.surfaceContainer,
                            icon: Icons.local_offer_outlined,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.title(l10n.isArabic),
                                  style: AppTypography.labelLg,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  offer.description(l10n.isArabic),
                                  style: AppTypography.bodySm.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radiusPill),
                            ),
                            child: Text(
                              discount,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onPrimaryFixedVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}

/// Offer details with the discounted items. Mirrors the previous sheet but
/// lives next to the restaurant widgets so the screen stays small.
Future<void> showRestaurantOfferDetail(
  BuildContext context, {
  required CatalogOffer offer,
  required bool restaurantOpen,
}) {
  final l10n = L10n.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surfaceContainerLowest,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SheetHeader(
            title: offer.title(l10n.isArabic),
            trailing: IconButton(
              tooltip: l10n.shareOffer,
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: () => Share.share(
                '${offer.title(l10n.isArabic)} — ${offer.restaurantName}\n'
                '${offer.description(l10n.isArabic)}',
                subject: offer.title(l10n.isArabic),
              ),
            ),
            onClose: () => Navigator.of(sheetContext).pop(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.description(l10n.isArabic),
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 360),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: offer.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = offer.items[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.displayName(l10n.isArabic),
                          style: AppTypography.labelLg,
                        ),
                        subtitle: Text(
                          offer.discountType == 'percentage'
                              ? '${offer.discountValue}% ${l10n.offers}'
                              : Fmt.money(offer.discountValue),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.tertiary,
                          ),
                        ),
                        trailing: PriceText(
                          priceMinor: item.offerPriceMinor,
                          compareAtMinor:
                              item.priceMinor > item.offerPriceMinor
                                  ? item.priceMinor
                                  : null,
                          size: PriceSize.sm,
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          openMeal(
                            context,
                            item.menuItemId,
                            restaurantOpen: restaurantOpen,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
