import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import '../../data/models/search.dart';
import '../../state/search_controller.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';
import '../shared/meal_launcher.dart';
import '../shared/menu_widgets.dart';
import '../shared/restaurant_widgets.dart';

/// Search screen (Stitch screen 4). Suggestions are fetched while typing
/// (debounced); a full result set is only requested when the customer submits.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key, this.initialQuery});

  final String? initialQuery;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialQuery?.trim() ?? '';
    if (initial.isNotEmpty) _controller.text = initial;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(searchProvider.notifier);
      notifier.ensureInitialised();
      if (initial.isNotEmpty) notifier.submit(initial);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    _controller.text = trimmed;
    _controller.selection = TextSelection.collapsed(offset: trimmed.length);
    _focusNode.unfocus();
    ref.read(searchProvider.notifier).submit(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final state = ref.watch(searchProvider);
    return AppScaffold(
      header: SimpleHeader(title: l10n.search, onBack: () => context.pop()),
      body: Column(
        children: [
          _SearchBar(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: ref.read(searchProvider.notifier).onQueryChanged,
            onSubmitted: _submit,
            onClear: () {
              _controller.clear();
              ref.read(searchProvider.notifier).clearQuery();
              _focusNode.requestFocus();
            },
            onFilter: () => context.push('/restaurants'),
          ),
          Expanded(child: _content(context, l10n, state)),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, L10n l10n, SearchState state) {
    if (state.hasSearched) return _results(context, l10n, state);

    final query = state.query.trim();
    if (query.length >= state.minQueryLength) {
      return _suggestions(context, l10n, state);
    }

    if (query.isNotEmpty) {
      return EmptyState(
        title: l10n.startTyping,
        message: l10n.minCharsHint,
        icon: Icons.keyboard_outlined,
      );
    }

    return _history(context, l10n, state);
  }

  Widget _history(BuildContext context, L10n l10n, SearchState state) {
    final signedIn = ref.watch(isSignedInProvider);
    if (!signedIn) {
      return EmptyState(
        title: l10n.search,
        message: l10n.searchHint,
        icon: Icons.search,
      );
    }
    if (state.history.isEmpty) {
      return EmptyState(
        title: l10n.recentSearches,
        message: l10n.startTyping,
        icon: Icons.history,
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xs,
          ),
          child: Row(
            children: [
              const Icon(Icons.history, size: 18, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(l10n.recentSearches, style: AppTypography.headlineSm),
              ),
              TextButton(
                onPressed: () => ref.read(searchProvider.notifier).clearHistory(),
                child: Text(
                  l10n.clearHistory,
                  style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
        for (final item in state.history)
          _HistoryTile(
            item: item,
            isArabic: l10n.isArabic,
            onSelect: () => _submit(item.query),
            onDelete: () => ref.read(searchProvider.notifier).deleteHistoryItem(item.id),
          ),
      ],
    );
  }

  Widget _suggestions(BuildContext context, L10n l10n, SearchState state) {
    if (state.suggesting && state.suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: LoadingState(),
      );
    }
    if (state.suggestions.isEmpty) {
      return EmptyState(
        title: l10n.noResults,
        message: l10n.searchHint,
        icon: Icons.search_off,
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Text(l10n.suggestions, style: AppTypography.headlineSm),
        ),
        for (final suggestion in state.suggestions)
          ListTile(
            leading: Icon(
              switch (suggestion.kind) {
                'restaurant' => Icons.storefront_outlined,
                'menu_item' => Icons.restaurant_menu,
                _ => Icons.search,
              },
              color: AppColors.primary,
            ),
            title: Text(suggestion.text, style: AppTypography.bodyLg),
            subtitle: Text(
              switch (suggestion.kind) {
                'restaurant' => l10n.food,
                'menu_item' => l10n.dishes,
                _ => l10n.search,
              },
              style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
            ),
            trailing: const Icon(Icons.north_west, size: 18, color: AppColors.secondary),
            onTap: () => _openSuggestion(context, suggestion),
          ),
      ],
    );
  }

  Future<void> _openSuggestion(BuildContext context, SearchSuggestion suggestion) async {
    final notifier = ref.read(searchProvider.notifier);
    if (suggestion.isRestaurant && suggestion.targetId != null) {
      await notifier.recordClick(targetType: 'restaurant', targetId: suggestion.targetId!);
      if (!context.mounted) return;
      context.push('/restaurants/${suggestion.targetId}');
      return;
    }
    if (suggestion.isMenuItem && suggestion.targetId != null) {
      await notifier.recordClick(targetType: 'menu_item', targetId: suggestion.targetId!);
      if (!context.mounted) return;
      openMeal(context, suggestion.targetId!);
      return;
    }
    _submit(suggestion.text);
  }

  Widget _results(BuildContext context, L10n l10n, SearchState state) {
    if (state.searching && state.results == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: LoadingState(),
      );
    }
    if (state.error != null) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(searchProvider.notifier).submit(),
      );
    }
    final results = state.results;
    if (results == null) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: LoadingState(),
      );
    }
    if (results.isEmpty) {
      return EmptyState(
        title: l10n.noResults,
        message: '${l10n.search}: ${results.query}',
        icon: Icons.search_off,
        actionLabel: l10n.allRestaurants,
        onAction: () => context.push('/restaurants'),
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (state.searching) const LinearProgressIndicator(minHeight: 2),
        if (results.restaurants.isNotEmpty) ...[
          SectionHeader(
            title: l10n.food,
            trailing: Text(
              '${results.meta.total}',
              style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final restaurant in results.restaurants)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: RestaurantListCard(
                restaurant: restaurant,
                onTap: () {
                  ref.read(searchProvider.notifier).recordClick(
                        targetType: 'restaurant',
                        targetId: restaurant.id,
                      );
                  context.push('/restaurants/${restaurant.id}');
                },
              ),
            ),
        ],
        if (results.items.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionHeader(
            title: l10n.dishes,
            trailing: Text(
              '${results.items.length}',
              style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final item in results.items)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: MenuItemRow(
                item: item,
                onTap: () {
                  ref.read(searchProvider.notifier).recordClick(
                        targetType: 'menu_item',
                        targetId: item.id,
                      );
                  openLoadedMeal(context, item);
                },
                onAdd: () {
                  ref.read(searchProvider.notifier).recordClick(
                        targetType: 'menu_item',
                        targetId: item.id,
                      );
                  openLoadedMeal(context, item);
                },
                showFavorite: true,
              ),
            ),
        ],
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onFilter,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final VoidCallback onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerLow)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 22, color: AppColors.secondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      onChanged: onChanged,
                      onSubmitted: onSubmitted,
                      style: AppTypography.bodyLg,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        hintStyle: AppTypography.bodyMd.copyWith(
                          color: AppColors.secondary,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      if (value.text.isEmpty) return const SizedBox.shrink();
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: onClear,
                        child: Tooltip(
                          message: l10n.clearSearch,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: AppColors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.orangeTintSubtle,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              onTap: onFilter,
              child: Tooltip(
                message: l10n.filters,
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: const Icon(Icons.tune, color: AppColors.primary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.item,
    required this.isArabic,
    required this.onSelect,
    required this.onDelete,
  });

  final SearchHistoryItem item;
  final bool isArabic;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.schedule, size: 18, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.query,
                    style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    Fmt.relative(item.createdAt, isArabic: isArabic),
                    style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: AppColors.secondary,
              tooltip: L10n.of(context).clearSearch,
              onPressed: onDelete,
            ),
            const Icon(Icons.north_west, size: 18, color: AppColors.secondary),
          ],
        ),
      ),
    );
  }
}
