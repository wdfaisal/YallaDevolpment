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
import '../../core/widgets/quantity_stepper.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/cart.dart';
import '../../data/models/customer.dart';
import '../../state/account_controllers.dart';
import '../../state/address_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/orders_controller.dart';
import '../shared/headers.dart';
import '../shared/sheets.dart';

/// Cart & checkout (Stitch screen 7). All financial values come from the
/// backend quote; the screen never computes totals locally.
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  final _noteController = TextEditingController();
  final _referenceController = TextEditingController();

  late final String _idempotencyKey =
      'cart-${DateTime.now().microsecondsSinceEpoch}';

  CartQuote? _quote;
  String? _quoteError;
  bool _quoting = false;
  bool _placing = false;
  String _fulfillment = 'delivery';
  String? _method;
  String _couponCode = '';
  bool _useWalletSplit = false;
  bool _quoteRequested = false;

  @override
  void dispose() {
    _couponController.dispose();
    _noteController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _refreshQuote() async {
    if (_quoting) return;
    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null || cart.lines.isEmpty) {
      if (mounted) {
        setState(() {
          _quote = null;
          _quoting = false;
        });
      }
      return;
    }
    final address = ref.read(selectedAddressProvider);
    setState(() {
      _quoting = true;
      _quoteError = null;
    });
    try {
      final quote = await ref.read(cartProvider.notifier).quote(
            QuoteRequest(
              addressId: address?.id,
              couponCode: _couponCode.isEmpty ? null : _couponCode,
              fulfillment: _fulfillment,
            ),
          );
      if (!mounted) return;
      final usable = quote.paymentMethods.where((m) => m.usable).toList(growable: false);
      var method = _method;
      if (method == null || !usable.any((m) => m.method == method)) {
        method = _defaultMethod(usable, quote.totalMinor);
      }
      final wallet = ref.read(walletProvider).valueOrNull;
      final walletUsable = usable.any((m) => m.method == 'wallet');
      final canSplit = walletUsable &&
          usable.any((m) => m.method == 'cash_on_delivery') &&
          (wallet?.availableMinor ?? 0) > 0 &&
          (wallet?.availableMinor ?? 0) < quote.totalMinor;
      setState(() {
        _quote = quote;
        _quoting = false;
        _method = method;
        if (!canSplit) _useWalletSplit = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _quoting = false;
        _quoteError = error is ApiException ? error.message : error.toString();
      });
    }
  }

  String? _defaultMethod(List<PaymentMethodOption> usable, int total) {
    final wallet = ref.read(walletProvider).valueOrNull;
    final walletOption = usable.where((m) => m.method == 'wallet');
    if (walletOption.isNotEmpty &&
        wallet != null &&
        wallet.availableMinor >= total) {
      return 'wallet';
    }
    final cash = usable.where((m) => m.method == 'cash_on_delivery');
    if (cash.isNotEmpty) return 'cash_on_delivery';
    return usable.isEmpty ? null : usable.first.method;
  }

  List<PaymentPartRequest> _paymentParts(CartQuote quote) {
    final wallet = ref.read(walletProvider).valueOrNull;
    final walletAvailable = wallet?.availableMinor ?? 0;
    if (_useWalletSplit && walletAvailable > 0 && walletAvailable < quote.totalMinor) {
      return [
        PaymentPartRequest(method: 'wallet', amountMinor: walletAvailable),
        PaymentPartRequest(
          method: 'cash_on_delivery',
          amountMinor: quote.totalMinor - walletAvailable,
        ),
      ];
    }
    final method = _method;
    if (method == null) return const [];
    return [
      PaymentPartRequest(
        method: method,
        amountMinor: quote.totalMinor,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      ),
    ];
  }

  String? _paymentValidation(CartQuote quote) {
    final l10n = L10n.of(context);
    if (_method == null && !_useWalletSplit) return l10n.paymentMethod;
    final wallet = ref.read(walletProvider).valueOrNull;
    if (_useWalletSplit) {
      if ((wallet?.availableMinor ?? 0) <= 0) return l10n.insufficientWallet;
      return null;
    }
    if (_method == 'wallet' && (wallet?.availableMinor ?? 0) < quote.totalMinor) {
      return l10n.insufficientWallet;
    }
    final option = quote.paymentMethods.where((m) => m.method == _method);
    if (option.isNotEmpty && option.first.requiresReference) {
      if (_referenceController.text.trim().isEmpty) return l10n.requiredField;
    }
    return null;
  }

  Future<void> _placeOrder(CartQuote quote) async {
    final l10n = L10n.of(context);
    final address = ref.read(selectedAddressProvider);
    if (address == null) {
      showAppSnack(context, l10n.addAddress, isError: true);
      return;
    }
    if (!quote.meetsMinimum) {
      showAppSnack(context, l10n.minimumNotMet, isError: true);
      return;
    }
    final paymentError = _paymentValidation(quote);
    if (paymentError != null) {
      showAppSnack(context, paymentError, isError: true);
      return;
    }
    final parts = _paymentParts(quote);
    if (parts.isEmpty || parts.fold<int>(0, (sum, p) => sum + p.amountMinor) != quote.totalMinor) {
      showAppSnack(context, l10n.paymentUnavailable, isError: true);
      return;
    }

    setState(() => _placing = true);
    try {
      final result = await ref.read(cartProvider.notifier).checkout(
            CheckoutRequest(
              addressId: address.id,
              couponCode: _couponCode.isEmpty ? null : _couponCode,
              fulfillment: _fulfillment,
              paymentParts: parts,
              note: _noteController.text.trim(),
              idempotencyKey: _idempotencyKey,
            ),
          );
      ref.invalidate(ordersProvider);
      ref.invalidate(walletProvider);
      ref.invalidate(loyaltyProvider);
      if (!mounted) return;
      showAppSnack(context, l10n.orderPlaced);
      context.pushReplacement('/orders/${result.orderId}');
    } catch (error) {
      if (!mounted) return;
      setState(() => _placing = false);
      showAppSnack(
        context,
        error is ApiException ? error.message : l10n.orderFailed,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final cartAsync = ref.watch(cartProvider);
    final address = ref.watch(selectedAddressProvider);

    ref.listen(selectedAddressProvider, (previous, next) {
      if (previous?.id != next?.id) _refreshQuote();
    });

    return AppScaffold(
      header: SimpleHeader(
        title: l10n.checkout,
        onBack: () => context.pop(),
      ),
      bottomBar: cartAsync.valueOrNull != null &&
              cartAsync.valueOrNull!.lines.isNotEmpty
          ? _bottomTray(l10n, cartAsync.valueOrNull!)
          : null,
      body: AsyncView(
        value: cartAsync,
        onRetry: () => ref.read(cartProvider.notifier).refresh(),
        builder: (cart) {
          if (cart.lines.isEmpty) {
            return EmptyState(
              title: l10n.emptyCart,
              message: l10n.emptyCartHint,
              icon: Icons.shopping_bag_outlined,
              actionLabel: l10n.browseRestaurants,
              onAction: () => context.push('/restaurants'),
            );
          }
          if (!_quoteRequested) {
            _quoteRequested = true;
            WidgetsBinding.instance.addPostFrameCallback((_) => _refreshQuote());
          }
          return _body(context, l10n, cart, address);
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    L10n l10n,
    CartResponse cart,
    CustomerAddressRecord? address,
  ) {
    final quote = _quote;
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (_quoteError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: _InlineError(
              message: _quoteError!,
              onRetry: _refreshQuote,
              retryLabel: l10n.retry,
            ),
          ),
        if (quote != null && quote.freeDeliveryApplied)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: _FreeDeliveryBanner(quote: quote, l10n: l10n),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: _restaurantCard(context, l10n, cart),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: _items(context, l10n, cart),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: _fulfillmentCard(l10n),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: _notesCard(l10n),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: _couponCard(l10n, quote),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: _addressCard(context, l10n, address),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: _paymentCard(l10n, quote),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: _summaryCard(l10n, quote),
        ),
        if (quote != null && quote.warnings.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: _warnings(l10n, quote.warnings),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 18, color: AppColors.tertiary),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.orderPlaced,
                  style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _restaurantCard(BuildContext context, L10n l10n, CartResponse cart) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.orderSummary,
                  style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                ),
                const SizedBox(height: 2),
                Text(
                  cart.restaurantName ?? '—',
                  style: AppTypography.headlineSm,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (cart.restaurantId != null)
            IconButton(
              icon: const Icon(Icons.restaurant_menu),
              tooltip: l10n.menu,
              color: AppColors.primary,
              onPressed: () => context.push('/restaurants/${cart.restaurantId}'),
            ),
        ],
      ),
    );
  }

  Widget _items(BuildContext context, L10n l10n, CartResponse cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${l10n.items} (${cart.itemCount})',
                style: AppTypography.headlineSm,
              ),
            ),
            if (cart.restaurantId != null)
              TextButton(
                onPressed: () => context.push('/restaurants/${cart.restaurantId}'),
                child: Text(l10n.addToCart),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final line in cart.lines) ...[
          _CartLineCard(
            line: line,
            l10n: l10n,
            onQuantity: (value) async {
              try {
                await ref.read(cartProvider.notifier).changeQuantity(line, value);
                await _refreshQuote();
              } catch (error) {
                if (!context.mounted) return;
                showAppSnack(
                  context,
                  error is ApiException ? error.message : l10n.somethingWentWrong,
                  isError: true,
                );
              }
            },
            onRemove: () async {
              try {
                await ref.read(cartProvider.notifier).removeItem(line.id);
                await _refreshQuote();
              } catch (error) {
                if (!context.mounted) return;
                showAppSnack(
                  context,
                  error is ApiException ? error.message : l10n.somethingWentWrong,
                  isError: true,
                );
              }
            },
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: cart.restaurantId == null
                ? null
                : () => context.push('/restaurants/${cart.restaurantId}'),
            icon: const Icon(Icons.add_circle_outline, size: 18),
            label: Text(l10n.addToCart),
          ),
        ),
      ],
    );
  }

  Widget _fulfillmentCard(L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deliveryInfo, style: AppTypography.labelLg),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppChoiceChip(
                  label: l10n.delivery,
                  selected: _fulfillment == 'delivery',
                  icon: Icons.delivery_dining,
                  onTap: () {
                    if (_fulfillment == 'delivery') return;
                    setState(() => _fulfillment = 'delivery');
                    _refreshQuote();
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppChoiceChip(
                  label: l10n.pickup,
                  selected: _fulfillment == 'pickup',
                  icon: Icons.storefront_outlined,
                  onTap: () {
                    if (_fulfillment == 'pickup') return;
                    setState(() => _fulfillment = 'pickup');
                    _refreshQuote();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _notesCard(L10n l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, size: 20, color: AppColors.secondary),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.orderNote, style: AppTypography.labelLg),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteController,
            maxLines: 3,
            maxLength: 500,
            style: AppTypography.bodyMd,
            decoration: InputDecoration(
              hintText: l10n.notesHint,
              hintStyle: AppTypography.bodySm.copyWith(color: AppColors.secondary),
              filled: true,
              fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                borderSide: BorderSide.none,
              ),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  Widget _couponCard(L10n l10n, CartQuote? quote) {
    final applied = quote?.coupon;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Text(l10n.couponCode, style: AppTypography.labelLg),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (applied != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.tertiaryContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.tertiary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          applied.code,
                          style: AppTypography.labelLg.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          applied.description.isEmpty
                              ? l10n.couponApplied
                              : applied.description,
                          style: AppTypography.bodySm.copyWith(color: AppColors.tertiary),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _couponCode = '');
                      _couponController.clear();
                      _refreshQuote();
                    },
                    child: Text(
                      l10n.removeCoupon,
                      style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    textCapitalization: TextCapitalization.characters,
                    style: AppTypography.bodyMd,
                    decoration: InputDecoration(
                      hintText: l10n.couponCode,
                      hintStyle: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.radius),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: _quoting
                        ? null
                        : () {
                            final code = _couponController.text.trim();
                            if (code.isEmpty) return;
                            setState(() => _couponCode = code);
                            _refreshQuote();
                          },
                    child: Text(l10n.applyCoupon),
                  ),
                ),
              ],
            ),
          if (quote?.couponError != null && quote!.couponError!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(
                quote.couponError!,
                style: AppTypography.bodySm.copyWith(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Widget _addressCard(
    BuildContext context,
    L10n l10n,
    CustomerAddressRecord? address,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.deliveryAddress, style: AppTypography.labelLg)),
              TextButton(
                onPressed: () => showAddressPicker(context),
                child: Text(
                  address == null ? l10n.addAddress : l10n.change,
                  style: AppTypography.labelMd.copyWith(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (address == null)
            Text(
              l10n.addAddressToSeeNearby,
              style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
            )
          else
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                    child: const Icon(Icons.home_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                address.label,
                                style: AppTypography.labelLg,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (address.isDefault) ...[
                              const SizedBox(width: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.orangeTintSoft,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.defaultAddress,
                                  style: AppTypography.labelSm.copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          address.address,
                          style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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

  Widget _paymentCard(L10n l10n, CartQuote? quote) {
    final wallet = ref.watch(walletProvider).valueOrNull;
    final methods = quote?.paymentMethods ?? const <PaymentMethodOption>[];
    final walletUsable = methods.any((m) => m.usable && m.method == 'wallet');
    final cashUsable = methods.any((m) => m.usable && m.method == 'cash_on_delivery');
    final canSplit = walletUsable &&
        cashUsable &&
        quote != null &&
        (wallet?.availableMinor ?? 0) > 0 &&
        (wallet?.availableMinor ?? 0) < quote.totalMinor;
    final selectedOption = methods.where((m) => m.method == _method);
    final needsReference =
        !_useWalletSplit && selectedOption.isNotEmpty && selectedOption.first.requiresReference;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                size: 20,
                color: AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(l10n.paymentMethod, style: AppTypography.labelLg)),
              if (wallet != null)
                Text(
                  '${l10n.walletBalance}: ${Fmt.money(wallet.availableMinor, currency: wallet.currency)}',
                  style: AppTypography.labelSm.copyWith(color: AppColors.tertiary),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (quote == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: LoadingState(),
            )
          else ...[
            for (final option in methods)
              _PaymentOptionTile(
                option: option,
                selected: !_useWalletSplit && _method == option.method,
                onTap: option.usable
                    ? () => setState(() {
                          _method = option.method;
                          _useWalletSplit = false;
                        })
                    : null,
                unavailableLabel: l10n.paymentUnavailable,
              ),
            if (canSplit)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.xs),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.orangeTintSubtle,
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.call_split, size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(l10n.mixedPayment, style: AppTypography.labelMd),
                        ),
                        Switch(
                          value: _useWalletSplit,
                          onChanged: (value) => setState(() => _useWalletSplit = value),
                        ),
                      ],
                    ),
                    if (_useWalletSplit)
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n.wallet}: ${Fmt.money(wallet!.availableMinor, currency: wallet.currency)}',
                              style: AppTypography.labelSm,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${l10n.cashOnDelivery}: ${Fmt.money(quote.totalMinor - wallet.availableMinor, currency: quote.currency)}',
                              style: AppTypography.labelSm,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            if (needsReference) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _referenceController,
                style: AppTypography.bodyMd,
                decoration: InputDecoration(
                  hintText: l10n.requiredField,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(L10n l10n, CartQuote? quote) {
    if (quote == null) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: _cardDecoration,
        child: const LoadingState(),
      );
    }
    final vatPercent = quote.taxRateBasisPoints / 100;
    final vatLabel = vatPercent == vatPercent.roundToDouble()
        ? vatPercent.toStringAsFixed(0)
        : vatPercent.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.orderSummary, style: AppTypography.headlineSm),
          const SizedBox(height: AppSpacing.sm),
          _priceRow(l10n.subtotal, Fmt.money(quote.subtotalMinor)),
          if (quote.fulfillment == 'delivery')
            _priceRow(
              l10n.deliveryFee,
              quote.deliveryFeeMinor == 0
                  ? l10n.deliveryFeeFree
                  : Fmt.money(quote.deliveryFeeMinor),
              original: quote.deliveryFeeOriginalMinor > quote.deliveryFeeMinor
                  ? Fmt.money(quote.deliveryFeeOriginalMinor)
                  : null,
              highlight: quote.deliveryFeeMinor == 0,
            ),
          if (quote.discountMinor > 0)
            _priceRow(
              quote.coupon == null
                  ? l10n.discount
                  : '${l10n.discount} (${quote.coupon!.code})',
              '-${Fmt.money(quote.discountMinor)}',
              highlight: true,
            ),
          _priceRow('${l10n.vat} ($vatLabel%)', Fmt.money(quote.vatMinor)),
          const Divider(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.total, style: AppTypography.headlineSm),
                    Text(
                      l10n.orderSummary,
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                    ),
                  ],
                ),
              ),
              Text(
                Fmt.moneyExact(quote.totalMinor, currency: quote.currency),
                style: AppTypography.headlineMd.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceRow(
    String label,
    String value, {
    String? original,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyMd.copyWith(color: AppColors.secondary),
            ),
          ),
          if (original != null) ...[
            Text(
              original,
              style: AppTypography.labelSm.copyWith(
                color: AppColors.secondary,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            value,
            style: AppTypography.labelLg.copyWith(
              color: highlight ? AppColors.tertiary : AppColors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warnings(L10n l10n, List<String> warnings) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final warning in warnings)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    warning,
                    style: AppTypography.bodySm.copyWith(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _bottomTray(L10n l10n, CartResponse cart) {
    final quote = _quote;
    final address = ref.watch(selectedAddressProvider);
    final canSubmit = quote != null &&
        quote.meetsMinimum &&
        address != null &&
        !_quoting &&
        !_placing &&
        _paymentValidation(quote) == null;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          boxShadow: AppColors.sheetShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quote != null && !quote.meetsMinimum)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  '${l10n.minimumNotMet}: ${l10n.minimumRemaining} ${Fmt.money(quote.remainingForMinimum)}',
                  style: AppTypography.labelSm.copyWith(color: AppColors.error),
                ),
              ),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: FilledButton(
                onPressed: canSubmit ? () => _placeOrder(quote) : null,
                child: _placing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(l10n.placingOrder),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: Text(l10n.placeOrder)),
                          if (quote != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(AppSpacing.radius),
                              ),
                              child: Text(
                                Fmt.money(quote.totalMinor, currency: quote.currency),
                                style: AppTypography.labelLg.copyWith(color: Colors.white),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 14, color: AppColors.tertiary),
                const SizedBox(width: 4),
                Text(
                  l10n.paymentMethod,
                  style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CartLineCard extends StatelessWidget {
  const _CartLineCard({
    required this.line,
    required this.l10n,
    required this.onQuantity,
    required this.onRemove,
  });

  final CartLine line;
  final L10n l10n;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
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
                        line.name,
                        style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 18),
                      color: AppColors.secondary,
                      onPressed: onRemove,
                    ),
                  ],
                ),
                if (line.options.isNotEmpty)
                  Text(
                    line.optionsSummary(l10n.isArabic),
                    style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (line.notes.isNotEmpty)
                  Text(
                    line.notes,
                    style: AppTypography.bodySm.copyWith(color: AppColors.secondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (!line.available)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      line.unavailableReason ?? l10n.itemUnavailable,
                      style: AppTypography.labelSm.copyWith(color: AppColors.error),
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Fmt.moneyExact(line.lineTotalMinor),
                        style: AppTypography.labelLg.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    QuantityStepper(
                      value: line.quantity,
                      compact: true,
                      onChanged: onQuantity,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppImage(
            url: line.imageUrl,
            width: 76,
            height: 76,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ],
      ),
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
    required this.unavailableLabel,
  });

  final PaymentMethodOption option;
  final bool selected;
  final VoidCallback? onTap;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = option.usable;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.orangeTintSubtle : AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceContainer,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: enabled ? AppColors.surfaceContainerHigh : AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radius),
              ),
              child: Icon(
                _icon(option.method),
                size: 19,
                color: enabled ? AppColors.onSurface : AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label(L10n.of(context).isArabic),
                    style: AppTypography.labelMd.copyWith(
                      color: enabled ? AppColors.onSurface : AppColors.secondary,
                    ),
                  ),
                  if (!enabled && option.reason != null)
                    Text(
                      option.reason!,
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                    )
                  else if (!enabled)
                    Text(
                      unavailableLabel,
                      style: AppTypography.labelSm.copyWith(color: AppColors.secondary),
                    ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: selected ? AppColors.primary : AppColors.surfaceContainerHigh,
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String method) {
    return switch (method) {
      'wallet' => Icons.account_balance_wallet_outlined,
      'card_gateway' => Icons.credit_card,
      'manual_bank_transfer' => Icons.account_balance,
      _ => Icons.payments_outlined,
    };
  }
}

class _FreeDeliveryBanner extends StatelessWidget {
  const _FreeDeliveryBanner({required this.quote, required this.l10n});

  final CartQuote quote;
  final L10n l10n;

  @override
  Widget build(BuildContext context) {
    final saved = quote.deliveryFeeOriginalMinor - quote.deliveryFeeMinor;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _cardDecoration,
      child: Row(
        children: [
          const Icon(Icons.local_shipping, size: 20, color: AppColors.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              '${l10n.deliveryFeeFree} • ${Fmt.money(saved)}',
              style: AppTypography.labelMd,
            ),
          ),
          const Icon(Icons.check_circle, size: 18, color: AppColors.tertiary),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySm.copyWith(color: AppColors.onErrorContainer),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

final _cardDecoration = BoxDecoration(
  color: AppColors.surfaceContainerLowest,
  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
  border: Border.all(color: AppColors.surfaceContainerHigh),
  boxShadow: AppColors.cardShadow,
);
