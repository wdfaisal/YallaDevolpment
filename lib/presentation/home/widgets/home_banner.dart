import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/catalog.dart';

/// Full-bleed promotional banner. The image uploaded in the backend fills the
/// whole banner surface (`BoxFit.cover`); the copy and call to action sit on a
/// scrim so they stay readable over any photo. Content is fully backend-driven:
/// no coupon code is invented when the payload has none, and without an image
/// the design gradient is shown instead. The home surface is flat, so the
/// banner is not elevated.
class HomeBanner extends StatelessWidget {
  const HomeBanner({
    super.key,
    required this.banners,
    required this.onTap,
  });

  final List<CatalogBanner> banners;
  final ValueChanged<CatalogBanner> onTap;

  /// Wide banner ratio from the home design.
  static const double _aspectRatio = 2.2;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    final banner = banners.first;
    final subtitle = l10n.isArabic ? banner.subtitleAr : banner.subtitleEn;
    final hasImage = banner.imageUrl.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: AspectRatio(
        aspectRatio: _aspectRatio,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(banner),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Design gradient: shown while the photo loads, when the
                // backend has no image, or when the photo fails.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [AppColors.primary, AppColors.primaryContainer],
                    ),
                  ),
                ),
                if (hasImage)
                  AppImage(
                    url: banner.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.zero,
                    backgroundColor: Colors.transparent,
                    icon: Icons.local_offer_outlined,
                  ),
                // Legibility scrim on the text side (right in Arabic).
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: AlignmentDirectional.centerStart,
                      end: AlignmentDirectional.centerEnd,
                      colors: [
                        Colors.black.withValues(alpha: 0.62),
                        Colors.black.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.28),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusPill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 13,
                              color: AppColors.onPrimary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              l10n.exclusiveOffer,
                              style: AppTypography.labelSm.copyWith(
                                color: AppColors.onPrimary,
                                fontSize: 10,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        banner.title(l10n.isArabic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headlineSm.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onPrimary,
                          height: 1.2,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySm.copyWith(
                            fontSize: 11,
                            color: AppColors.onPrimary.withValues(alpha: 0.90),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLowest,
                              borderRadius:
                                  BorderRadius.circular(AppSpacing.radius),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  l10n.orderNow,
                                  style: AppTypography.labelMd.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  l10n.isArabic
                                      ? Icons.arrow_back
                                      : Icons.arrow_forward,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (banners.length > 1)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (var index = 0;
                                    index < banners.length;
                                    index++) ...[
                                  if (index > 0) const SizedBox(width: 4),
                                  Container(
                                    width: index == 0 ? 12 : 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: index == 0
                                          ? AppColors.onPrimary
                                          : AppColors.onPrimary
                                              .withValues(alpha: 0.40),
                                      borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusPill,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        ],
                      ),
                    ],
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
