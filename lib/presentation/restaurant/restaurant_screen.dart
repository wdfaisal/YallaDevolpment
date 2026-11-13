import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/price_text.dart';
import '../../core/widgets/rating_badge.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/models/cart.dart';
import '../../data/models/catalog.dart';
import '../../state/cart_controller.dart';
import '../../state/restaurant_detail_controller.dart';
import '../shared/meal_launcher.dart';
import '../shared/menu_widgets.dart';
import '../shared/restaurant_widgets.dart';

/// Restaurant details & menu (Stitch screen 5).
class RestaurantScreen extends ConsumerStatefulWidget {
  const RestaurantScreen({super.key, required this.restaurantId});

  final String restaurantId;

  @override
  ConsumerState<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends ConsumerState<RestaurantScreen> {
  final _menuSearch = TextEditingController();
  String _query = '';
  String? _categoryId;

  @override
  void dispose() {
    _menuSearch.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final detail = ref.watch(restaurantDetailProvider(widget.restaurantId));
    final cart = ref.watch(cartProvider).valueOrNull;
    final restaurantId = detail.valueOrNull?.restaurant.id;
    final trayVisible =
        cart != null && cart.lines.isNotEmpty && cart.restaurantId == restaurantId;

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      body: AsyncView(
        value: detail,
        onRetry: () => ref
            .read(restaurantDetailProvider(widget.restaurantId).notifier)
            .refresh(),
        builder: (data) => _content(context, l10n, data),
      ),
      bottomNavigationBar: trayVisible
          ? _CartTray(cart: cart, l10n: l10n)
          : null,
    );
  }

