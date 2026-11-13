import '../../core/utils/json.dart';
import 'catalog.dart';

class WalletEntry {
  const WalletEntry({
    required this.id,
    required this.kind,
    required this.amountMinor,
    required this.reference,
    required this.note,
    required this.createdAt,
  });

  factory WalletEntry.fromJson(Map<String, dynamic> json) {
    return WalletEntry(
      id: asString(json['id']),
      kind: asString(json['kind']),
      amountMinor: asInt(json['amountMinor']),
      reference: asStringOrNull(json['reference']),
      note: asStringOrNull(json['note']),
      createdAt: asString(json['createdAt']),
    );
  }

  final String id;
  final String kind;
  final int amountMinor;
  final String? reference;
  final String? note;
  final String createdAt;
}

class WalletSummary {
  const WalletSummary({
    required this.availableMinor,
    required this.heldMinor,
    required this.currency,
    required this.entries,
  });

  factory WalletSummary.fromJson(Map<String, dynamic> json) {
    return WalletSummary(
      availableMinor: asInt(json['availableMinor']),
      heldMinor: asInt(json['heldMinor']),
      currency: asString(json['currency'], 'SAR'),
      entries: mapList(json['entries'], WalletEntry.fromJson),
    );
  }

  final int availableMinor;
  final int heldMinor;
  final String currency;
  final List<WalletEntry> entries;
}

class LoyaltyEntry {
  const LoyaltyEntry({
    required this.id,
    required this.pointsDelta,
    required this.reason,
    required this.orderId,
    required this.createdAt,
  });

  factory LoyaltyEntry.fromJson(Map<String, dynamic> json) {
    return LoyaltyEntry(
      id: asString(json['id']),
      pointsDelta: asInt(json['pointsDelta']),
      reason: asString(json['reason']),
      orderId: asStringOrNull(json['orderId']),
      createdAt: asString(json['createdAt']),
    );
  }

  final String id;
  final int pointsDelta;
  final String reason;
  final String? orderId;
  final String createdAt;
}

class LoyaltySummary {
  const LoyaltySummary({required this.points, required this.entries});

  factory LoyaltySummary.fromJson(Map<String, dynamic> json) {
    return LoyaltySummary(
      points: asInt(json['points']),
      entries: mapList(json['entries'], LoyaltyEntry.fromJson),
    );
  }

  final int points;
  final List<LoyaltyEntry> entries;
}

class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.kind,
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.data,
    required this.readAt,
    required this.createdAt,
  });

  factory CustomerNotification.fromJson(Map<String, dynamic> json) {
    return CustomerNotification(
      id: asString(json['id']),
      kind: asString(json['kind']),
      titleAr: asString(json['titleAr']),
      titleEn: asString(json['titleEn']),
      bodyAr: asString(json['bodyAr']),
      bodyEn: asString(json['bodyEn']),
      data: asMapOrNull(json['data']),
      readAt: asStringOrNull(json['readAt']),
      createdAt: asString(json['createdAt']),
    );
  }

  final String id;
  final String kind;
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final Map<String, dynamic>? data;
  final String? readAt;
  final String createdAt;

  bool get isUnread => readAt == null;
  String title(bool arabic) => arabic ? titleAr : (titleEn.isEmpty ? titleAr : titleEn);
  String body(bool arabic) => arabic ? bodyAr : (bodyEn.isEmpty ? bodyAr : bodyEn);
  String? get orderId => data == null ? null : asStringOrNull(data!['orderId']);
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
    required this.unreadCount,
  });

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    return NotificationPage(
      items: mapList(json['items'], CustomerNotification.fromJson),
      page: asInt(json['page'], 1),
      pageSize: asInt(json['pageSize'], 30),
      total: asInt(json['total']),
      hasMore: asBool(json['hasMore']),
      unreadCount: asInt(json['unreadCount']),
    );
  }

  final List<CustomerNotification> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
  final int unreadCount;
}

class FavoriteRecord {
  const FavoriteRecord({
    required this.id,
    required this.targetType,
    required this.targetId,
    required this.createdAt,
    required this.restaurant,
    required this.menuItem,
  });

  factory FavoriteRecord.fromJson(Map<String, dynamic> json) {
    return FavoriteRecord(
      id: asString(json['id']),
      targetType: asString(json['targetType']),
      targetId: asString(json['targetId']),
      createdAt: asString(json['createdAt']),
      restaurant:
          json['restaurant'] == null ? null : CatalogRestaurant.fromJson(asMap(json['restaurant'])),
      menuItem:
          json['menuItem'] == null ? null : CatalogMenuItem.fromJson(asMap(json['menuItem'])),
    );
  }

  final String id;
  final String targetType;
  final String targetId;
  final String createdAt;
  final CatalogRestaurant? restaurant;
  final CatalogMenuItem? menuItem;

  bool get isRestaurant => targetType == 'restaurant';
}

class TicketMessage {
  const TicketMessage({
    required this.id,
    required this.author,
    required this.body,
    required this.at,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: asInt(json['id']),
      author: asString(json['author']),
      body: asString(json['body']),
      at: asString(json['at']),
    );
  }

  final int id;
  final String author;
  final String body;
  final String at;

  bool get isCustomer => author == 'customer';
}

class SupportTicket {
  const SupportTicket({
    required this.id,
    required this.reference,
    required this.orderId,
    required this.orderReference,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.messages,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: asString(json['id']),
      reference: asString(json['reference']),
      orderId: asStringOrNull(json['orderId']),
      orderReference: asStringOrNull(json['orderReference']),
      subject: asString(json['subject']),
      description: asString(json['description']),
      status: asString(json['status'], 'open'),
      priority: asString(json['priority'], 'normal'),
      category: asString(json['category'], 'general'),
      createdAt: asString(json['createdAt']),
      updatedAt: asString(json['updatedAt']),
      messages: mapList(json['messages'], TicketMessage.fromJson),
    );
  }

  final String id;
  final String reference;
  final String? orderId;
  final String? orderReference;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String category;
  final String createdAt;
  final String updatedAt;
  final List<TicketMessage> messages;

  bool get isOpen => status != 'closed' && status != 'resolved';
}

class RatingResult {
  const RatingResult({
    required this.orderId,
    required this.restaurant,
    required this.driver,
  });

  factory RatingResult.fromJson(Map<String, dynamic> json) {
    return RatingResult(
      orderId: asString(json['orderId']),
      restaurant: asIntOrNull(json['restaurant']),
      driver: asIntOrNull(json['driver']),
    );
  }

  final String orderId;
  final int? restaurant;
  final int? driver;
}
