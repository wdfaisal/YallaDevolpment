import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_system_ui.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/maps.dart';
import '../../data/models/orders.dart';
import '../../state/maps_controller.dart';
import '../../state/orders_controller.dart';
import '../shared/sheets.dart';
import 'order_detail_dialogs.dart';
import 'widgets/tracking_driver_card.dart';
import 'widgets/tracking_map_hero.dart';
import 'widgets/tracking_order_summary.dart';
import 'widgets/tracking_route_card.dart';
import 'widgets/tracking_safety_card.dart';
import 'widgets/tracking_timeline.dart';

/// Order details + live tracking rebuilt from the Stitch tracking design.
///
/// The page is a pure white canvas: a full-bleed live map reaches the notch, the
/// content column overlaps it by 16 px and every card is flat white with a
/// hairline border. No shadows, no grey surfaces. Polling only runs while the
/// order is active.
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  static const double _mapHeight = 360;
  static const double _contentOverlap = 16;

  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _poll = Timer.periodic(const Duration(seconds: 20), (_) {
      final detail = ref.read(orderDetailProvider(widget.orderId)).valueOrNull;
      if (detail != null && detail.summary.isActive) {
        ref.read(orderDetailProvider(widget.orderId).notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final detail = ref.watch(orderDetailProvider(widget.orderId));
    return AppScaffold(
      extendTop: true,
      statusBarStyle: AppSystemUi.light,
      onRefresh: () =>
          ref.read(orderDetailProvider(widget.orderId).notifier).refresh(),
      body: AsyncView(
        value: detail,
        onRetry: () =>
            ref.read(orderDetailProvider(widget.orderId).notifier).refresh(),
        builder: (data) => _body(context, l10n, data),
      ),
    );
  }

  Widget _body(BuildContext context, L10n l10n, OrderDetail detail) {
    final summary = detail.summary;
    final driver = detail.tracking.driver;
    final rating = detail.rating;
    // The backend owns the raster provider; the app only receives an
    // authenticated tile template. `null` while loading or when the server has
    // no tile source, so the map never falls back to a hardcoded provider.
    final tiles = ref.watch(mapTilesProvider).valueOrNull;
    final route = _routeFor(detail);
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        TrackingMapHero(
          detail: detail,
          l10n: l10n,
          height: _mapHeight,
          tiles: tiles,
          route: route,
          tileDio: ref.watch(mapTileDioProvider),
          onBack: () => context.pop(),
          onCancel: summary.canCancel
              ? () => _cancel(context, l10n, summary.id)
              : null,
        ),
        Transform.translate(
          offset: const Offset(0, -_contentOverlap),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xxxl - _contentOverlap,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TrackingTimeline(detail: detail, l10n: l10n),
                if (route != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TrackingRouteCard(route: route, l10n: l10n),
                ],
                const SizedBox(height: AppSpacing.lg),
                if (driver != null) ...[
                  TrackingDriverCard(
                    driver: driver,
                    l10n: l10n,
                    onCall: () => _callDriver(context, l10n, driver.phone),
                    onSupport: () => _openSupport(context, summary.id),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                TrackingOrderSummary(
                  detail: detail,
                  l10n: l10n,
                  onShareReceipt: () => _share(l10n, detail),
                  onSupport: () => _openSupport(context, summary.id),
                ),
                const SizedBox(height: AppSpacing.lg),
                TrackingSafetyCard(l10n: l10n),
                if (rating != null && !rating.isEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _RatingSummaryCard(rating: rating, l10n: l10n),
                ],
                const SizedBox(height: AppSpacing.lg),
                ..._actions(context, l10n, detail),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The road route for this order, or null while it loads / when the backend
  /// has no routing provider. Only the pickup→drop leg is routed; a missing
  /// coordinate means there is nothing honest to draw.
  MapRoute? _routeFor(OrderDetail detail) {
    final origin = detail.restaurantPosition;
    final destination = detail.deliveryPosition;
    if (origin == null || destination == null) return null;
    final query = MapRouteQuery(origin: origin, destination: destination);
    return ref.watch(mapRouteProvider(query)).valueOrNull;
  }

  List<Widget> _actions(
    BuildContext context,
    L10n l10n,
    OrderDetail detail,
  ) {
    final summary = detail.summary;
    final hasRating = detail.rating != null && !detail.rating!.isEmpty;
    final actions = <Widget>[
      if (summary.canRate && !hasRating)
        FilledButton.icon(
          onPressed: () => _showRating(context, l10n, detail),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
          ),
          icon: const Icon(Icons.star_outline, size: 20),
          label: Text(l10n.rateOrder),
        ),
      if (summary.canReorder && summary.restaurantId != null)
        OutlinedButton.icon(
          onPressed: () {
            showAppSnack(context, l10n.reorderUnavailable);
            context.push('/restaurants/${summary.restaurantId}');
          },
          style: _outlineStyle(AppColors.onSurface),
          icon: const Icon(Icons.replay, size: 18),
          label: Text(l10n.reorder),
        ),
      if (summary.restaurantId != null)
        OutlinedButton.icon(
          onPressed: () => context.push('/restaurants/${summary.restaurantId}'),
          style: _outlineStyle(AppColors.onSurface),
          icon: const Icon(Icons.storefront_outlined, size: 18),
          label: Text(l10n.viewRestaurant),
        ),
      TextButton.icon(
        onPressed: () => _openSupport(context, summary.id),
        style: TextButton.styleFrom(foregroundColor: AppColors.primary),
        icon: const Icon(Icons.support_agent, size: 18),
        label: Text(l10n.helpWithOrder),
      ),
    ];
    return [
      for (var index = 0; index < actions.length; index++) ...[
        if (index > 0) const SizedBox(height: AppSpacing.sm),
        actions[index],
      ],
    ];
  }

  ButtonStyle _outlineStyle(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      minimumSize: const Size.fromHeight(48),
      side: const BorderSide(color: AppColors.borderHairline),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
    );
  }

  void _openSupport(BuildContext context, String orderId) {
    context.push('/account/support/new?orderId=$orderId');
  }

  Future<void> _callDriver(
    BuildContext context,
    L10n l10n,
    String? phone,
  ) async {
    if (phone == null || phone.isEmpty) {
      showAppSnack(context, l10n.callUnavailable, isError: true);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        showAppSnack(context, l10n.callUnavailable, isError: true);
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, l10n.callUnavailable, isError: true);
      }
    }
  }

  void _share(L10n l10n, OrderDetail detail) {
    final summary = detail.summary;
    final text = [
      '${l10n.orderShareText} ${summary.restaurantName ?? ''}',
      '${l10n.orderReference}: ${summary.reference}',
      '${l10n.orderStatus}: ${summary.statusLabel(l10n.isArabic)}',
      '${l10n.total}: ${Fmt.money(summary.totalMinor, currency: summary.currency)}',
    ].join('\n');
    Share.share(text, subject: summary.reference);
  }

  Future<void> _cancel(
    BuildContext context,
    L10n l10n,
    String orderId,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.cancelOrder,
      message: l10n.cancelOrderConfirm,
      confirmLabel: l10n.cancelOrder,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    final reason = await showCancelReasonDialog(
      context,
      title: l10n.cancelOrder,
      hint: l10n.cancelReason,
    );
    if (reason == null) return;
    try {
      await ref.read(orderDetailProvider(orderId).notifier).cancel(
            reason: reason.trim().isEmpty ? null : reason.trim(),
          );
      if (!context.mounted) return;
      showAppSnack(context, l10n.orderCancelled);
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(
        context,
        error is ApiException ? error.message : l10n.somethingWentWrong,
        isError: true,
      );
    }
  }

  Future<void> _showRating(
    BuildContext context,
    L10n l10n,
    OrderDetail detail,
  ) async {
    final submitted = await showOrderRatingSheet(
      context,
      orderId: detail.summary.id,
      restaurantName: detail.summary.restaurantName ?? l10n.rateRestaurant,
      driverAvailable: detail.tracking.driver != null,
    );
    if (submitted == true && context.mounted) {
      ref.invalidate(orderDetailProvider(detail.summary.id));
      ref.invalidate(ordersProvider);
      showAppSnack(context, l10n.ratingSubmitted);
    }
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.rating, required this.l10n});

  final OrderRating rating;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.borderHairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.yourRating, style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          if (rating.restaurant != null)
            _RatingRow(label: l10n.rateRestaurant, stars: rating.restaurant!),
          if (rating.driver != null)
            _RatingRow(label: l10n.rateDriver, stars: rating.driver!),
        ],
      ),
    );
  }
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.label, required this.stars});

  final String label;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.bodySm)),
          for (var i = 1; i <= 5; i++)
            Icon(
              i <= stars ? Icons.star_rounded : Icons.star_border_rounded,
              size: 18,
              color: AppColors.warning,
            ),
        ],
      ),
    );
  }
}
