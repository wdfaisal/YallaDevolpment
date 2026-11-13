import '../../core/utils/json.dart';
import 'catalog.dart';
import 'customer.dart';

class SearchConfig {
  const SearchConfig({
    required this.minQueryLength,
    required this.debounceMs,
    required this.suggestionLimit,
    required this.pageSize,
    required this.historyRetentionDays,
  });

  factory SearchConfig.fromJson(Map<String, dynamic> json) {
    return SearchConfig(
      minQueryLength: asInt(json['minQueryLength'], 2),
      debounceMs: asInt(json['debounceMs'], 300),
      suggestionLimit: asInt(json['suggestionLimit'], 8),
      pageSize: asInt(json['pageSize'], 20),
      historyRetentionDays: asInt(json['historyRetentionDays'], 30),
    );
  }

  final int minQueryLength;
  final int debounceMs;
  final int suggestionLimit;
  final int pageSize;
  final int historyRetentionDays;
}

class SearchSuggestion {
  const SearchSuggestion({
    required this.kind,
    required this.text,
    required this.targetId,
  });

  factory SearchSuggestion.fromJson(Map<String, dynamic> json) {
    return SearchSuggestion(
      kind: asString(json['kind'], 'term'),
      text: asString(json['text']),
      targetId: asStringOrNull(json['targetId']),
    );
  }

  final String kind;
  final String text;
  final String? targetId;

  bool get isTerm => kind == 'term';
  bool get isRestaurant => kind == 'restaurant';
  bool get isMenuItem => kind == 'menu_item';
}

class SearchSuggestions {
  const SearchSuggestions({required this.query, required this.suggestions});

  factory SearchSuggestions.fromJson(Map<String, dynamic> json) {
    return SearchSuggestions(
      query: asString(json['query']),
      suggestions: mapList(json['suggestions'], SearchSuggestion.fromJson),
    );
  }

  final String query;
  final List<SearchSuggestion> suggestions;
}

class SearchResults {
  const SearchResults({
    required this.query,
    required this.restaurants,
    required this.items,
    required this.meta,
  });

  factory SearchResults.fromJson(Map<String, dynamic> json) {
    return SearchResults(
      query: asString(json['query']),
      restaurants: mapList(json['restaurants'], CatalogRestaurant.fromJson),
      items: mapList(json['items'], CatalogMenuItem.fromJson),
      meta: CatalogRestaurantList.fromJson(asMap(json['meta'])),
    );
  }

  final String query;
  final List<CatalogRestaurant> restaurants;
  final List<CatalogMenuItem> items;
  final CatalogRestaurantList meta;

  bool get isEmpty => restaurants.isEmpty && items.isEmpty;
}

class SearchHistoryItem {
  const SearchHistoryItem({
    required this.id,
    required this.query,
    required this.createdAt,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: asString(json['id']),
      query: asString(json['query']),
      createdAt: asString(json['createdAt']),
    );
  }

  final String id;
  final String query;
  final String createdAt;
}

/// Query object for the restaurant list, mirroring the backend schema.
class RestaurantQuery {
  const RestaurantQuery({
    this.addressId,
    this.lat,
    this.lng,
    this.page = 1,
    this.pageSize = 20,
    this.sort = 'recommended',
    this.categoryIds = const [],
    this.minRating,
    this.openNow,
    this.maxDistanceKm,
    this.maxDeliveryMinutes,
    this.freeDelivery,
    this.maxDeliveryFeeMinor,
    this.hasOffers,
    this.maxMinOrderMinor,
    this.search,
  });

  final String? addressId;
  final double? lat;
  final double? lng;
  final int page;
  final int pageSize;
  final String sort;
  final List<String> categoryIds;
  final double? minRating;
  final bool? openNow;
  final double? maxDistanceKm;
  final int? maxDeliveryMinutes;
  final bool? freeDelivery;
  final int? maxDeliveryFeeMinor;
  final bool? hasOffers;
  final int? maxMinOrderMinor;
  final String? search;

