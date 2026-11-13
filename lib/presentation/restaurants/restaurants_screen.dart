import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/states.dart';
import '../../data/models/catalog.dart';
import '../../data/models/search.dart';
import '../../presentation/shared/headers.dart';
import '../../presentation/shared/restaurant_widgets.dart';
import '../../presentation/shared/sheets.dart';
import '../../state/providers.dart';
import '../../state/restaurants_controller.dart';

final catalogCategoriesProvider = FutureProvider<List<CatalogCategory>>(
  (ref) => ref.read(catalogRepositoryProvider).categories(),
);

class RestaurantsScreen extends ConsumerStatefulWidget {
  const RestaurantsScreen({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  ConsumerState<RestaurantsScreen> createState() => _RestaurantsScreenState();
}

class _RestaurantsScreenState extends ConsumerState<RestaurantsScreen> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  bool _grid = false;

  String? get _categoryArg => widget.initialCategoryId;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _search.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      ref.read(restaurantsProvider(_categoryArg).notifier).loadMore();
    }
  }

  void _apply(RestaurantQuery query) {
    ref.read(restaurantsProvider(_categoryArg).notifier).applyFilters(query);
  }

  void _submitSearch(RestaurantListState state) {
    final text = _search.text.trim();
    _apply(
      text.isEmpty
          ? state.query.copyWith(clearSearch: true)
          : state.query.copyWith(search: text),
    );
  }

  void _toggleCategory(RestaurantListState state, String id) {
    final selected = List<String>.from(state.query.categoryIds);
    if (selected.contains(id)) {
      selected.remove(id);
    } else {
      selected.add(id);
    }
    _apply(state.query.copyWith(categoryIds: selected));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final provider = restaurantsProvider(_categoryArg);
    final value = ref.watch(provider);
    return AppScaffold(
      header: _Header(
        search: _search,
        onSearch: () {
          final state = value.valueOrNull;
          if (state != null) _submitSearch(state);
        },
        onClearSearch: () {
          _search.clear();
          final state = value.valueOrNull;
          if (state != null) _submitSearch(state);
        },
      ),
      onRefresh: () => ref.read(provider.notifier).refresh(),
      body: AsyncView(
        value: value,
        onRetry: () => ref.invalidate(provider),
        loading: const _ListSkeleton(),
        builder: (state) => _body(state, l10n),
      ),
    );
  }

  Widget _body(RestaurantListState state, L10n l10n) {
    return NotificationListener<ScrollNotification>(
      onNotification: (_) => false,
      child: ListView(
        controller: _scroll,
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          _categories(state, l10n),
          if (state.items.isNotEmpty) _brands(state),
          _sortBar(state, l10n),
          if (state.items.isEmpty)
            EmptyState(
              title: l10n.noResults,
              icon: Icons.search_off,
              actionLabel: state.query.hasFilters ? l10n.resetFilters : null,
              onAction: state.query.hasFilters
                  ? () => ref.read(restaurantsProvider(_categoryArg).notifier).clearFilters()
                  : null,
            )
          else if (_grid)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.72,
                ),
                itemBuilder: (context, index) {
                  final restaurant = state.items[index];
                  return RestaurantGridCard(
                    restaurant: restaurant,
                    showShadow: false,
                    onTap: () => context.push('/restaurants/${restaurant.id}'),
                  );
                },
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  for (var i = 0; i < state.items.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    RestaurantListCard(
                      restaurant: state.items[i],
                      showShadow: false,
                      onTap: () => context.push('/restaurants/${state.items[i].id}'),
                    ),
                  ],
                ],
              ),
            ),
          if (state.loadingMore)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categories(RestaurantListState state, L10n l10n) {
    final categories = ref.watch(catalogCategoriesProvider);
    final arabic = l10n.isArabic;
    return categories.maybeWhen(
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: [
                    Expanded(child: Text(l10n.categories, style: AppTypography.headlineSm)),
                    if (state.query.categoryIds.isNotEmpty)
                      TextButton(
                        onPressed: () =>
                            _apply(state.query.copyWith(categoryIds: const [])),
                        child: Text(l10n.resetFilters),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final category = list[index];
                    final selected = state.query.categoryIds.contains(category.id);
                    return InkWell(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      onTap: () => _toggleCategory(state, category.id),
                      child: SizedBox(
                        width: 72,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                border: Border.all(
                                  color: selected ? AppColors.primary : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: AppImage(
                                url: category.imageUrl,
                                width: 60,
                                height: 60,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                icon: Icons.category_outlined,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              category.name(arabic),
                              style: AppTypography.labelSm.copyWith(
                                color: selected ? AppColors.primary : AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
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
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _brands(RestaurantListState state) {
    final items = state.items.take(8).toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: L10n.of(context).topBrands),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final restaurant = items[index];
                return RestaurantBrandTile(
                  restaurant: restaurant,
                  onTap: () => context.push('/restaurants/${restaurant.id}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sortBar(RestaurantListState state, L10n l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            onTap: () => _pickSort(state, l10n),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _sortLabel(state.query.sort, l10n),
                    style: AppTypography.labelMd,
                  ),
                  const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primary),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            onTap: () => _openFilters(state, l10n),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: state.query.hasFilters
                    ? AppColors.orangeTintSubtle
                    : AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                border: Border.all(
                  color: state.query.hasFilters ? AppColors.primary : AppColors.surfaceContainerHigh,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune,
                    size: 15,
                    color: state.query.hasFilters ? AppColors.primary : AppColors.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.filters,
                    style: AppTypography.labelMd.copyWith(
                      color: state.query.hasFilters ? AppColors.primary : AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${state.total}',
            style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
          ),
          const SizedBox(width: AppSpacing.sm),
          _ViewToggle(
            grid: _grid,
            onChanged: (value) => setState(() => _grid = value),
          ),
        ],
      ),
    );
  }

  String _sortLabel(String sort, L10n l10n) => switch (sort) {
        'rating' => l10n.sortRating,
        'distance' => l10n.sortDistance,
        'popular' => l10n.sortPopular,
        'fastest' => l10n.sortFastest,
        'lowest_fee' => l10n.sortLowestFee,
        'newest' => l10n.sortNewest,
        _ => l10n.sortRecommended,
      };

  Future<void> _pickSort(RestaurantListState state, L10n l10n) async {
    final options = state.availableSorts.isEmpty ? const ['recommended'] : state.availableSorts;
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(l10n.sortBy, style: AppTypography.headlineSm),
            ),
            for (final option in options)
              ListTile(
                title: Text(_sortLabel(option, l10n)),
                trailing: option == state.query.sort
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(option),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (selected != null && selected != state.query.sort) {
      await ref.read(restaurantsProvider(_categoryArg).notifier).setSort(selected);
    }
  }

  Future<void> _openFilters(RestaurantListState state, L10n l10n) async {
    final result = await showModalBottomSheet<RestaurantQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _FilterSheet(initial: state.query),
    );
    if (result != null) _apply(result);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.search,
    required this.onSearch,
    required this.onClearSearch,
  });

  final TextEditingController search;
  final VoidCallback onSearch;
  final VoidCallback onClearSearch;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Container(
      color: AppColors.surfaceContainerLowest,
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
      child: Column(
        children: [
          Row(
            children: [
              HeaderIconButton(
                icon: Icons.arrow_forward,
                tooltip: l10n.back,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Expanded(child: AddressChip(compact: true)),
              HeaderIconButton(
                icon: Icons.search,
                tooltip: l10n.search,
                onTap: () => context.push('/search'),
              ),
              const SizedBox(width: AppSpacing.xs),
              const CartHeaderButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: search,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: search,
                builder: (context, value, _) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: l10n.clearSearch,
                    onPressed: onClearSearch,
                  );
                },
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.grid, required this.onChanged});

  final bool grid;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.surfaceContainerHigh),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggle(Icons.view_agenda_outlined, !grid, () => onChanged(false)),
          _toggle(Icons.grid_view, grid, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _toggle(IconData icon, bool active, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: active ? AppColors.surfaceContainerLow : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
        ),
        child: Icon(icon, size: 17, color: active ? AppColors.primary : AppColors.secondary),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.initial});

  final RestaurantQuery initial;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late bool _openNow = widget.initial.openNow ?? false;
  late bool _freeDelivery = widget.initial.freeDelivery ?? false;
  late bool _hasOffers = widget.initial.hasOffers ?? false;
  late double? _minRating = widget.initial.minRating;
  late double? _maxDistance = widget.initial.maxDistanceKm;
  late int? _maxMinutes = widget.initial.maxDeliveryMinutes;
  late int? _maxFee = widget.initial.maxDeliveryFeeMinor;
  late int? _maxMinOrder = widget.initial.maxMinOrderMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: Text(l10n.filters, style: AppTypography.headlineSm)),
                  TextButton(
                    onPressed: _reset,
                    child: Text(l10n.resetFilters),
                  ),
                ],
              ),
              _section(l10n.openNow, [
                AppChoiceChip(
                  label: l10n.openNow,
                  selected: _openNow,
                  icon: Icons.schedule,
                  onTap: () => setState(() => _openNow = !_openNow),
                ),
                AppChoiceChip(
                  label: l10n.freeDelivery,
                  selected: _freeDelivery,
                  icon: Icons.delivery_dining,
                  onTap: () => setState(() => _freeDelivery = !_freeDelivery),
                ),
                AppChoiceChip(
                  label: l10n.hasOffers,
                  selected: _hasOffers,
                  icon: Icons.local_offer_outlined,
                  onTap: () => setState(() => _hasOffers = !_hasOffers),
                ),
              ]),
              _section(l10n.rating, [
                _choice('4.0+', _minRating == 4.0, () => _setRating(4.0)),
                _choice('4.5+', _minRating == 4.5, () => _setRating(4.5)),
                _choice(l10n.any, _minRating == null, () => _setRating(null)),
              ]),
              _section(l10n.distance, [
                _choice('2 km', _maxDistance == 2, () => _setDistance(2)),
                _choice('5 km', _maxDistance == 5, () => _setDistance(5)),
                _choice('10 km', _maxDistance == 10, () => _setDistance(10)),
                _choice(l10n.any, _maxDistance == null, () => _setDistance(null)),
              ]),
              _section(l10n.deliveryTime, [
                _choice('30 ${l10n.minuteShort}', _maxMinutes == 30, () => _setMinutes(30)),
                _choice('45 ${l10n.minuteShort}', _maxMinutes == 45, () => _setMinutes(45)),
                _choice('60 ${l10n.minuteShort}', _maxMinutes == 60, () => _setMinutes(60)),
                _choice(l10n.any, _maxMinutes == null, () => _setMinutes(null)),
              ]),
              _section(l10n.deliveryFee, [
                _choice(l10n.deliveryFeeFree, _maxFee == 0, () => _setFee(0)),
                _choice('≤ 5', _maxFee == 500, () => _setFee(500)),
                _choice('≤ 10', _maxFee == 1000, () => _setFee(1000)),
                _choice(l10n.any, _maxFee == null, () => _setFee(null)),
              ]),
              _section(l10n.minimumOrder, [
                _choice('≤ 20', _maxMinOrder == 2000, () => _setMinOrder(2000)),
                _choice('≤ 30', _maxMinOrder == 3000, () => _setMinOrder(3000)),
                _choice('≤ 50', _maxMinOrder == 5000, () => _setMinOrder(5000)),
                _choice(l10n.any, _maxMinOrder == null, () => _setMinOrder(null)),
              ]),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_build()),
                  child: Text(l10n.applyFilters),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.labelLg),
          const SizedBox(height: AppSpacing.sm),
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: children),
        ],
      ),
    );
  }

  Widget _choice(String label, bool selected, VoidCallback onTap) {
    return AppChoiceChip(label: label, selected: selected, onTap: onTap);
  }

  void _setRating(double? value) => setState(() => _minRating = value);
  void _setDistance(double? value) => setState(() => _maxDistance = value);
  void _setMinutes(int? value) => setState(() => _maxMinutes = value);
  void _setFee(int? value) => setState(() => _maxFee = value);
  void _setMinOrder(int? value) => setState(() => _maxMinOrder = value);

  void _reset() {
    setState(() {
      _openNow = false;
      _freeDelivery = false;
      _hasOffers = false;
      _minRating = null;
      _maxDistance = null;
      _maxMinutes = null;
      _maxFee = null;
      _maxMinOrder = null;
    });
  }

  RestaurantQuery _build() {
    return widget.initial.copyWith(
      openNow: _openNow ? true : null,
      clearOpenNow: !_openNow,
      freeDelivery: _freeDelivery ? true : null,
      clearFreeDelivery: !_freeDelivery,
      hasOffers: _hasOffers ? true : null,
      clearHasOffers: !_hasOffers,
      minRating: _minRating,
      clearRating: _minRating == null,
      maxDistanceKm: _maxDistance,
      clearDistance: _maxDistance == null,
      maxDeliveryMinutes: _maxMinutes,
      clearDeliveryMinutes: _maxMinutes == null,
      maxDeliveryFeeMinor: _maxFee,
      clearMaxFee: _maxFee == null,
      maxMinOrderMinor: _maxMinOrder,
      clearMinOrder: _maxMinOrder == null,
    );
  }
}

class _ListSkeleton extends StatelessWidget {
  const _ListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: const [
        SkeletonBox(height: 96, radius: 16),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 112, radius: 16),
        SizedBox(height: AppSpacing.lg),
        SkeletonBox(height: 120, radius: 16),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 120, radius: 16),
        SizedBox(height: AppSpacing.md),
        SkeletonBox(height: 120, radius: 16),
      ],
    );
  }
}
