import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design/app_spacing.dart';
import '../../core/localization/l10n.dart';
import '../../core/widgets/app_scaffold.dart';
import '../../core/widgets/snack.dart';
import '../../core/widgets/states.dart';
import '../../data/api/api_exception.dart';
import '../../data/models/account.dart';
import '../../data/models/cart.dart';
import '../../data/models/catalog.dart';
import '../../data/models/customer.dart';
import '../../state/account_controllers.dart';
import '../../state/address_controller.dart';
import '../../state/cart_controller.dart';
import '../../state/orders_controller.dart';
import '../../state/restaurant_detail_controller.dart';
import '../shared/headers.dart';
import '../shared/sheets.dart';
import 'widgets/checkout_address_card.dart';
import 'widgets/checkout_bottom_tray.dart';
import 'widgets/checkout_coupon_card.dart';
import 'widgets/checkout_free_delivery_banner.dart';
import 'widgets/checkout_fulfillment_card.dart';
import 'widgets/checkout_items_section.dart';
import 'widgets/checkout_notes_card.dart';
import 'widgets/checkout_notices.dart';
import 'widgets/checkout_payment_card.dart';
import 'widgets/checkout_restaurant_card.dart';
import 'widgets/checkout_summary_card.dart';
import 'widgets/checkout_trust_note.dart';

