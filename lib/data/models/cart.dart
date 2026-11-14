import '../../core/utils/json.dart';

class CartLineOption {
  const CartLineOption({
    required this.groupId,
    required this.groupNameAr,
    required this.groupNameEn,
    required this.optionId,
    required this.nameAr,
    required this.nameEn,
    required this.priceDeltaMinor,
  });

  factory CartLineOption.fromJson(Map<String, dynamic> json) {
    return CartLineOption(
      groupId: asString(json['groupId']),
      groupNameAr: asString(json['groupNameAr']),
      groupNameEn: asString(json['groupNameEn']),
      optionId: asString(json['optionId']),
      nameAr: asString(json['nameAr']),
      nameEn: asString(json['nameEn']),
      priceDeltaMinor: asInt(json['priceDeltaMinor']),
    );
  }

  final String groupId;
  final String groupNameAr;
  final String groupNameEn;
  final String optionId;
  final String nameAr;
  final String nameEn;
  final int priceDeltaMinor;

  String name(bool arabic) => arabic ? nameAr : (nameEn.isEmpty ? nameAr : nameEn);
}

class CartLine {
  const CartLine({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.imageUrl,
    required this.quantity,
    required this.notes,
    required this.options,
    required this.unitBaseMinor,
    required this.unitOptionsMinor,
    required this.unitOriginalMinor,
    required this.unitTotalMinor,
    required this.offerDiscountMinor,
    required this.offerTitleAr,
    required this.offerTitleEn,
    required this.lineTotalMinor,
    required this.available,
    required this.unavailableReason,
  });

  factory CartLine.fromJson(Map<String, dynamic> json) {
    final unitBaseMinor = asInt(json['unitBaseMinor']);
    final unitOptionsMinor = asInt(json['unitOptionsMinor']);
    return CartLine(
      id: asString(json['id']),
      menuItemId: asString(json['menuItemId']),
      name: asString(json['name']),
      imageUrl: asStringOrNull(json['imageUrl']),
      quantity: asInt(json['quantity'], 1),
      notes: asString(json['notes']),
      options: mapList(json['options'], CartLineOption.fromJson),
      unitBaseMinor: unitBaseMinor,
      unitOptionsMinor: unitOptionsMinor,
      unitOriginalMinor: asInt(
        json['unitOriginalMinor'],
        unitBaseMinor + unitOptionsMinor,
      ),
      unitTotalMinor: asInt(json['unitTotalMinor']),
      offerDiscountMinor: asInt(json['offerDiscountMinor']),
      offerTitleAr: asStringOrNull(json['offerTitleAr']),
      offerTitleEn: asStringOrNull(json['offerTitleEn']),
      lineTotalMinor: asInt(json['lineTotalMinor']),
      available: asBool(json['available'], true),
      unavailableReason: asStringOrNull(json['unavailableReason']),
    );
  }

  final String id;
  final String menuItemId;
  final String name;
  final String? imageUrl;
  final int quantity;
  final String notes;
  final List<CartLineOption> options;
  final int unitBaseMinor;
  final int unitOptionsMinor;
  final int unitOriginalMinor;
  final int unitTotalMinor;
  final int offerDiscountMinor;
  final String? offerTitleAr;
  final String? offerTitleEn;
  final int lineTotalMinor;
  final bool available;
  final String? unavailableReason;

  String optionsSummary(bool arabic) => options.map((o) => o.name(arabic)).join(' • ');

  bool get hasOffer => unitOriginalMinor > unitTotalMinor;
  int get unitDiscountMinor => unitOriginalMinor - unitTotalMinor;

  String? offerTitle(bool arabic) {
    final ar = offerTitleAr ?? '';
    final en = offerTitleEn ?? '';
    final value = arabic ? ar : (en.isEmpty ? ar : en);
    return value.isEmpty ? null : value;
  }
}

class AppliedCoupon {
  const AppliedCoupon({
    required this.code,
    required this.discountMinor,
    required this.description,
  });

  factory AppliedCoupon.fromJson(Map<String, dynamic> json) {
    return AppliedCoupon(
      code: asString(json['code']),
      discountMinor: asInt(json['discountMinor']),
      description: asString(json['description']),
    );
  }

  final String code;
  final int discountMinor;
  final String description;
}

class PaymentMethodOption {
  const PaymentMethodOption({
    required this.method,
    required this.enabled,
    required this.available,
    required this.reason,
    required this.labelAr,
    required this.labelEn,
    required this.requiresReference,
  });

