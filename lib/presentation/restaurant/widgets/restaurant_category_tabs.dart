import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
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

  /// Row height sized for the 14px labels plus the 2px selected underline.
  static const double height = 46;

  @override
  State<RestaurantCategoryTabs> createState() => _RestaurantCategoryTabsState();
}

class _RestaurantCategoryTabsState extends State<RestaurantCategoryTabs> {
  final Map<String, GlobalKey> _tabKeys = <String, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    // The strip is recreated when it is promoted to the pinned overlay, so
    // bring the active tab back into view as soon as it mounts.
    _revealSelected();
  }

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
      height: RestaurantCategoryTabs.height,
      child: Stack(
        children: [
          // Full-width hairline behind the tabs, so the active tab's 2px
          // underline covers it exactly instead of stacking a second line.
          PositionedDirectional(
            start: 0,
            end: 0,
            bottom: 0,
            child: Container(
              height: 1,
              color: AppColors.surfaceContainerHigh,
            ),
          ),
          Positioned.fill(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsetsDirectional.only(
                    end: AppSpacing.md,
                  ),
                  margin: const EdgeInsetsDirectional.only(end: AppSpacing.xs),
                  decoration: const BoxDecoration(
                    border: BorderDirectional(
                      end: BorderSide(
                        color: AppColors.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  child: Tooltip(
                    message: l10n.menuSections,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                      onTap: widget.onOpenMenu,
                      child: const SizedBox(
                        width: 44,
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
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.lg,
                    ),
                    itemCount: widget.categories.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(width: AppSpacing.lg),
                    itemBuilder: (context, index) {
                      final category = widget.categories[index];
                      final selected = category.id == widget.selectedId;
                      return InkWell(
                        key: _tabKeys.putIfAbsent(category.id, GlobalKey.new),
                        onTap: () => widget.onSelected(category.id),
                        child: Container(
                          alignment: AlignmentDirectional.bottomCenter,
                          padding: const EdgeInsetsDirectional.only(
                            bottom: 10,
                          ),
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
                            maxLines: 1,
                            softWrap: false,
                            style: AppTypography.labelLg.copyWith(
                              color: selected
                                  ? AppColors.onSurface
                                  : AppColors.secondary,
                              fontWeight:
                                  selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat strip that carries the category tabs. It is rendered once in the
/// scroll flow right under the meta card, and once as a pinned overlay while
/// the menu scrolls, so the tabs stick below the top bar without reserving a
/// blank gap above them at rest.
class RestaurantTabsBar extends StatelessWidget {
  const RestaurantTabsBar({
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

  /// Gap between the meta card and the tab row from the Stitch mock
  /// (`mt-2` + `pt-3`).
  static const double topPadding = 20;

  /// White breathing room below the row hairline (`pb-1`).
  static const double bottomPadding = 4;

  static const double rowHeight = RestaurantCategoryTabs.height;

  /// Total strip height, including the row's 1px hairline.
  static const double height = topPadding + rowHeight + bottomPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.only(
        top: topPadding,
        bottom: bottomPadding,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
      ),
      child: RestaurantCategoryTabs(
        categories: categories,
        selectedId: selectedId,
        onSelected: onSelected,
        onOpenMenu: onOpenMenu,
      ),
    );
  }
}
