import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/models/orders.dart';
import '../../state/orders_controller.dart';
import '../../state/session_controller.dart';
import '../shared/headers.dart';

/// My Orders tab: active and past orders with backend pagination.
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
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 240) return;
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
        showBack: false,
        actions: const [CartHeaderButton()],
      ),
      onRefresh: signedIn
          ? () => ref.read(ordersProvider(_tab).notifier).refresh()
          : null,
      body: !signedIn
          ? EmptyState(
              title: l10n.noOrders,
              message: l10n.notAuthorized,
              icon: Icons.receipt_long_outlined,
              actionLabel: l10n.signIn,
              onAction: () => context.push('/login?next=/orders'),
            )
          : Column(
              children: [
                _Tabs(
                  activeLabel: l10n.activeOrders,
                  pastLabel: l10n.pastOrders,
                  active: _tab == OrdersTab.active,
                  onSelect: (active) =>
                      _select(active ? OrdersTab.active : OrdersTab.past),
                ),
                Expanded(
                  child: AsyncView(
                    value: orders,
                    onRetry: () => ref.read(ordersProvider(_tab).notifier).refresh(),
                    builder: (state) {
                      if (state.items.isEmpty) {
                        return EmptyState(
                          title: _tab == OrdersTab.active
                              ? l10n.noActiveOrders
                              : l10n.noOrders,
                          icon: Icons.receipt_long_outlined,
                          actionLabel: l10n.browseRestaurants,
                          onAction: () => context.push('/restaurants'),
                        );
                      }
                      return ListView.separated(
                        controller: _scroll,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: state.items.length + (state.hasMore ? 1 : 0),
                        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          if (index >= state.items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                              child: LoadingState(),
                            );
                          }
                          return _OrderCard(
                            order: state.items[index],
                            onTap: () =>
                                context.push('/orders/${state.items[index].id}'),
                            onReorder: () => _reorder(state.items[index]),
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

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.activeLabel,
    required this.pastLabel,
    required this.active,
    required this.onSelect,
  });

  final String activeLabel;
  final String pastLabel;
  final bool active;
  final ValueChanged<bool> onSelect;

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
          _tab(activeLabel, active, () => onSelect(true)),
          _tab(pastLabel, !active, () => onSelect(false)),
        ],
      ),
    );
  }

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            boxShadow: selected ? AppColors.cardShadow : null,
          ),
          child: Text(
            label,
            style: AppTypography.labelMd.copyWith(
              color: selected ? AppColors.primary : AppColors.secondary,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onReorder,
  });

  final OrderSummary order;
  final VoidCallback onTap;
  final VoidCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final color = _statusColor(order.status);
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.surfaceContainerHigh),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppImage(
                  url: order.restaurantLogoUrl,
                  width: 56,
                  height: 56,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.restaurantName ?? '—',
                        style: AppTypography.headlineSm.copyWith(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${order.reference} • ${Fmt.dateTime(order.placedAt)}',
                        style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _StatusChip(
                        label: order.statusLabel(l10n.isArabic),
                        color: color,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Fmt.money(order.totalMinor, currency: order.currency),
                      style: AppTypography.labelLg.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '${order.itemCount} ${l10n.items}',
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onTap,
                    child: Text(
                      order.isActive ? l10n.track : l10n.orderDetails,
                    ),
                  ),
                ),
                if (order.canRate) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onTap,
                      child: Text(l10n.rateOrder),
                    ),
                  ),
                ],
                if (!order.isActive && order.canReorder) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: order.restaurantId == null ? null : onReorder,
                      child: Text(l10n.reorder),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      'delivered' => AppColors.tertiary,
      'cancelled' || 'failed_delivery' => AppColors.secondary,
      'under_financial_review' => AppColors.warning,
      _ => AppColors.primary,
    };
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: AppTypography.labelSm.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