  factory PaymentMethodOption.fromJson(Map<String, dynamic> json) {
    return PaymentMethodOption(
      method: asString(json['method']),
      enabled: asBool(json['enabled']),
      available: asBool(json['available']),
      reason: asStringOrNull(json['reason']),
      labelAr: asString(json['labelAr']),
      labelEn: asString(json['labelEn']),
      requiresReference: asBool(json['requiresReference']),
    );
  }

  final String method;
  final bool enabled;
  final bool available;
  final String? reason;
  final String labelAr;
  final String labelEn;
  final bool requiresReference;

  String label(bool arabic) => arabic ? labelAr : (labelEn.isEmpty ? labelAr : labelEn);
  bool get usable => enabled && available;
}

class CartQuote {
  const CartQuote({
    required this.currency,
    required this.restaurantId,
    required this.restaurantName,
    required this.branchId,
    required this.lines,
    required this.itemCount,
    required this.subtotalMinor,
    required this.subtotalOriginalMinor,
    required this.offerDiscountMinor,
    required this.deliveryFeeMinor,
    required this.deliveryFeeOriginalMinor,
    required this.discountMinor,
    required this.vatMinor,
    required this.totalMinor,
    required this.minOrderMinor,
    required this.meetsMinimum,
    required this.freeDeliveryApplied,
    required this.coupon,
    required this.couponError,
    required this.taxMode,
    required this.taxRateBasisPoints,
    required this.fulfillment,
    required this.scheduledFor,
    required this.paymentMethods,
    required this.warnings,
  });