/// Cart & checkout rebuilt from the Stitch design: a pure white canvas with
/// hairline borders instead of shadows. All financial values still come from
/// the backend quote; the screen never computes totals locally.
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
  bool _quoteDirty = false;
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

  /// Fetches a fresh quote. Requests that arrive while one is in flight are
  /// coalesced into a single follow-up request so the screen never shows a
  /// stale total after a fast quantity change.
  Future<void> _refreshQuote() async {
    if (_quoting) {
      _quoteDirty = true;
      return;
    }
    final cart = ref.read(cartProvider).valueOrNull;
    if (cart == null || cart.lines.isEmpty) {
      if (mounted) {
        setState(() {
          _quote = null;
          _quoteError = null;
          _quoting = false;
          _quoteDirty = false;
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
      final usable =
          quote.paymentMethods.where((m) => m.usable).toList(growable: false);
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
    if (_quoteDirty && mounted) {
      _quoteDirty = false;
      await _refreshQuote();
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
    if (_useWalletSplit &&
        walletAvailable > 0 &&
        walletAvailable < quote.totalMinor) {
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
    if (_method == 'wallet' &&
        (wallet?.availableMinor ?? 0) < quote.totalMinor) {
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
    if (parts.isEmpty ||
        parts.fold<int>(0, (sum, p) => sum + p.amountMinor) !=
            quote.totalMinor) {
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

  Future<void> _changeQuantity(
    BuildContext context,
    L10n l10n,
    CartLine line,
    int quantity,
  ) async {
    try {
      await ref.read(cartProvider.notifier).changeQuantity(line, quantity);
      await _refreshQuote();
    } catch (error) {
      if (!context.mounted) return;
      showAppSnack(
        context,
        error is ApiException ? error.message : l10n.somethingWentWrong,
        isError: true,
      );
    }
  }

  Future<void> _removeLine(
    BuildContext context,
    L10n l10n,
    CartLine line,
  ) async {
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
  }

  /// Ignores quote-only updates so refreshing the quote never re-triggers the
  /// cart listener in a loop.
  String _cartSignature(CartResponse cart) {
    return [
      cart.restaurantId ?? '',
      for (final line in cart.lines)
        '${line.id}:${line.quantity}:${line.lineTotalMinor}:${line.available}',
    ].join('|');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = L10n.of(context);
    final cartAsync = ref.watch(cartProvider);
    final address = ref.watch(selectedAddressProvider);
    final wallet = ref.watch(walletProvider).valueOrNull;
    final cart = cartAsync.valueOrNull;
    final restaurantId = cart?.restaurantId;
    final detail = restaurantId == null
        ? null
        : ref.watch(restaurantDetailProvider(restaurantId)).valueOrNull;

    ref.listen(selectedAddressProvider, (previous, next) {
      if (previous?.id != next?.id) _refreshQuote();
    });
    ref.listen(cartProvider, (previous, next) {
      final before = previous?.valueOrNull;
      final after = next.valueOrNull;
      if (before == null || after == null) return;
      if (_cartSignature(before) != _cartSignature(after)) _refreshQuote();
    });

    final hasLines = cart != null && cart.lines.isNotEmpty;
    final quote = _quote;
    final canSubmit = quote != null &&
        quote.meetsMinimum &&
        address != null &&
        !_quoting &&
        !_placing &&
        _paymentValidation(quote) == null;

    return AppScaffold(
      header: SimpleHeader(
        title: l10n.checkoutTitle,
        onBack: () => context.pop(),
      ),
      bottomBar: hasLines
          ? CheckoutBottomTray(
              quote: quote,
              l10n: l10n,
              placing: _placing,
              enabled: canSubmit,
              onPressed: quote == null ? () {} : () => _placeOrder(quote),
            )
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
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _refreshQuote());
          }
          return _body(context, l10n, cart, address, detail, wallet);
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    L10n l10n,
    CartResponse cart,
    CustomerAddressRecord? address,
    CatalogRestaurantDetail? detail,
    WalletSummary? wallet,
  ) {
    final quote = _quote;
    final selectedAddress = address;
    final currency = quote?.currency ?? l10n.currencyDefault;
    final restaurantId = cart.restaurantId;
    VoidCallback? openMenu;
    if (restaurantId != null) {
      openMenu = () => context.push('/restaurants/$restaurantId');
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      children: [
        if (_quoteError != null)
          _section(
            CheckoutInlineError(
              message: _quoteError!,
              onRetry: _refreshQuote,
              retryLabel: l10n.retry,
            ),
            top: AppSpacing.lg,
          ),
        if (quote != null && quote.freeDeliveryApplied)
          _section(
            CheckoutFreeDeliveryBanner(quote: quote, l10n: l10n),
            top: AppSpacing.lg,
          ),
        _section(
          CheckoutRestaurantCard(
            cart: cart,
            detail: detail,
            l10n: l10n,
            onMenuTap: openMenu,
          ),
          top: AppSpacing.lg,
        ),
        _section(
          CheckoutItemsSection(
            cart: cart,
            currency: currency,
            l10n: l10n,
            onQuantity: (line, quantity) =>
                _changeQuantity(context, l10n, line, quantity),
            onRemove: (line) => _removeLine(context, l10n, line),
            onEdit: openMenu,
          ),
          top: AppSpacing.lg,
        ),
        _section(
          CheckoutFulfillmentCard(
            fulfillment: _fulfillment,
            l10n: l10n,
            onChanged: (value) {
              setState(() => _fulfillment = value);
              _refreshQuote();
            },
          ),
          top: AppSpacing.lg,
        ),
        _section(
          CheckoutNotesCard(controller: _noteController, l10n: l10n),
          top: AppSpacing.lg,
        ),
        _section(
          CheckoutCouponCard(
            controller: _couponController,
            quote: quote,
            l10n: l10n,
            quoting: _quoting,
            onApply: _applyCoupon,
            onRemove: _removeCoupon,
          ),
          top: AppSpacing.lg,
        ),
        _section(
          CheckoutAddressCard(
            address: selectedAddress,
            l10n: l10n,
            onChange: () => showAddressPicker(context),
            onEditInstructions: selectedAddress == null
                ? null
                : () => context.push(
                      '/account/addresses/${selectedAddress.id}/edit',
                    ),
          ),
          top: AppSpacing.lg,
        ),
        _section(
          CheckoutPaymentCard(
            quote: quote,
            wallet: wallet,
            method: _method,
            useWalletSplit: _useWalletSplit,
            referenceController: _referenceController,
            l10n: l10n,
            onSelect: (method) {
              setState(() {
                _method = method;
                _useWalletSplit = false;
              });
            },
            onSplitChanged: (value) {
              setState(() => _useWalletSplit = value);
            },
          ),
          top: AppSpacing.lg,
        ),
        _section(
          CheckoutSummaryCard(quote: quote, l10n: l10n),
          top: AppSpacing.lg,
        ),
        if (quote != null && quote.warnings.isNotEmpty)
          _section(
            CheckoutWarnings(warnings: quote.warnings),
            top: AppSpacing.lg,
          ),
        _section(CheckoutTrustNote(l10n: l10n), top: AppSpacing.lg),
      ],
    );
  }

  void _applyCoupon() {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() => _couponCode = code);
    _refreshQuote();
  }

  void _removeCoupon() {
    setState(() => _couponCode = '');
    _couponController.clear();
    _refreshQuote();
  }

  Widget _section(Widget child, {required double top}) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, top, AppSpacing.lg, 0),
      child: child,
    );
  }
}
