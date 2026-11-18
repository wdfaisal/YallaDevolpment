import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/flat_empty_state.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/models/orders.dart';
import '../../state/orders_controller.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';
import 'widgets/order_card.dart';
import 'widgets/orders_tabs.dart';

/// My Orders tab: active and past orders with backend pagination. Flat white
/// canvas, segmented tabs, hairline order cards and one compact action per
/// order, in line with the rest of the customer app.
class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  final _scroll = ScrollController();
  OrdersTab _tab = OrdersTab.active;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final threshold = _scroll.position.maxScrollExtent - 240;
    if (_scroll.position.pixels < threshold) return;
    ref.read(ordersProvider(_tab).notifier).loadMore();
  }

  void _select(OrdersTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final signedIn = ref.watch(isSignedInProvider);
    final orders = ref.watch(ordersProvider(_tab));

    return AppScaffold(
      header: SimpleHeader(
        title: l10n.myOrders,
        subtitle: l10n.ordersSubtitle,
        showBack: false,
        actions: const [CartHeaderButton()],
      ),
      onRefresh: signedIn
          ? () => ref.read(ordersProvider(_tab).notifier).refresh()
          : null,
      body: !signedIn
          ? FlatEmptyState(
              title: l10n.noOrders,
              message: l10n.ordersGuestMessage,
              icon: Icons.receipt_long_outlined,
              actionLabel: l10n.signIn,
              actionIcon: Icons.login,
              onAction: () => context.push('/login?next=/orders'),
            )
          : Column(
              children: [
                OrdersTabs(
                  activeLabel: l10n.activeOrders,
                  pastLabel: l10n.pastOrders,
                  active: _tab == OrdersTab.active,
                  onSelect: (active) =>
                      _select(active ? OrdersTab.active : OrdersTab.past),
                ),
                Expanded(
                  child: AsyncView(
                    value: orders,
                    onRetry: () =>
                        ref.read(ordersProvider(_tab).notifier).refresh(),
                    loading: const _OrdersSkeleton(),
                    builder: (state) {
                      if (state.items.isEmpty) {
                        final active = _tab == OrdersTab.active;
                        return FlatEmptyState(
                          title:
                              active ? l10n.noActiveOrders : l10n.noPastOrders,
                          message: active
                              ? l10n.noActiveOrdersMessage
                              : l10n.noPastOrdersMessage,
                          icon: active
                              ? Icons.receipt_long_outlined
                              : Icons.history,
                          actionLabel: l10n.browseRestaurants,
                          onAction: () => context.push('/restaurants'),
                        );
                      }
                      return ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.gutter,
                          AppSpacing.sm,
                          AppSpacing.gutter,
                          AppSpacing.xxxl,
                        ),
                        itemCount: state.items.length + (state.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                ),
                              ),
                            );
                          }
                          final order = state.items[index];
                          return OrderCard(
                            order: order,
                            onTap: () => context.push('/orders/${order.id}'),
                            onReorder: () => _reorder(order),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  void _reorder(OrderSummary order) {
    final l10n = L10n.of(context);
    if (order.restaurantId == null) return;
    showAppSnack(context, l10n.reorderUnavailable);
    context.push('/restaurants/${order.restaurantId}');
  }
}

/// Placeholder cards that keep the list layout stable while the first page of
/// orders loads.
class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.gutter,
        AppSpacing.sm,
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
                const SkeletonBox(width: 48, height: 48, radius: 12),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SkeletonBox(width: 140, height: 12),
                      SizedBox(height: 8),
                      SkeletonBox(width: 90, height: 10),
                      SizedBox(height: 10),
                      SkeletonBox(width: 68, height: 16, radius: 6),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const SkeletonBox(width: 64, height: 14),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const SkeletonBox(height: 1, radius: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: const [
                SkeletonBox(width: 72, height: 10),
                Spacer(),
                SkeletonBox(width: 92, height: 34, radius: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
