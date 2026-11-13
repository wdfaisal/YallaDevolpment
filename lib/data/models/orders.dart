import '../../core/utils/json.dart';
import 'cart.dart';

class OrderSummary {
  const OrderSummary({
    required this.id,
    required this.reference,
    required this.restaurantId,
    required this.restaurantName,
    required this.restaurantLogoUrl,
    required this.status,
    required this.statusLabelAr,
    required this.statusLabelEn,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.totalMinor,
    required this.currency,
    required this.itemCount,
    required this.placedAt,
    required this.deliveredAt,
    required this.canCancel,
    required this.canRate,
    required this.canReorder,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    return OrderSummary(
      id: asString(json['id']),
      reference: asString(json['reference']),
      restaurantId: asStringOrNull(json['restaurantId']),
      restaurantName: asStringOrNull(json['restaurantName']),
      restaurantLogoUrl: asStringOrNull(json['restaurantLogoUrl']),
      status: asString(json['status'], 'draft'),
      statusLabelAr: asString(json['statusLabelAr']),
      statusLabelEn: asString(json['statusLabelEn']),
      paymentStatus: asString(json['paymentStatus'], 'pending'),
      paymentMethod: asString(json['paymentMethod']),
      totalMinor: asInt(json['totalMinor']),
      currency: asString(json['currency'], 'SAR'),
      itemCount: asInt(json['itemCount']),
      placedAt: asString(json['placedAt']),
      deliveredAt: asStringOrNull(json['deliveredAt']),
      canCancel: asBool(json['canCancel']),
      canRate: asBool(json['canRate']),
      canReorder: asBool(json['canReorder']),
    );
  }

  final String id;
  final String reference;
  final String? restaurantId;
  final String? restaurantName;
  final String? restaurantLogoUrl;
  final String status;
  final String statusLabelAr;
  final String statusLabelEn;
  final String paymentStatus;
  final String paymentMethod;
  final int totalMinor;
  final String currency;
  final int itemCount;
  final String placedAt;
  final String? deliveredAt;
  final bool canCancel;
  final bool canRate;
  final bool canReorder;

  String statusLabel(bool arabic) =>
      arabic ? statusLabelAr : (statusLabelEn.isEmpty ? statusLabelAr : statusLabelEn);
  bool get isActive => !const {'delivered', 'cancelled', 'failed_delivery'}.contains(status);
}

class OrderItemLine {
  const OrderItemLine({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.unitPriceMinor,
    required this.lineTotalMinor,
    required this.options,
    required this.notes,
  });

  factory OrderItemLine.fromJson(Map<String, dynamic> json) {
    return OrderItemLine(
      id: asString(json['id']),
      menuItemId: asStringOrNull(json['menuItemId']),
      name: asString(json['name']),
      quantity: asInt(json['quantity'], 1),
      unitPriceMinor: asInt(json['unitPriceMinor']),
      lineTotalMinor: asInt(json['lineTotalMinor']),
      options: asString(json['options']),
      notes: asString(json['notes']),
    );
  }

  final String id;
  final String? menuItemId;
  final String name;
  final int quantity;
  final int unitPriceMinor;
  final int lineTotalMinor;
  final String options;
  final String notes;
}

class GeoPoint {
  const GeoPoint({required this.lat, required this.lng});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(lat: asDouble(json['lat']), lng: asDouble(json['lng']));
  }

  final double lat;
  final double lng;
}

class DriverTracking {
  const DriverTracking({
    required this.id,
    required this.name,
    required this.initials,
    required this.vehicle,
    required this.plate,
    required this.rating,
    required this.phone,
    required this.position,
    required this.lastSignalAt,
    required this.stale,
  });

  factory DriverTracking.fromJson(Map<String, dynamic> json) {
    return DriverTracking(
      id: asString(json['id']),
      name: asString(json['name']),
      initials: asString(json['initials']),
      vehicle: asString(json['vehicle']),
      plate: asString(json['plate']),
      rating: asDouble(json['rating']),
      phone: asStringOrNull(json['phone']),
      position: json['position'] == null ? null : GeoPoint.fromJson(asMap(json['position'])),
      lastSignalAt: asStringOrNull(json['lastSignalAt']),
      stale: asBool(json['stale']),
    );
  }

