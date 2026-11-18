import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/flat_empty_state.dart';
import '../../core/widgets/states.dart';
import '../../data/models/account.dart';
import '../../state/favorites_controller.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';
import '../shared/meal_launcher.dart';
import '../shared/segmented_tabs.dart';
import 'widgets/favorite_dish_card.dart';
import 'widgets/favorite_restaurant_card.dart';

/// Favorites tab: saved restaurants and dishes from the backend, laid out the
/// same way as My Orders — subtitle header, flat segmented pills, hairline
/// cards and one compact outlined action per card.
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
        subtitle: l10n.favoritesSubtitle,
        showBack: false,
        actions: const [CartHeaderButton()],
      ),
      onRefresh: signedIn
          ? () => ref.read(favoritesProvider.notifier).refresh()
          : null,
      body: !signedIn
          ? FlatEmptyState(
              title: l10n.noFavorites,
              message: l10n.favoritesGuestMessage,
              icon: Icons.favorite_border,
              actionLabel: l10n.signIn,
              actionIcon: Icons.login,
              onAction: () => context.push('/login?next=/favorites'),
            )
          : AsyncView(
              value: favorites,
              onRetry: () => ref.read(favoritesProvider.notifier).refresh(),
              loading: const _FavoritesSkeleton(),
              builder: (records) {
                final restaurants = records
                    .where((r) => r.restaurant != null)
                    .toList(growable: false);
                final items = records
                    .where((r) => r.menuItem != null)
                    .toList(growable: false);
                return Column(
                  children: [
                    SegmentedTabs(
                      items: [
                        SegmentedTabItem(
                          label: l10n.food,
                          count: restaurants.length,
                        ),
                        SegmentedTabItem(
                          label: l10n.dishes,
                          count: items.length,
                        ),
                      ],
                      selectedIndex: _tab,
                      onSelect: (index) => setState(() => _tab = index),
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
      return FlatEmptyState(
        title: l10n.favoriteRestaurantsTitle,
        message: l10n.noFavoriteRestaurants,
        icon: Icons.storefront_outlined,
        actionLabel: l10n.browseRestaurants,
        onAction: () => context.push('/restaurants'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final restaurant = records[index].restaurant!;
        void openRestaurant() => context.push('/restaurants/${restaurant.id}');
        return FavoriteRestaurantCard(
          restaurant: restaurant,
          onTap: openRestaurant,
          onOpenMenu: openRestaurant,
        );
      },
    );
  }

  Widget _itemList(L10n l10n, List<FavoriteRecord> records) {
    if (records.isEmpty) {
      return FlatEmptyState(
        title: l10n.favoriteItemsTitle,
        message: l10n.noFavoriteItems,
        icon: Icons.restaurant_menu,
        actionLabel: l10n.browseRestaurants,
        onAction: () => context.push('/restaurants'),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      itemCount: records.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final item = records[index].menuItem!;
        void openDish() => openLoadedMeal(context, item);
        return FavoriteDishCard(
          item: item,
          onTap: openDish,
          onView: openDish,
        );
      },
    );
  }
}

/// Placeholder cards that keep the list layout stable while favorites load.
class _FavoritesSkeleton extends StatelessWidget {
  const _FavoritesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.md,
        AppSpacing.gutter,
        AppSpacing.xxxl,
      ),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.all(AppSpacing.md + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.borderHairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(width: 64, height: 64, radius: 12),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 140, height: 12),
                      SizedBox(height: 8),
                      SkeletonBox(width: 96, height: 10),
                      SizedBox(height: 10),
                      SkeletonBox(width: 72, height: 10),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const SkeletonBox(height: 1, radius: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: const [
                SkeletonBox(width: 72, height: 10),
                Spacer(),
                SkeletonBox(width: 132, height: 38, radius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
