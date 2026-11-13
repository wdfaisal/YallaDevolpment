import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/states.dart';
import '../../data/models/account.dart';
import '../../state/favorites_controller.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';
import '../shared/meal_launcher.dart';
import '../shared/menu_widgets.dart';
import '../shared/restaurant_widgets.dart';

/// Favorites tab: saved restaurants and dishes from the backend.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final favorites = ref.watch(favoritesProvider);

    return AppScaffold(
      header: SimpleHeader(
        title: l10n.favorites,
        showBack: false,
        actions: const [CartHeaderButton()],
      ),
      onRefresh: signedIn
          ? () => ref.read(favoritesProvider.notifier).refresh()
          : null,
      body: !signedIn
          ? EmptyState(
              title: l10n.noFavorites,
              message: l10n.notAuthorized,
              icon: Icons.favorite_border,
              actionLabel: l10n.signIn,
              onAction: () => context.push('/login?next=/favorites'),
            )
          : AsyncView(
              value: favorites,
              onRetry: () => ref.read(favoritesProvider.notifier).refresh(),
              builder: (records) {
                final restaurants =
                    records.where((r) => r.restaurant != null).toList(growable: false);
                final items =
                    records.where((r) => r.menuItem != null).toList(growable: false);
                return Column(
                  children: [
                    _Tabs(
                      firstLabel: l10n.food,
                      secondLabel: l10n.dishes,
                      firstCount: restaurants.length,
                      secondCount: items.length,
                      selected: _tab,
                      onSelect: (value) => setState(() => _tab = value),
                    ),
                    Expanded(
                      child: _tab == 0
                          ? _restaurantList(l10n, restaurants)
                          : _itemList(l10n, items),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _restaurantList(L10n l10n, List<FavoriteRecord> records) {
    if (records.isEmpty) {
      return EmptyState(
        title: l10n.noFavoriteRestaurants,
        icon: Icons.storefront_outlined,
        actionLabel: l10n.browseRestaurants,
        onAction: () => context.push('/restaurants'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final restaurant = records[index].restaurant!;
        return RestaurantListCard(
          restaurant: restaurant,
          onTap: () => context.push('/restaurants/${restaurant.id}'),
        );
      },
    );
  }

  Widget _itemList(L10n l10n, List<FavoriteRecord> records) {
    if (records.isEmpty) {
      return EmptyState(
        title: l10n.noFavoriteItems,
        icon: Icons.restaurant_menu,
        actionLabel: l10n.browseRestaurants,
        onAction: () => context.push('/restaurants'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = records[index].menuItem!;
        return MenuItemRow(
          item: item,
          showFavorite: true,
          onTap: () => openLoadedMeal(context, item),
          onAdd: () => openLoadedMeal(context, item),
        );
      },
    );
  }
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.firstLabel,
    required this.secondLabel,
    required this.firstCount,
    required this.secondCount,
    required this.selected,
    required this.onSelect,
  });

  final String firstLabel;
  final String secondLabel;
  final int firstCount;
  final int secondCount;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        children: [
          _tab(0, firstLabel, firstCount),
          _tab(1, secondLabel, secondCount),
        ],
      ),
    );
  }

  Widget _tab(int index, String label, int count) {
    final active = selected == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        onTap: () => onSelect(index),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: active ? AppColors.cardShadow : null,
          ),
          child: Text(
            '$label ($count)',
            style: AppTypography.labelMd.copyWith(
              color: active ? AppColors.primary : AppColors.secondary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
