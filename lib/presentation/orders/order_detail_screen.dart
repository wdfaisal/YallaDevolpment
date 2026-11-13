import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/design/app_colors.dart';
import '../../core/design/app_spacing.dart';
import '../../core/design/app_typography.dart';
import '../../core/formatting/formatters.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/orders.dart';
import '../../state/orders_controller.dart';
import '../../state/providers.dart';
import '../shared/headers.dart';
import '../shared/sheets.dart';

/// Order details + live tracking (backend driven; polling only while active).
class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
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
      header: SimpleHeader(
        title: l10n.orderDetails,
        onBack: () => context.pop(),
        actions: [
          HeaderIconButton(
            icon: Icons.share_outlined,
            tooltip: l10n.shareOrder,
            onTap: () {
              final value = detail.valueOrNull;
              if (value != null) _share(l10n, value);
            },
          ),
        ],
      ),
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xxxl,
      ),
      children: [
        _statusCard(l10n, detail),
        if (detail.tracking.driver != null) ...[
          const SizedBox(height: AppSpacing.md),
          _driverCard(context, l10n, detail.tracking.driver!),
        ],
        if (detail.tracking.events.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _timelineCard(l10n, detail.tracking.events),
        ],
        const SizedBox(height: AppSpacing.md),
        _itemsCard(l10n, detail),
        const SizedBox(height: AppSpacing.md),
        _paymentCard(l10n, detail),
        const SizedBox(height: AppSpacing.md),
        _deliveryCard(l10n, detail),
        if (detail.rating != null && !detail.rating!.isEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _ratingSummary(l10n, detail.rating!),
        ],
        const SizedBox(height: AppSpacing.lg),
        if (summary.canCancel) ...[
          OutlinedButton.icon(
            onPressed: () => _cancel(context, l10n, summary.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            icon: const Icon(Icons.close, size: 18),
            label: Text(l10n.cancelOrder),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (summary.canRate && (detail.rating == null || detail.rating!.isEmpty)) ...[
          FilledButton.icon(
            onPressed: () => _showRating(context, l10n, detail),
            icon: const Icon(Icons.star_outline, size: 20),
            label: Text(l10n.rateOrder),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (summary.canReorder && summary.restaurantId != null) ...[
          OutlinedButton.icon(
            onPressed: () {
              showAppSnack(context, l10n.reorderUnavailable);
              context.push('/restaurants/${summary.restaurantId}');
            },
            icon: const Icon(Icons.replay, size: 18),
            label: Text(l10n.reorder),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (summary.restaurantId != null)
          OutlinedButton.icon(
            onPressed: () => context.push('/restaurants/${summary.restaurantId}'),
            icon: const Icon(Icons.storefront_outlined, size: 18),
            label: Text(l10n.viewRestaurant),
          ),
        const SizedBox(height: AppSpacing.sm),
        TextButton.icon(
          onPressed: () => context.push('/account/support/new?orderId=${summary.id}'),
          icon: const Icon(Icons.support_agent, size: 18),
          label: Text(l10n.helpWithOrder),
        ),
      ],
    );
  }

  Widget _statusCard(L10n l10n, OrderDetail detail) {
    final summary = detail.summary;
    final color = _statusColor(summary.status);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  summary.statusLabel(l10n.isArabic),
                  style: AppTypography.headlineMd,
                ),
              ),
              _Chip(label: summary.statusLabel(l10n.isArabic), color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${l10n.orderReference}: ${summary.reference}',
            style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
          ),
          Text(
            '${l10n.placedAt}: ${Fmt.dateTime(summary.placedAt)}',
            style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
          ),
          if (detail.tracking.etaMinutes != null && summary.isActive) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${l10n.eta}: ${detail.tracking.etaMinutes} ${l10n.minuteShort}',
                  style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _driverCard(BuildContext context, L10n l10n, DriverTracking driver) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.orangeTintSoft,
            child: Text(
              driver.initials.isEmpty ? driver.name.characters.first : driver.initials,
              style: AppTypography.labelLg.copyWith(color: AppColors.primary),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        driver.name,
                        style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.star_rounded, size: 15, color: AppColors.warning),
                    Text(
                      Fmt.rating(driver.rating),
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
                Text(
                  [driver.vehicle, driver.plate].where((e) => e.isNotEmpty).join(' • '),
                  style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (driver.lastSignalAt != null)
                  Text(
                    '${l10n.lastSignal}: ${Fmt.relative(driver.lastSignalAt, isArabic: l10n.isArabic)}',
                    style: AppTypography.labelSm.copyWith(
                      color: driver.stale ? AppColors.warning : AppColors.tertiary,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _callDriver(context, l10n, driver.phone),
            tooltip: l10n.callDriver,
            icon: const Icon(Icons.call),
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _timelineCard(L10n l10n, List<TimelineEvent> events) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.orderTimeline, style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          for (var index = 0; index < events.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: index == 0 ? AppColors.primary : AppColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          events[index].title,
                          style: AppTypography.labelMd.copyWith(
                            fontWeight: FontWeight.w700,
                            color: index == 0 ? AppColors.onSurface : AppColors.secondary,
                          ),
                        ),
                        if (events[index].detail != null &&
                            events[index].detail!.isNotEmpty)
                          Text(
                            events[index].detail!,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        Text(
                          events[index].at.isEmpty
                              ? events[index].time
                              : Fmt.dateTime(events[index].at),
                          style: AppTypography.labelSm.copyWith(
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemsCard(L10n l10n, OrderDetail detail) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.items, style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          for (final item in detail.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.orangeTintSubtle,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${item.quantity}×',
                      style: AppTypography.labelSm.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: AppTypography.labelMd),
                        if (item.options.isNotEmpty)
                          Text(
                            item.options,
                            style: AppTypography.bodySm.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                        if (item.notes.isNotEmpty)
                          Text(
                            item.notes,
                            style: AppTypography.labelSm.copyWith(
                              color: AppColors.secondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    Fmt.money(item.lineTotalMinor, currency: detail.summary.currency),
                    style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          const Divider(height: AppSpacing.xl),
          _priceRow(l10n.subtotal, detail.subtotalMinor, detail.summary.currency),
          if (detail.fulfillment == 'delivery')
            _priceRow(
              l10n.deliveryFee,
              detail.deliveryFeeMinor,
              detail.summary.currency,
            ),
          if (detail.discountMinor > 0)
            _priceRow(
              detail.couponCode == null
                  ? l10n.discount
                  : '${l10n.discount} (${detail.couponCode})',
              -detail.discountMinor,
              detail.summary.currency,
              highlight: true,
            ),
          _priceRow(l10n.vat, detail.vatMinor, detail.summary.currency),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: Text(l10n.total, style: AppTypography.headlineSm)),
              Text(
                Fmt.moneyExact(
                  detail.summary.totalMinor,
                  currency: detail.summary.currency,
                ),
                style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(String label, int amount, String currency, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
            ),
          ),
          Text(
            Fmt.money(amount, currency: currency),
            style: AppTypography.labelMd.copyWith(
              color: highlight ? AppColors.tertiary : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(L10n l10n, OrderDetail detail) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(l10n.paymentBreakdown, style: AppTypography.headlineSm)),
              _Chip(
                label: _paymentStatusLabel(l10n, detail.summary.paymentStatus),
                color: detail.summary.paymentStatus == 'paid'
                    ? AppColors.tertiary
                    : AppColors.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (detail.payments.isEmpty)
            Text(
              _paymentStatusLabel(l10n, detail.summary.paymentStatus),
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
            )
          else
            for (final payment in detail.payments)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  children: [
                    Icon(_paymentIcon(payment.method), size: 18, color: AppColors.secondary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${_methodLabel(l10n, payment.method)} • ${_paymentStatusLabel(l10n, payment.status)}',
                        style: AppTypography.bodySm,
                      ),
                    ),
                    Text(
                      Fmt.money(payment.amountMinor, currency: detail.summary.currency),
                      style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _deliveryCard(L10n l10n, OrderDetail detail) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deliveryInfo, style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          _infoRow(Icons.location_on_outlined, detail.deliveryAddress),
          _infoRow(
            Icons.shopping_bag_outlined,
            detail.fulfillment == 'pickup' ? l10n.pickup : l10n.delivery,
          ),
          if (detail.scheduledFor != null)
            _infoRow(Icons.event_outlined, Fmt.dateTime(detail.scheduledFor)),
          if (detail.note.isNotEmpty) _infoRow(Icons.edit_note, detail.note),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.secondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingSummary(L10n l10n, OrderRating rating) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.yourRating, style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          if (rating.restaurant != null)
            _ratingRow(l10n.rateRestaurant, rating.restaurant!),
          if (rating.driver != null) _ratingRow(l10n.rateDriver, rating.driver!),
        ],
      ),
    );
  }

  Widget _ratingRow(String label, int stars) {
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

  Future<void> _callDriver(BuildContext context, L10n l10n, String? phone) async {
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

  Future<void> _cancel(BuildContext context, L10n l10n, String orderId) async {
    final confirmed = await showConfirmDialog(
      context,
      title: l10n.cancelOrder,
      message: l10n.cancelOrderConfirm,
      confirmLabel: l10n.cancelOrder,
    );
    if (!confirmed) return;
    if (!context.mounted) return;
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CancelReasonDialog(title: l10n.cancelOrder, hint: l10n.cancelReason),
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
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _RatingSheet(
        orderId: detail.summary.id,
        restaurantName: detail.summary.restaurantName ?? l10n.rateRestaurant,
        driverAvailable: detail.tracking.driver != null,
      ),
    );
    if (submitted == true && context.mounted) {
      ref.invalidate(orderDetailProvider(detail.summary.id));
      ref.invalidate(ordersProvider);
      showAppSnack(context, l10n.ratingSubmitted);
    }
  }

  Color _statusColor(String status) {
    return switch (status) {
      'delivered' => AppColors.tertiary,
      'cancelled' || 'failed_delivery' => AppColors.secondary,
      'under_financial_review' => AppColors.warning,
      _ => AppColors.primary,
    };
  }

  String _methodLabel(L10n l10n, String method) {
    return switch (method) {
      'wallet' => l10n.payWithWallet,
      'cash_on_delivery' => l10n.cashOnDelivery,
      'card_gateway' => l10n.cardGateway,
      'manual_bank_transfer' => l10n.bankTransfer,
      _ => method,
    };
  }

  IconData _paymentIcon(String method) {
    return switch (method) {
      'wallet' => Icons.account_balance_wallet_outlined,
      'card_gateway' => Icons.credit_card,
      'manual_bank_transfer' => Icons.account_balance,
      _ => Icons.payments_outlined,
    };
  }

  String _paymentStatusLabel(L10n l10n, String status) {
    return switch (status) {
      'paid' => l10n.paid,
      'authorized' => l10n.authorized,
      'pending' => l10n.unpaid,
      'failed' => l10n.paymentFailed,
      'refunded' => l10n.refunded,
      'partially_refunded' => l10n.partiallyRefunded,
      _ => status,
    };
  }
}

class _RatingSheet extends ConsumerStatefulWidget {
  const _RatingSheet({
    required this.orderId,
    required this.restaurantName,
    required this.driverAvailable,
  });

  final String orderId;
  final String restaurantName;
  final bool driverAvailable;

  @override
  ConsumerState<_RatingSheet> createState() => _RatingSheetState();
}

class _RatingSheetState extends ConsumerState<_RatingSheet> {
  final _restaurantComment = TextEditingController();
  final _driverComment = TextEditingController();
  int _restaurantStars = 0;
  int _driverStars = 0;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _restaurantComment.dispose();
    _driverComment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = L10n.of(context);
    if (_restaurantStars == 0 && _driverStars == 0) {
      setState(() => _error = l10n.starsRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(accountRepositoryProvider).rateOrder(
            orderId: widget.orderId,
            restaurantStars: _restaurantStars == 0 ? null : _restaurantStars,
            restaurantComment: _restaurantComment.text.trim(),
            driverStars: _driverStars == 0 ? null : _driverStars,
            driverComment: _driverComment.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error is ApiException ? error.message : l10n.somethingWentWrong;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Text(l10n.rateYourOrder, style: AppTypography.headlineSm),
            const SizedBox(height: AppSpacing.lg),
            Text(widget.restaurantName, style: AppTypography.labelLg),
            const SizedBox(height: AppSpacing.xs),
            _StarPicker(
              value: _restaurantStars,
              onChanged: (value) => setState(() => _restaurantStars = value),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _restaurantComment,
              maxLines: 2,
              maxLength: 500,
              style: AppTypography.bodyMd,
              decoration: InputDecoration(
                hintText: l10n.yourComment,
                counterText: '',
              ),
            ),
            if (widget.driverAvailable) ...[
              const SizedBox(height: AppSpacing.md),
              Text(l10n.rateDriver, style: AppTypography.labelLg),
              const SizedBox(height: AppSpacing.xs),
              _StarPicker(
                value: _driverStars,
                onChanged: (value) => setState(() => _driverStars = value),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _driverComment,
                maxLines: 2,
                maxLength: 500,
                style: AppTypography.bodyMd,
                decoration: InputDecoration(
                  hintText: l10n.yourComment,
                  counterText: '',
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                _error!,
                style: AppTypography.bodySm.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(l10n.submitRating),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarPicker extends StatelessWidget {
  const _StarPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => onChanged(i),
            icon: Icon(
              i <= value ? Icons.star_rounded : Icons.star_border_rounded,
              size: 32,
              color: AppColors.warning,
            ),
          ),
      ],
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  const _CancelReasonDialog({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 300,
        style: AppTypography.bodyMd,
        decoration: InputDecoration(hintText: widget.hint, counterText: ''),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(l10n.cancelOrder),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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

const _cardDecoration = BoxDecoration(
  color: AppColors.surfaceContainerLowest,
  borderRadius: BorderRadius.all(Radius.circular(AppSpacing.radiusLg)),
  border: Border.fromBorderSide(BorderSide(color: AppColors.surfaceContainerHigh)),
  boxShadow: AppColors.cardShadow,
);
