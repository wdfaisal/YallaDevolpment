import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/cart.dart';
import '../../data/models/catalog.dart';
import '../../state/cart_controller.dart';
import '../../state/restaurant_detail_controller.dart';
import '../../state/session_controller.dart';
import '../shared/meal_launcher.dart';
import 'widgets/restaurant_cart_tray.dart';
import 'widgets/restaurant_category_tabs.dart';
import 'widgets/restaurant_hero.dart';
import 'widgets/restaurant_menu_item_card.dart';
import 'widgets/restaurant_menu_sheet.dart';
import 'widgets/restaurant_meta_card.dart';
import 'widgets/restaurant_offers_sheet.dart';

/// Restaurant details & menu rebuilt from the Stitch restaurant design: a flat
/// white surface with hairline separators instead of shadows.
class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  String? _categoryId;
  final Set<String> _busyItems = <String>{};

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final detail = ref.watch(restaurantDetailProvider(widget.restaurantId));
    final cart = ref.watch(cartProvider).valueOrNull;
    final data = detail.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: AsyncView(
        value: detail,
        onRetry: () => ref
            .read(restaurantDetailProvider(widget.restaurantId).notifier)
            .refresh(),
        builder: (detail) => _content(context, l10n, detail, cart),
      ),
      bottomNavigationBar: data == null || cart == null
          ? null
          : RestaurantCartTray(
              cart: cart,
              restaurantId: data.restaurant.id,
              l10n: l10n,
              onCheckout: () => context.push('/cart'),
            ),
    );
  }

  Widget _content(
    BuildContext context,
    L10n l10n,
    CatalogRestaurantDetail detail,
    CartResponse? cart,
  ) {
    final restaurant = detail.restaurant;
    final categories = detail.menu
        .where((category) => category.items.isNotEmpty)
        .toList(growable: false);
    final selectedId = _categoryId != null &&
            categories.any((category) => category.id == _categoryId)
        ? _categoryId
        : (categories.isEmpty ? null : categories.first.id);
    CatalogMenuCategory? selected;
    for (final category in categories) {
      if (category.id == selectedId) {
        selected = category;
        break;
      }
    }
    final items = selected?.items ?? const <CatalogMenuItem>[];
    final topInset = MediaQuery.paddingOf(context).top;

    return RefreshIndicator(
      color: AppColors.primaryContainer,
      onRefresh: () => ref
          .read(restaurantDetailProvider(widget.restaurantId).notifier)
          .refresh(),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header(context, l10n, detail)),
          if (!restaurant.isOpen)
            SliverToBoxAdapter(child: _closedNotice(l10n)),
          if (categories.isNotEmpty)
            SliverPersistentHeader(
              pinned: true,
              delegate: RestaurantTabsHeaderDelegate(
                topInset: topInset,
                child: RestaurantCategoryTabs(
                  categories: categories,
                  selectedId: selectedId,
                  onSelected: (id) => setState(() => _categoryId = id),
                  onOpenMenu: () => _openMenuSheet(
                    context,
                    detail,
                    categories,
                    selectedId,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: _sectionTitle(l10n, selected, items.length),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                title: l10n.emptyState,
                icon: Icons.restaurant_menu,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              sliver: SliverList.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final lines = _linesFor(cart, restaurant.id, item.id);
                  final quantity = lines.fold<int>(
                    0,
                    (sum, line) => sum + line.quantity,
                  );
                  return RestaurantMenuItemCard(
                    item: item,
                    l10n: l10n,
                    quantity: quantity,
                    busy: _busyItems.contains(item.id),
                    enabled: restaurant.isOpen,
                    onTap: () => openLoadedMeal(
                      context,
                      item,
                      restaurantOpen: restaurant.isOpen,
                    ),
                    onIncrement: () =>
                        _increment(context, l10n, restaurant, item),
                    onDecrement: () => _decrement(context, l10n, lines),
                  );
                },
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    L10n l10n,
    CatalogRestaurantDetail detail,
  ) {
    final restaurant = detail.restaurant;
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: RestaurantHero.height,
          child: RestaurantHero(
            restaurantId: restaurant.id,
            imageUrl: restaurant.bannerUrl ?? restaurant.logoUrl,
            onBack: () =>
                context.canPop() ? context.pop() : context.go('/'),
            onShare: () => Share.share(
              '${restaurant.name} — ${l10n.appName}',
              subject: restaurant.name,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            top: RestaurantHero.height - 32,
            start: AppSpacing.lg,
            end: AppSpacing.lg,
          ),
          child: RestaurantMetaCard(
            detail: detail,
            l10n: l10n,
            onOffersTap: detail.offers.isEmpty
                ? null
                : () => showRestaurantOffersSheet(
                      context,
                      offers: detail.offers,
                      onSelect: (offer) => showRestaurantOfferDetail(
                        context,
                        offer: offer,
                        restaurantOpen: restaurant.isOpen,
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _closedNotice(L10n l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.schedule,
              size: 18,
              color: AppColors.error,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                l10n.restaurantClosedNotice,
                style: AppTypography.bodySm.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(
    L10n l10n,
    CatalogMenuCategory? category,
    int itemCount,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    category?.name ?? l10n.menu,
                    style: AppTypography.headlineMd,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            l10n.menuItemsCount(itemCount),
            style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  List<CartLine> _linesFor(
    CartResponse? cart,
    String restaurantId,
    String menuItemId,
  ) {
    if (cart == null || cart.restaurantId != restaurantId) {
      return const <CartLine>[];
    }
    return cart.lines
        .where((line) => line.menuItemId == menuItemId)
        .toList(growable: false);
  }

  Future<void> _openMenuSheet(
    BuildContext context,
    CatalogRestaurantDetail detail,
    List<CatalogMenuCategory> categories,
    String? selectedId,
  ) {
    return showRestaurantMenuSheet(
      context,
      categories: categories,
      selectedId: selectedId,
      onSelect: (id) {
        if (mounted) setState(() => _categoryId = id);
      },
      onOpenItem: (item) => openLoadedMeal(
        context,
        item,
        restaurantOpen: detail.restaurant.isOpen,
      ),
    );
  }

  Future<void> _increment(
    BuildContext context,
    L10n l10n,
    CatalogRestaurant restaurant,
    CatalogMenuItem item,
  ) async {
    if (_busyItems.contains(item.id)) return;
    if (!restaurant.isOpen) {
      showAppSnack(context, l10n.restaurantClosedNotice, isError: true);
      return;
    }
    if (item.hasOptions) {
      await openLoadedMeal(context, item, restaurantOpen: true);
      return;
    }
    if (ref.read(sessionProvider).valueOrNull == null) {
      context.push('/login?next=/restaurants/${widget.restaurantId}');
      return;
    }
    setState(() => _busyItems.add(item.id));
    try {
      await ref
          .read(cartProvider.notifier)
          .addItem(menuItemId: item.id, quantity: 1);
      if (!context.mounted) return;
      showAppSnack(context, l10n.addedToCart);
    } on ApiException catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, error.message, isError: true);
    } catch (_) {
      if (!context.mounted) return;
      showAppSnack(context, l10n.somethingWentWrong, isError: true);
    } finally {
      if (mounted) setState(() => _busyItems.remove(item.id));
    }
  }

  Future<void> _decrement(
    BuildContext context,
    L10n l10n,
    List<CartLine> lines,
  ) async {
    if (lines.isEmpty) return;
    final line = lines.last;
    if (_busyItems.contains(line.menuItemId)) return;
    setState(() => _busyItems.add(line.menuItemId));
    try {
      await ref
          .read(cartProvider.notifier)
          .changeQuantity(line, line.quantity - 1);
    } on ApiException catch (error) {
      if (!context.mounted) return;
      showAppSnack(context, error.message, isError: true);
    } catch (_) {
      if (!context.mounted) return;
      showAppSnack(context, l10n.somethingWentWrong, isError: true);
    } finally {
      if (mounted) setState(() => _busyItems.remove(line.menuItemId));
    }
  }
}
