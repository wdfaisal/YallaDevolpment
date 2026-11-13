import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/localization/l10n.dart';
import '../../../data/models/catalog.dart';

/// Sticky category strip from the Stitch restaurant design: a leading menu
/// button that opens the section/search sheet followed by underlined tabs.
class RestaurantCategoryTabs extends StatefulWidget {
  const RestaurantCategoryTabs({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
    required this.onOpenMenu,
  });

  final List<CatalogMenuCategory> categories;
  final String? selectedId;
  final ValueChanged<String> onSelected;
  final VoidCallback onOpenMenu;

  @override
  State<RestaurantCategoryTabs> createState() =>
      _RestaurantCategoryTabsState();
}

class _RestaurantCategoryTabsState extends State<RestaurantCategoryTabs> {
  final Map<String, GlobalKey> _tabKeys = <String, GlobalKey>{};

  @override
  void didUpdateWidget(covariant RestaurantCategoryTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _revealSelected();
    }
  }

  void _revealSelected() {
    final id = widget.selectedId;
    if (id == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final tabContext = _tabKeys[id]?.currentContext;
      if (tabContext == null) return;
      Scrollable.ensureVisible(
        tabContext,
        alignment: 0.5,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Container(
            height: 44,
            padding: const EdgeInsetsDirectional.only(end: 12),
            margin: const EdgeInsetsDirectional.only(end: 4),
            decoration: const BoxDecoration(
              border: BorderDirectional(
                end: BorderSide(color: AppColors.surfaceContainerHighest),
              ),
            ),
            child: Tooltip(
              message: l10n.menuSections,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: widget.onOpenMenu,
                child: const SizedBox(
                  width: 40,
                  height: 44,
                  child: Icon(
                    Icons.menu,
                    size: 22,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.only(end: 16),
              itemCount: widget.categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final selected = category.id == widget.selectedId;
                return InkWell(
                  key: _tabKeys.putIfAbsent(category.id, GlobalKey.new),
                  onTap: () => widget.onSelected(category.id),
                  child: Container(
                    alignment: Alignment.bottomCenter,
                    padding: const EdgeInsets.only(top: 4, bottom: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected
                              ? AppColors.onSurface
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      category.name,
                      style: AppTypography.labelMd.copyWith(
                        color: selected
                            ? AppColors.onSurface
                            : AppColors.secondary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pins the category strip under the status bar while the menu scrolls.
class RestaurantTabsHeaderDelegate extends SliverPersistentHeaderDelegate {
  RestaurantTabsHeaderDelegate({required this.child, required this.topInset});

  final Widget child;
  final double topInset;

  static const double _rowHeight = 44;
  static const double _topPadding = 8;

  @override
  double get minExtent => topInset + _topPadding + _rowHeight + 1;

  @override
  double get maxExtent => minExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      padding: EdgeInsets.only(top: topInset + _topPadding),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceContainerHigh),
        ),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant RestaurantTabsHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.topInset != topInset;
  }
}
