import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/data/models/account.dart';
import 'package:yalla_talabat_customer/data/models/cart.dart';
import 'package:yalla_talabat_customer/data/models/catalog.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';

void main() {
  test('CustomerProfile parses the auth payload', () {
    final profile = CustomerProfile.fromJson({
      'id': 'cus_1',
      'name': 'أحمد',
      'initials': 'أ',
      'phone': '+249900000000',
      'email': 'a@example.com',
      'language': 'en',
      'avatarUrl': null,
      'status': 'active',
      'memberSince': '2026-01-01T00:00:00.000Z',
      'orderCount': 3,
      'defaultAddress': {
        'id': 'addr_1',
        'label': 'Home',
        'address': 'Street 1',
        'lat': 15.5,
        'lng': 32.5,
        'isDefault': true,
      },
    });

    expect(profile.id, 'cus_1');
    expect(profile.isArabic, isFalse);
    expect(profile.isSuspended, isFalse);
    expect(profile.orderCount, 3);
    expect(profile.defaultAddress?.label, 'Home');
    expect(profile.defaultAddress?.hasPosition, isTrue);
  });

  test('CustomerAddressRecord keeps the extended fields', () {
    final record = CustomerAddressRecord.fromJson({
      'id': 'addr_1',
      'label': 'Work',
      'address': 'Street 2',
      'lat': null,
      'lng': null,
      'isDefault': false,
      'instructions': 'Call on arrival',
      'zoneId': 'zone_1',
      'cityId': 'city_1',
      'updatedAt': '2026-01-02T00:00:00.000Z',
    });

    expect(record.instructions, 'Call on arrival');
    expect(record.zoneId, 'zone_1');
    expect(record.hasPosition, isFalse);
  });

  test('CatalogRestaurant parses status and fees', () {
    final restaurant = CatalogRestaurant.fromJson({
      'id': 'res_1',
      'name': 'Food Villa',
      'cuisine': 'Fast food',
      'rating': 4.5,
      'ratingCount': 120,
      'logoUrl': null,
      'bannerUrl': null,
      'accepting': true,
      'openNow': false,
      'statusLabel': 'closed',
      'prepMinutes': 20,
      'distanceKm': 1.8,
      'deliveryFeeMinor': 1500,
      'minOrderMinor': 5000,
      'etaMinutes': 35,
      'offerCount': 2,
      'categories': ['برجر', 'بيتزا'],
    });

    expect(restaurant.name, 'Food Villa');
    expect(restaurant.isOpen, isFalse);
    expect(restaurant.deliveryFeeMinor, 1500);
    expect(restaurant.categories, hasLength(2));
  });

  test('CatalogOffer parses nested items', () {
    final offer = CatalogOffer.fromJson({
      'id': 'offer_1',
      'restaurantId': 'res_1',
      'restaurantName': 'Food Villa',
      'titleAr': 'خصم 20%',
      'titleEn': '20% off',
      'descriptionAr': 'وصف',
      'descriptionEn': 'Description',
      'imageUrl': null,
      'discountType': 'percentage',
      'discountValue': 20,
      'endsAt': '2026-12-31T00:00:00.000Z',
      'items': [
        {
          'id': 'oi_1',
          'menuItemId': 'item_1',
          'name': 'Burger',
          'nameAr': 'برجر',
          'nameEn': 'Burger',
          'priceMinor': 2000,
        },
      ],
    });

    expect(offer.title(true), 'خصم 20%');
    expect(offer.title(false), '20% off');
    expect(offer.items.single.displayName(false), 'Burger');
  });

  test('CartQuote parses lines, coupon and minimum shortfall', () {
    final quote = CartQuote.fromJson({
      'currency': 'SAR',
      'restaurantId': 'res_1',
      'restaurantName': 'Food Villa',
      'branchId': null,
      'lines': [
        {
          'id': 'line_1',
          'menuItemId': 'item_1',
          'name': 'Burger',
          'imageUrl': null,
          'quantity': 2,
          'notes': '',
          'options': [
            {
              'groupId': 'g1',
              'groupNameAr': 'إضافات',
              'groupNameEn': 'Extras',
              'optionId': 'o1',
              'nameAr': 'جبن',
              'nameEn': 'Cheese',
              'priceDeltaMinor': 300,
            },
          ],
          'unitBaseMinor': 2000,
          'unitOptionsMinor': 300,
          'unitTotalMinor': 2300,
          'lineTotalMinor': 4600,
          'available': true,
        },
      ],
      'itemCount': 2,
      'subtotalMinor': 4600,
      'deliveryFeeMinor': 0,
      'deliveryFeeOriginalMinor': 1500,
      'discountMinor': 500,
      'vatMinor': 690,
      'totalMinor': 4790,
      'minOrderMinor': 5000,
      'meetsMinimum': false,
      'freeDeliveryApplied': true,
      'coupon': {'code': 'SAVE5', 'discountMinor': 500, 'description': 'خصم'},
      'couponError': null,
      'taxMode': 'exclusive',
      'taxRateBasisPoints': 1500,
      'fulfillment': 'delivery',
      'scheduledFor': null,
      'paymentMethods': [
        {
          'method': 'cash_on_delivery',
          'enabled': true,
          'available': true,
          'reason': null,
          'labelAr': 'نقداً',
          'labelEn': 'Cash',
          'requiresReference': false,
        },
      ],
      'warnings': ['coupon minimum not met'],
    });

    expect(quote.lines.single.optionsSummary(false), 'Cheese');
    expect(quote.itemCount, 2);
    expect(quote.freeDeliveryApplied, isTrue);
    expect(quote.coupon?.code, 'SAVE5');
    expect(quote.remainingForMinimum, 400);
    expect(quote.paymentMethods.single.usable, isTrue);
    expect(quote.warnings, hasLength(1));
  });

  test('NotificationPage exposes unread state and linked order', () {
    final page = NotificationPage.fromJson({
      'items': [
        {
          'id': 'n1',
          'kind': 'order_status',
          'titleAr': 'تم التأكيد',
          'titleEn': 'Confirmed',
          'bodyAr': 'طلبك قيد التحضير',
          'bodyEn': 'Your order is being prepared',
          'data': {'orderId': 'ord_1'},
          'readAt': null,
          'createdAt': '2026-01-02T00:00:00.000Z',
        },
      ],
      'page': 1,
      'pageSize': 30,
      'total': 1,
      'hasMore': false,
      'unreadCount': 1,
    });

    expect(page.items.single.isUnread, isTrue);
    expect(page.items.single.orderId, 'ord_1');
    expect(page.items.single.title(false), 'Confirmed');
    expect(page.unreadCount, 1);
  });

  test('SupportTicket flags open and resolved states', () {
    Map<String, dynamic> json(String status) => {
          'id': 't1',
          'reference': 'TCK-1',
          'orderId': 'ord_1',
          'orderReference': 'ORD-1',
          'subject': 'Late order',
          'description': 'It is late',
          'status': status,
          'priority': 'high',
          'category': 'order',
          'createdAt': '2026-01-02T00:00:00.000Z',
          'updatedAt': '2026-01-02T00:00:00.000Z',
          'messages': [
            {
              'id': 1,
              'author': 'customer',
              'body': 'Hello',
              'at': '2026-01-02T00:00:00.000Z',
            },
          ],
        };

    final open = SupportTicket.fromJson(json('open'));
    final resolved = SupportTicket.fromJson(json('resolved'));

    expect(open.isOpen, isTrue);
    expect(resolved.isOpen, isFalse);
    expect(open.messages.single.isCustomer, isTrue);
  });
}
