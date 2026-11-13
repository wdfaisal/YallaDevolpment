import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/catalog.dart';

/// Gradient promotional banner from the Stitch home design. Content is fully
/// backend-driven: no coupon code is invented when the payload has none.
/// The home surface is flat, so the banner is not elevated.
class HomeBanner extends StatelessWidget {
  const HomeBanner({
    super.key,
    required this.banners,
    required this.onTap,
  });

  final List<CatalogBanner> banners;
  final ValueChanged<CatalogBanner> onTap;

  @override
  Widget build(BuildContext context) {
    if (banners.isEmpty) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    final banner = banners.first;
    final subtitle = l10n.isArabic ? banner.subtitleAr : banner.subtitleEn;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [AppColors.primary, AppColors.primaryContainer],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
                      fontSize: 16,
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
                  const SizedBox(height: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    onTap: () => onTap(banner),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
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
                            l10n.isArabic ? Icons.arrow_back : Icons.arrow_forward,
                            size: 13,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: AppImage(
                      url: banner.imageUrl,
                      width: 76,
                      height: 76,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < banners.length; index++) ...[
                      if (index > 0) const SizedBox(width: 4),
                      Container(
                        width: index == 0 ? 12 : 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: index == 0
                              ? AppColors.onPrimary
                              : AppColors.onPrimary.withValues(alpha: 0.40),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
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
    );
  }
}
