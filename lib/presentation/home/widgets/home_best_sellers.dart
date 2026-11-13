import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/catalog.dart';
import '../../shared/menu_widgets.dart';
import 'home_section_header.dart';

/// "Most ordered this week" two-column grid.
class HomeBestSellers extends StatelessWidget {
  const HomeBestSellers({
    super.key,
    required this.items,
    required this.onTap,
    required this.onAdd,
    required this.onMore,
  });

  final List<CatalogMenuItem> items;
  final ValueChanged<CatalogMenuItem> onTap;
  final ValueChanged<CatalogMenuItem> onAdd;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final l10n = L10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: l10n.bestSellersThisWeek,
          trailing: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            onTap: onMore,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.more,
                style: AppTypography.labelMd.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ),
        // The design uses gap-3 between the section heading and the grid.
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - AppSpacing.md) / 2;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: cardWidth + 78,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return BestSellerCard(
                    item: item,
                    showShadow: false,
                    onTap: () => onTap(item),
                    onAdd: () => onAdd(item),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