  Map<String, dynamic> toQuery() {
    return {
      'addressId': addressId,
      'lat': lat,
      'lng': lng,
      'page': page,
      'pageSize': pageSize,
      'sort': sort,
      'categoryIds': categoryIds.isEmpty ? null : categoryIds.join(','),
      'minRating': minRating,
      'openNow': openNow,
      'maxDistanceKm': maxDistanceKm,
      'maxDeliveryMinutes': maxDeliveryMinutes,
      'freeDelivery': freeDelivery,
      'maxDeliveryFeeMinor': maxDeliveryFeeMinor,
      'hasOffers': hasOffers,
      'maxMinOrderMinor': maxMinOrderMinor,
      'search': search,
    };
  }

  /// Only the filter part, used to detect changes.
  RestaurantQuery filtersOnly() => RestaurantQuery(
        addressId: addressId,
        lat: lat,
        lng: lng,
        sort: sort,
        categoryIds: categoryIds,
        minRating: minRating,
        openNow: openNow,
        maxDistanceKm: maxDistanceKm,
        maxDeliveryMinutes: maxDeliveryMinutes,
        freeDelivery: freeDelivery,
        maxDeliveryFeeMinor: maxDeliveryFeeMinor,
        hasOffers: hasOffers,
        maxMinOrderMinor: maxMinOrderMinor,
        search: search,
      );

  RestaurantQuery copyWith({
    String? addressId,
    double? lat,
    double? lng,
    int? page,
    int? pageSize,
    String? sort,
    List<String>? categoryIds,
    double? minRating,
    bool? openNow,
    double? maxDistanceKm,
    int? maxDeliveryMinutes,
    bool? freeDelivery,
    int? maxDeliveryFeeMinor,
    bool? hasOffers,
    int? maxMinOrderMinor,
    String? search,
    bool clearRating = false,
    bool clearOpenNow = false,
    bool clearDistance = false,
    bool clearDeliveryMinutes = false,
    bool clearFreeDelivery = false,
    bool clearMaxFee = false,
    bool clearHasOffers = false,
    bool clearMinOrder = false,
    bool clearAddress = false,
    bool clearSearch = false,
  }) {
    return RestaurantQuery(
      addressId: clearAddress ? null : (addressId ?? this.addressId),
      lat: clearAddress ? null : (lat ?? this.lat),
      lng: clearAddress ? null : (lng ?? this.lng),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      sort: sort ?? this.sort,
      categoryIds: categoryIds ?? this.categoryIds,
      minRating: clearRating ? null : (minRating ?? this.minRating),
      openNow: clearOpenNow ? null : (openNow ?? this.openNow),
      maxDistanceKm: clearDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      maxDeliveryMinutes:
          clearDeliveryMinutes ? null : (maxDeliveryMinutes ?? this.maxDeliveryMinutes),
      freeDelivery: clearFreeDelivery ? null : (freeDelivery ?? this.freeDelivery),
      maxDeliveryFeeMinor: clearMaxFee ? null : (maxDeliveryFeeMinor ?? this.maxDeliveryFeeMinor),
      hasOffers: clearHasOffers ? null : (hasOffers ?? this.hasOffers),
      maxMinOrderMinor: clearMinOrder ? null : (maxMinOrderMinor ?? this.maxMinOrderMinor),
      search: clearSearch ? null : (search ?? this.search),
    );
  }

  bool get hasFilters =>
      categoryIds.isNotEmpty ||
      minRating != null ||
      openNow == true ||
      maxDistanceKm != null ||
      maxDeliveryMinutes != null ||
      freeDelivery == true ||
      maxDeliveryFeeMinor != null ||
      hasOffers == true ||
      maxMinOrderMinor != null;

  static RestaurantQuery fromAddress(CustomerAddressRecord? address) {
    return RestaurantQuery(addressId: address?.id);
  }
}