  Widget _content(BuildContext context, L10n l10n, CatalogRestaurantDetail detail) {
    final restaurant = detail.restaurant;
    final categories = detail.menu.where((c) => c.items.isNotEmpty).toList(growable: false);
    final selectedId = _categoryId != null &&
            categories.any((c) => c.id == _categoryId)
        ? _categoryId
        : (categories.isEmpty ? null : categories.first.id);
    CatalogMenuCategory? selected;
    for (final category in categories) {
      if (category.id == selectedId) {
        selected = category;
        break;
      }
    }
    final query = _query.trim().toLowerCase();
    final items = selected == null
        ? const <CatalogMenuItem>[]
        : (query.isEmpty
            ? selected.items
            : selected.items
                .where(
                  (item) =>
                      item.name.toLowerCase().contains(query) ||
                      item.description.toLowerCase().contains(query),
                )
                .toList(growable: false));

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _hero(context, l10n, detail)),
            SliverToBoxAdapter(child: _meta(l10n, detail)),
            if (!restaurant.isOpen)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _Notice(
                    icon: Icons.schedule,
                    color: AppColors.error,
                    text: l10n.restaurantClosedNotice,
                  ),
                ),
              ),
            if (detail.offers.isNotEmpty)
              SliverToBoxAdapter(child: _offers(context, l10n, detail)),
            SliverToBoxAdapter(child: _menuSearchBar(l10n)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _TabsDelegate(
                height: 50,
                child: _categoryTabs(l10n, categories, selectedId),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        selected?.name ?? l10n.menu,
                        style: AppTypography.headlineSm,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${items.length}',
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
            ),
            if (items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  title: query.isEmpty ? l10n.emptyState : l10n.noResults,
                  message: query.isEmpty ? null : l10n.clearSearch,
                  icon: Icons.restaurant_menu,
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                sliver: SliverList.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _MenuItemCard(
                      item: item,
                      l10n: l10n,
                      onTap: () => openLoadedMeal(
                        context,
                        item,
                        restaurantOpen: restaurant.isOpen,
                      ),
                      onAdd: () => openLoadedMeal(
                        context,
                        item,
                        restaurantOpen: restaurant.isOpen,
                      ),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 96)),
          ],
        ),
        PositionedDirectional(
          top: 0,
          start: 0,
          end: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  _HeroButton(
                    icon: Icons.arrow_forward,
                    tooltip: l10n.back,
                    onTap: () => context.pop(),
                  ),
                  const Spacer(),
                  _HeroButton(
                    icon: Icons.share_outlined,
                    tooltip: l10n.shareRestaurant,
                    onTap: () => Share.share(
                      '${restaurant.name} — ${l10n.appName}',
                      subject: restaurant.name,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FavoriteButton(
                    targetType: 'restaurant',
                    targetId: restaurant.id,
                    size: 40,
                    background: AppColors.surfaceContainerLowest.withValues(alpha: 0.92),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _hero(BuildContext context, L10n l10n, CatalogRestaurantDetail detail) {
    final restaurant = detail.restaurant;
    return SizedBox(
      height: 288,
      child: Stack(
        fit: StackFit.expand,
        children: [
          AppImage(
            url: restaurant.bannerUrl ?? restaurant.logoUrl,
            borderRadius: BorderRadius.zero,
            icon: Icons.restaurant,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x66000000), Color(0x11000000), Color(0xCC000000)],
                stops: [0, 0.45, 1],
              ),
            ),
          ),
          PositionedDirectional(
            start: AppSpacing.lg,
            end: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Row(
              children: [
                if (!restaurant.isOpen)
                  StatusPill(label: l10n.closed, isOpen: false)
                else
                  StatusPill(label: l10n.open, isOpen: true),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    restaurantCuisine(restaurant),
                    style: AppTypography.bodySm.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _meta(L10n l10n, CatalogRestaurantDetail detail) {
    final restaurant = detail.restaurant;
    final pills = <Widget>[
      if (restaurant.etaMinutes != null && restaurant.etaMinutes! <= 30)
        _FeaturePill(
          icon: Icons.bolt,
          label: l10n.sortFastest,
          color: AppColors.tertiary,
          background: AppColors.tertiaryContainer.withValues(alpha: 0.12),
        ),
      if (detail.offers.isNotEmpty)
        _FeaturePill(
          icon: Icons.local_offer,
          label: l10n.offers,
          color: AppColors.primary,
          background: AppColors.primaryFixed.withValues(alpha: 0.5),
        ),
      _FeaturePill(
        icon: Icons.schedule,
        label: restaurantEtaLabel(restaurant, l10n),
        color: AppColors.onSurface,
        background: AppColors.surfaceContainer,
      ),
    ];
    return Transform.translate(
      offset: const Offset(0, -24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppColors.floatingShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        restaurant.name,
                        style: AppTypography.headlineLgMobile,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        restaurantCuisine(restaurant),
                        style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(Icons.lunch_dining, size: 26, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: pills.length,
                separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
                itemBuilder: (_, index) => pills[index],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Row(
                children: [
                  _Metric(
                    value: Fmt.rating(restaurant.rating),
                    icon: Icons.star,
                    label: restaurant.ratingCount > 0 ? '(${restaurant.ratingCount})' : null,
                  ),
                  _divider(),
                  _Metric(
                    value: restaurantEtaLabel(restaurant, l10n),
                    label: l10n.deliveryTime,
                  ),
                  _divider(),
                  _Metric(
                    value: detail.deliveryFeeMinor == null
                        ? '—'
                        : (detail.deliveryFeeMinor == 0
                            ? l10n.deliveryFeeFree
                            : Fmt.money(detail.deliveryFeeMinor!)),
                    label: l10n.deliveryFee,
                  ),
                  _divider(),
                  _Metric(
                    value: detail.minOrderMinor == null
                        ? '—'
                        : Fmt.money(detail.minOrderMinor!),
                    label: l10n.minimumOrder,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 28,
        color: AppColors.surfaceContainerHigh,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      );

  Widget _offers(BuildContext context, L10n l10n, CatalogRestaurantDetail detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(l10n.offers, style: AppTypography.headlineSm),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: detail.offers.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              final offer = detail.offers[index];
              return OfferCard(
                offer: offer,
                width: 300,
                onTap: () => _showOffer(context, l10n, detail, offer),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showOffer(
    BuildContext context,
    L10n l10n,
    CatalogRestaurantDetail detail,
    CatalogOffer offer,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(
              title: offer.title(l10n.isArabic),
              trailing: IconButton(
                tooltip: l10n.shareOffer,
                icon: const Icon(Icons.share_outlined, size: 20),
                onPressed: () => Share.share(
                  '${offer.title(l10n.isArabic)} — ${offer.restaurantName}\n'
                  '${offer.description(l10n.isArabic)}',
                  subject: offer.title(l10n.isArabic),
                ),
              ),
              onClose: () => Navigator.of(sheetContext).pop(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.description(l10n.isArabic),
                    style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 360),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: offer.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = offer.items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            item.displayName(l10n.isArabic),
                            style: AppTypography.labelLg,
                          ),
                          subtitle: Text(
                            offer.discountType == 'percentage'
                                ? '${offer.discountValue}% ${l10n.offers}'
                                : Fmt.money(offer.discountValue),
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.tertiary,
                            ),
                          ),
                          trailing: PriceText(
                            priceMinor: item.offerPriceMinor,
                            compareAtMinor: item.priceMinor > item.offerPriceMinor
                                ? item.priceMinor
                                : null,
                            size: PriceSize.sm,
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            openMeal(
                              context,
                              item.menuItemId,
                              restaurantOpen: detail.restaurant.isOpen,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuSearchBar(L10n l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20, color: AppColors.secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _menuSearch,
                onChanged: (value) => setState(() => _query = value),
                style: AppTypography.bodyMd,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  hintStyle: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_query.isNotEmpty)
              InkWell(
                onTap: () {
                  _menuSearch.clear();
                  setState(() => _query = '');
                },
                child: const Icon(Icons.close, size: 18, color: AppColors.secondary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _categoryTabs(
    L10n l10n,
    List<CatalogMenuCategory> categories,
    String? selectedId,
  ) {
    if (categories.isEmpty) {
      return Container(
        color: AppColors.surfaceContainerLowest,
        alignment: AlignmentDirectional.centerStart,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Text(l10n.menu, style: AppTypography.headlineSm),
      );
    }
    return Container(
      color: AppColors.surfaceContainerLowest,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.lg),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = category.id == selectedId;
          return InkWell(
            onTap: () => setState(() => _categoryId = category.id),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: selected ? AppColors.onSurface : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Text(
                category.name,
                style: AppTypography.labelMd.copyWith(
                  color: selected ? AppColors.onSurface : AppColors.secondary,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.l10n,
    required this.onTap,
    required this.onAdd,
  });

  final CatalogMenuItem item;
  final L10n l10n;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          boxShadow: AppColors.cardShadow,
          border: Border.all(color: AppColors.surfaceContainerLow),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: AppTypography.headlineSm.copyWith(fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.badge(l10n.isArabic) != null &&
                          item.badge(l10n.isArabic)!.isNotEmpty)
                        const Padding(
                          padding: EdgeInsetsDirectional.only(start: 4),
                          child: Icon(
                            Icons.local_fire_department,
                            size: 16,
                            color: AppColors.warning,
                          ),
                        ),
                    ],
                  ),
                  if (item.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.description,
                      style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      PriceText(priceMinor: item.priceMinor, size: PriceSize.sm),
                      const Spacer(),
                      Material(
                        color: item.available
                            ? AppColors.primary
                            : AppColors.surfaceContainerHigh,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: item.available ? onAdd : null,
                          child: SizedBox(
                            width: 34,
                            height: 34,
                            child: Icon(
                              Icons.add,
                              size: 20,
                              color: item.available
                                  ? AppColors.onPrimary
                                  : AppColors.secondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SizedBox(
              width: 104,
              height: 104,
              child: Stack(
                children: [
                  AppImage(
                    url: item.imageUrl,
                    width: 104,
                    height: 104,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  if (!item.available)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          l10n.outOfStock,
                          style: AppTypography.labelSm.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  if (item.calories != null)
                    PositionedDirectional(
                      bottom: 4,
                      end: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.calories} kcal',
                          style: AppTypography.labelSm.copyWith(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartTray extends StatelessWidget {
  const _CartTray({required this.cart, required this.l10n});

  final CartResponse cart;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final quote = cart.quote;
    final total = quote?.totalMinor ??
        cart.lines.fold<int>(0, (sum, line) => sum + line.lineTotalMinor);
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: AppColors.sheetShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.tertiaryContainer,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${cart.itemCount} ${l10n.items}',
                        style: AppTypography.labelMd,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    Fmt.money(total, currency: quote?.currency ?? l10n.currencyDefault),
                    style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: () => context.push('/cart'),
                icon: const Icon(Icons.arrow_back, size: 20),
                label: Text(l10n.checkout),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black.withValues(alpha: 0.4)),
          ),
          child: Icon(icon, size: 21, color: Colors.white),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSm.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label, this.icon});

  final String value;
  final String? label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTypography.labelLg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 2),
                Icon(icon, size: 15, color: AppColors.warning),
              ],
            ],
          ),
          if (label != null)
            Text(
              label!,
              style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabsDelegate extends SliverPersistentHeaderDelegate {
  _TabsDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHigh)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _TabsDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}
