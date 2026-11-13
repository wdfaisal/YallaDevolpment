import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/models/catalog.dart';
import '../../state/home_controller.dart';
import '../../state/session_controller.dart';
import '../shared/meal_launcher.dart';
import 'widgets/home_banner.dart';
import 'widgets/home_best_sellers.dart';
import 'widgets/home_header.dart';
import 'widgets/home_nearby.dart';
import 'widgets/home_offers.dart';
import 'widgets/home_services.dart';

/// Customer home: service strip, banner, exclusive offers, nearby restaurants
/// and best sellers. Every section is hidden when the backend has no real data.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _nearbyGrid = false;

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeProvider);
    return AppScaffold(
      header: const HomeHeader(),
      onRefresh: () => ref.read(homeProvider.notifier).refresh(),
      body: AsyncView<CatalogHome>(
        value: home,
        onRetry: () => ref.invalidate(homeProvider),
        builder: (data) => _buildBody(data),
      ),
    );
  }

  Widget _buildBody(CatalogHome data) {
    final l10n = L10n.of(context);
    final nearby = data.nearby.isNotEmpty ? data.nearby : data.restaurants;
    final hasContent = data.services.isNotEmpty ||
        data.banners.isNotEmpty ||
        data.offers.isNotEmpty ||
        nearby.isNotEmpty ||
        data.bestSellers.isNotEmpty;

    if (!hasContent) {
      final signedIn = ref.watch(isSignedInProvider);
      return EmptyState(
        title: signedIn ? l10n.noRestaurantsNearby : l10n.addAddressToSeeNearby,
        icon: Icons.location_on_outlined,
      );
    }

    final restaurants = <String, CatalogRestaurant>{
      for (final restaurant in data.restaurants) restaurant.id: restaurant,
      for (final restaurant in data.nearby) restaurant.id: restaurant,
    };

    return ListView(
      key: const PageStorageKey<String>('home-scroll'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl),
      children: [
        if (data.services.isNotEmpty)
          HomeServices(services: data.services, onSelected: _selectService),
        if (data.banners.isNotEmpty)
          Padding(
            // Design: px-margin pt-2 mt-1 on the banner wrapper.
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: HomeBanner(
              banners: data.banners,
              onTap: (banner) => _openBanner(banner, data),
            ),
          ),
        if (data.offers.isNotEmpty)
          Padding(
            // Design: mt-space-lg between the banner and the offers section.
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: HomeOffers(
              offers: data.offers,
              restaurants: restaurants,
              onRestaurantTap: _openRestaurant,
              onItemTap: (offer, item) => _openOfferItem(item, restaurants[offer.restaurantId]),
            ),
          ),
        if (nearby.isNotEmpty)
          Padding(
            // Design: mt-1 between the offers strip and the nearby section.
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: HomeNearby(
              restaurants: nearby,
              isGrid: _nearbyGrid,
              onToggleGrid: (isGrid) => setState(() => _nearbyGrid = isGrid),
              onSeeAll: _openAllRestaurants,
              onTap: (restaurant) => _openRestaurant(restaurant.id),
            ),
          ),
        if (data.bestSellers.isNotEmpty)
          Padding(
            // Design: mt-space-lg before the best sellers section.
            padding: const EdgeInsets.only(top: AppSpacing.xxl),
            child: HomeBestSellers(
              items: data.bestSellers,
              onTap: (item) => _openMenuItem(item, restaurants[item.restaurantId]),
              onAdd: (item) => _openMenuItem(item, restaurants[item.restaurantId]),
              onMore: _openAllRestaurants,
            ),
          ),
      ],
    );
  }

  void _selectService(HomeService service) {
    if (service.enabled && service.key == 'food') {
      context.push('/restaurants');
      return;
    }
    showAppSnack(context, L10n.of(context).serviceUnavailable);
  }

  void _openRestaurant(String id) {
    if (id.isEmpty) return;
    context.push('/restaurants/$id');
  }

  void _openAllRestaurants() {
    context.push('/restaurants');
  }

  Future<void> _openMenuItem(CatalogMenuItem item, CatalogRestaurant? restaurant) {
    return openLoadedMeal(
      context,
      item,
      restaurantOpen: restaurant?.isOpen ?? true,
    );
  }

  Future<void> _openOfferItem(CatalogOfferItem item, CatalogRestaurant? restaurant) {
    return openMeal(
      context,
      item.menuItemId,
      restaurantOpen: restaurant?.isOpen ?? true,
    );
  }

  Future<void> _openBanner(CatalogBanner banner, CatalogHome data) async {
    final targetId = banner.targetId;
    switch (banner.targetType) {
      case 'restaurant':
        if (targetId != null && targetId.isNotEmpty) {
          context.push('/restaurants/$targetId');
        }
        break;
      case 'menu_item':
        if (targetId != null && targetId.isNotEmpty) {
          await openMeal(context, targetId);
        }
        break;
      case 'category':
        if (targetId != null && targetId.isNotEmpty) {
          context.push('/restaurants?categoryId=$targetId');
        }
        break;
      case 'offer':
        for (final offer in data.offers) {
          if (offer.id == targetId) {
            _openRestaurant(offer.restaurantId);
            break;
          }
        }
        break;
      case 'external':
        await _openExternal(banner.externalUrl);
        break;
      default:
        break;
    }
  }

  Future<void> _openExternal(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        showAppSnack(context, L10n.of(context).serviceUnavailable, isError: true);
      }
    } catch (_) {
      if (mounted) {
        showAppSnack(context, L10n.of(context).serviceUnavailable, isError: true);
      }
    }
  }
}