  factory CartQuote.fromJson(Map<String, dynamic> json) {
    return CartQuote(
      currency: asString(json['currency'], 'SAR'),
      restaurantId: asStringOrNull(json['restaurantId']),
      restaurantName: asStringOrNull(json['restaurantName']),
      branchId: asStringOrNull(json['branchId']),
      lines: mapList(json['lines'], CartLine.fromJson),
      itemCount: asInt(json['itemCount']),
      subtotalMinor: asInt(json['subtotalMinor']),
      subtotalOriginalMinor: asInt(
        json['subtotalOriginalMinor'],
        asInt(json['subtotalMinor']),
      ),
      offerDiscountMinor: asInt(json['offerDiscountMinor']),
      deliveryFeeMinor: asInt(json['deliveryFeeMinor']),
      deliveryFeeOriginalMinor: asInt(json['deliveryFeeOriginalMinor']),
      discountMinor: asInt(json['discountMinor']),
      vatMinor: asInt(json['vatMinor']),
      totalMinor: asInt(json['totalMinor']),
      minOrderMinor: asInt(json['minOrderMinor']),
      meetsMinimum: asBool(json['meetsMinimum'], true),
      freeDeliveryApplied: asBool(json['freeDeliveryApplied']),
      coupon: json['coupon'] == null ? null : AppliedCoupon.fromJson(asMap(json['coupon'])),
      couponError: asStringOrNull(json['couponError']),
      taxMode: asString(json['taxMode'], 'inclusive'),
      taxRateBasisPoints: asInt(json['taxRateBasisPoints']),
      fulfillment: asString(json['fulfillment'], 'delivery'),
      scheduledFor: asStringOrNull(json['scheduledFor']),
      paymentMethods: mapList(json['paymentMethods'], PaymentMethodOption.fromJson),
      warnings: (json['warnings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  final String currency;
  final String? restaurantId;
  final String? restaurantName;
  final String? branchId;
  final List<CartLine> lines;
  final int itemCount;
  final int subtotalMinor;
  final int subtotalOriginalMinor;
  final int offerDiscountMinor;
  final int deliveryFeeMinor;
  final int deliveryFeeOriginalMinor;
  final int discountMinor;
  final int vatMinor;
  final int totalMinor;
  final int minOrderMinor;
  final bool meetsMinimum;
  final bool freeDeliveryApplied;
  final AppliedCoupon? coupon;
  final String? couponError;
  final String taxMode;
  final int taxRateBasisPoints;
  final String fulfillment;
  final String? scheduledFor;
  final List<PaymentMethodOption> paymentMethods;
  final List<String> warnings;

  bool get isEmpty => lines.isEmpty;
  int get remainingForMinimum =>
      meetsMinimum ? 0 : (minOrderMinor - subtotalMinor).clamp(0, minOrderMinor);
}

class CartResponse {
  const CartResponse({
    required this.cartId,
    required this.restaurantId,
    required this.restaurantName,
    required this.lines,
    required this.itemCount,
    required this.updatedAt,
    required this.quote,
  });

  factory CartResponse.fromJson(Map<String, dynamic> json) {
    return CartResponse(
      cartId: asStringOrNull(json['cartId']),
      restaurantId: asStringOrNull(json['restaurantId']),
      restaurantName: asStringOrNull(json['restaurantName']),
      lines: mapList(json['lines'], CartLine.fromJson),
      itemCount: asInt(json['itemCount']),
      updatedAt: asStringOrNull(json['updatedAt']),
      quote: json['quote'] == null ? null : CartQuote.fromJson(asMap(json['quote'])),
    );
  }

  final String? cartId;
  final String? restaurantId;
  final String? restaurantName;
  final List<CartLine> lines;
  final int itemCount;
  final String? updatedAt;
  final CartQuote? quote;

  bool get isEmpty => lines.isEmpty;
}

/// A payment part chosen by the customer at checkout.
class PaymentPartRequest {
  const PaymentPartRequest({
    required this.method,
    required this.amountMinor,
    this.reference,
  });

  final String method;
  final int amountMinor;
  final String? reference;

  Map<String, dynamic> toJson() => {
        'method': method,
        'amountMinor': amountMinor,
        if (reference != null && reference!.isNotEmpty) 'reference': reference,
      };
}

class PaymentPart {
  const PaymentPart({
    required this.id,
    required this.method,
    required this.amountMinor,
    required this.status,
    required this.reference,
  });

  factory PaymentPart.fromJson(Map<String, dynamic> json) {
    return PaymentPart(
      id: asString(json['id']),
      method: asString(json['method']),
      amountMinor: asInt(json['amountMinor']),
      status: asString(json['status'], 'pending'),
      reference: asString(json['reference']),
    );
  }

  final String id;
  final String method;
  final int amountMinor;
  final String status;
  final String reference;
}

class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.reference,
    required this.status,
    required this.paymentStatus,
    required this.totalMinor,
    required this.currency,
    required this.paidMinor,
    required this.remainingMinor,
    required this.payments,
  });

  factory CheckoutResult.fromJson(Map<String, dynamic> json) {
    return CheckoutResult(
      orderId: asString(json['orderId']),
      reference: asString(json['reference']),
      status: asString(json['status'], 'awaiting_confirmation'),
      paymentStatus: asString(json['paymentStatus'], 'pending'),
      totalMinor: asInt(json['totalMinor']),
      currency: asString(json['currency'], 'SAR'),
      paidMinor: asInt(json['paidMinor']),
      remainingMinor: asInt(json['remainingMinor']),
      payments: mapList(json['payments'], PaymentPart.fromJson),
    );
  }

  final String orderId;
  final String reference;
  final String status;
  final String paymentStatus;
  final int totalMinor;
  final String currency;
  final int paidMinor;
  final int remainingMinor;
  final List<PaymentPart> payments;
}

/// Quote request parameters shared by quote and checkout.
class QuoteRequest {
  const QuoteRequest({
    this.addressId,
    this.couponCode,
    this.fulfillment = 'delivery',
    this.scheduledFor,
  });

  final String? addressId;
  final String? couponCode;
  final String fulfillment;
  final String? scheduledFor;

  Map<String, dynamic> toJson() => {
        if (addressId != null && addressId!.isNotEmpty) 'addressId': addressId,
        if (couponCode != null && couponCode!.isNotEmpty) 'couponCode': couponCode,
        'fulfillment': fulfillment,
        if (scheduledFor != null && scheduledFor!.isNotEmpty) 'scheduledFor': scheduledFor,
      };
}

class CheckoutRequest extends QuoteRequest {
  const CheckoutRequest({
    required super.addressId,
    super.couponCode,
    super.fulfillment,
    super.scheduledFor,
    required this.paymentParts,
    required this.note,
    required this.idempotencyKey,
  });

  final List<PaymentPartRequest> paymentParts;
  final String note;
  final String idempotencyKey;

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'addressId': addressId,
        'paymentParts': paymentParts.map((p) => p.toJson()).toList(),
        if (note.isNotEmpty) 'note': note,
        'idempotencyKey': idempotencyKey,
      };
}