  final String id;
  final String name;
  final String initials;
  final String vehicle;
  final String plate;
  final double rating;
  final String? phone;
  final GeoPoint? position;
  final String? lastSignalAt;
  final bool stale;
}

class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.time,
    required this.at,
    required this.title,
    required this.detail,
    required this.actor,
    required this.state,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      id: asString(json['id']),
      time: asString(json['time']),
      at: asString(json['at']),
      title: asString(json['title']),
      detail: asStringOrNull(json['detail']),
      actor: asStringOrNull(json['actor']),
      state: asString(json['state']),
    );
  }

  final String id;
  final String time;
  final String at;
  final String title;
  final String? detail;
  final String? actor;
  final String state;
}

class OrderTracking {
  const OrderTracking({
    required this.status,
    required this.driver,
    required this.etaMinutes,
    required this.events,
  });

  factory OrderTracking.fromJson(Map<String, dynamic> json) {
    return OrderTracking(
      status: asString(json['status']),
      driver: json['driver'] == null ? null : DriverTracking.fromJson(asMap(json['driver'])),
      etaMinutes: asIntOrNull(json['etaMinutes']),
      events: mapList(json['events'], TimelineEvent.fromJson),
    );
  }

  final String status;
  final DriverTracking? driver;
  final int? etaMinutes;
  final List<TimelineEvent> events;
}

class OrderRating {
  const OrderRating({required this.restaurant, required this.driver});

  factory OrderRating.fromJson(Map<String, dynamic> json) {
    return OrderRating(
      restaurant: asIntOrNull(json['restaurant']),
      driver: asIntOrNull(json['driver']),
    );
  }

  final int? restaurant;
  final int? driver;

  bool get isEmpty => restaurant == null && driver == null;
}

class OrderDetail {
  const OrderDetail({
    required this.summary,
    required this.items,
    required this.subtotalMinor,
    required this.deliveryFeeMinor,
    required this.vatMinor,
    required this.discountMinor,
    required this.deliveryAddress,
    required this.deliveryPosition,
    required this.note,
    required this.couponCode,
    required this.payments,
    required this.tracking,
    required this.rating,
    required this.scheduledFor,
    required this.fulfillment,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    return OrderDetail(
      summary: OrderSummary.fromJson(asMap(json['summary'])),
      items: mapList(json['items'], OrderItemLine.fromJson),
      subtotalMinor: asInt(json['subtotalMinor']),
      deliveryFeeMinor: asInt(json['deliveryFeeMinor']),
      vatMinor: asInt(json['vatMinor']),
      discountMinor: asInt(json['discountMinor']),
      deliveryAddress: asString(json['deliveryAddress']),
      deliveryPosition:
          json['deliveryPosition'] == null ? null : GeoPoint.fromJson(asMap(json['deliveryPosition'])),
      note: asString(json['note']),
      couponCode: asStringOrNull(json['couponCode']),
      payments: mapList(json['payments'], PaymentPart.fromJson),
      tracking: OrderTracking.fromJson(asMap(json['tracking'])),
      rating: json['rating'] == null ? null : OrderRating.fromJson(asMap(json['rating'])),
      scheduledFor: asStringOrNull(json['scheduledFor']),
      fulfillment: asString(json['fulfillment'], 'delivery'),
    );
  }

  final OrderSummary summary;
  final List<OrderItemLine> items;
  final int subtotalMinor;
  final int deliveryFeeMinor;
  final int vatMinor;
  final int discountMinor;
  final String deliveryAddress;
  final GeoPoint? deliveryPosition;
  final String note;
  final String? couponCode;
  final List<PaymentPart> payments;
  final OrderTracking tracking;
  final OrderRating? rating;
  final String? scheduledFor;
  final String fulfillment;
}

class OrderList {
  const OrderList({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
  });

  factory OrderList.fromJson(Map<String, dynamic> json) {
    return OrderList(
      items: mapList(json['items'], OrderSummary.fromJson),
      page: asInt(json['page'], 1),
      pageSize: asInt(json['pageSize'], 20),
      total: asInt(json['total']),
      hasMore: asBool(json['hasMore']),
    );
  }

  final List<OrderSummary> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
}
