import 'package:flutter/material.dart';

import '../../../core/design/app_colors.dart';
import '../../../core/design/app_spacing.dart';
import '../../../core/design/app_typography.dart';
import '../../../core/formatting/formatters.dart';
import '../../../core/localization/l10n.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/snack.dart';
import '../../../core/widgets/states.dart';
import '../../../data/models/catalog.dart';

/// Bottom sheet opened by the leading menu button. It replaces the removed
/// search bar from the old screen: browse sections or search every dish.
Future<void> showRestaurantMenuSheet(
  BuildContext context, {
  required List<CatalogMenuCategory> categories,
  required String? selectedId,
  required ValueChanged<String> onSelect,
  required ValueChanged<CatalogMenuItem> onOpenItem,
}) {
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
    builder: (sheetContext) => _MenuSheet(
      categories: categories,
      selectedId: selectedId,
      onSelect: onSelect,
      onOpenItem: onOpenItem,
    ),
  );
}

class _MenuSheet extends StatefulWidget {
  const _MenuSheet({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
    required this.onOpenItem,
  });

  final List<CatalogMenuCategory> categories;
  final String? selectedId;
  final ValueChanged<String> onSelect;
  final ValueChanged<CatalogMenuItem> onOpenItem;

  @override
  State<_MenuSheet> createState() => _MenuSheetState();
}

class _MenuSheetState extends State<_MenuSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  void _select(String categoryId) {
    _close();
    widget.onSelect(categoryId);
  }

  void _openItem(CatalogMenuItem item) {
    _close();
    widget.onOpenItem(item);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final media = MediaQuery.of(context);
    final query = _query.trim().toLowerCase();
    final results = <_MenuSearchResult>[];
    if (query.isNotEmpty) {
      for (final category in widget.categories) {
        for (final item in category.items) {
          if (item.name.toLowerCase().contains(query) ||
              item.description.toLowerCase().contains(query)) {
            results.add(_MenuSearchResult(category: category, item: item));
          }
        }
      }
    }

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.85,
        child: Column(
          children: [
            SheetHeader(title: l10n.menu, onClose: _close),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _search,
                onChanged: (value) => setState(() => _query = value),
                style: AppTypography.bodyMd,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchMenuHint,
                  hintStyle: AppTypography.bodySm.copyWith(
                    color: AppColors.secondary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.secondary,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.clearSearch,
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: query.isEmpty
                  ? _categories(l10n)
                  : (results.isEmpty
                      ? EmptyState(
                          title: l10n.noResults,
                          icon: Icons.search_off,
                        )
                      : _results(l10n, results)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categories(L10n l10n) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: widget.categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final category = widget.categories[index];
        final selected = category.id == widget.selectedId;
        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _select(category.id),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.orangeTintSubtle
                  : AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: selected
                    ? AppColors.primaryFixedDim
                    : AppColors.surfaceContainerHigh,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.orangeTintSoft,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: AppTypography.labelLg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.itemCountShort(category.items.length),
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _results(L10n l10n, List<_MenuSearchResult> results) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: results.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        color: AppColors.surfaceContainerLow,
      ),
      itemBuilder: (context, index) {
        final result = results[index];
        final item = result.item;
        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () => _openItem(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                AppImage(
                  url: item.imageUrl,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  backgroundColor: AppColors.surfaceContainer,
                  icon: Icons.fastfood_outlined,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: AppTypography.labelLg,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.category.name,
                        style: AppTypography.bodySm.copyWith(
                          color: AppColors.secondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  Fmt.money(
                    item.priceMinor,
                    currency: l10n.currencyDefault,
                  ),
                  style: AppTypography.labelLg.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MenuSearchResult {
  const _MenuSearchResult({required this.category, required this.item});

  final CatalogMenuCategory category;
  final CatalogMenuItem item;
}
