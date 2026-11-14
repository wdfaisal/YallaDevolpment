import '../../core/utils/json.dart';
import 'customer.dart';

class CatalogCategory {
  const CatalogCategory({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.slug,
    required this.imageUrl,
    required this.position,
  });

  factory CatalogCategory.fromJson(Map<String, dynamic> json) {
    return CatalogCategory(
      id: asString(json['id']),
      nameAr: asString(json['nameAr']),
      nameEn: asString(json['nameEn']),
      slug: asString(json['slug']),
      imageUrl: asStringOrNull(json['imageUrl']),
      position: asInt(json['position']),
    );
  }

  final String id;
  final String nameAr;
  final String nameEn;
  final String slug;
  final String? imageUrl;
  final int position;

  String name(bool arabic) => arabic ? nameAr : (nameEn.isEmpty ? nameAr : nameEn);
}

class CatalogBanner {
  const CatalogBanner({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    required this.subtitleAr,
    required this.subtitleEn,
    required this.imageUrl,
    required this.targetType,
    required this.targetId,
    required this.externalUrl,
    required this.position,
  });

  factory CatalogBanner.fromJson(Map<String, dynamic> json) {
    return CatalogBanner(
      id: asString(json['id']),
      titleAr: asString(json['titleAr']),
      titleEn: asString(json['titleEn']),
      subtitleAr: asString(json['subtitleAr']),
      subtitleEn: asString(json['subtitleEn']),
      imageUrl: asString(json['imageUrl']),
      targetType: asString(json['targetType'], 'none'),
      targetId: asStringOrNull(json['targetId']),
      externalUrl: asStringOrNull(json['externalUrl']),
      position: asInt(json['position']),
    );
  }

  final String id;
  final String titleAr;
  final String titleEn;
  final String subtitleAr;
  final String subtitleEn;
  final String imageUrl;
  final String targetType;
  final String? targetId;
  final String? externalUrl;
  final int position;

  String title(bool arabic) => arabic ? titleAr : (titleEn.isEmpty ? titleAr : titleEn);
  String subtitle(bool arabic) => arabic ? subtitleAr : (subtitleEn.isEmpty ? subtitleAr : subtitleEn);
}

class HomeSection {
  const HomeSection({
    required this.id,
    required this.key,
    required this.type,
    required this.titleAr,
    required this.titleEn,
    required this.itemLimit,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    return HomeSection(
      id: asString(json['id']),
      key: asString(json['key']),
      type: asString(json['type']),
      titleAr: asString(json['titleAr']),
      titleEn: asString(json['titleEn']),
      itemLimit: asInt(json['itemLimit']),
    );
  }

  final String id;
  final String key;
  final String type;
  final String titleAr;
  final String titleEn;
  final int itemLimit;

  String title(bool arabic) => arabic ? titleAr : (titleEn.isEmpty ? titleAr : titleEn);
}

class CatalogOfferItem {
  const CatalogOfferItem({
    required this.menuItemId,
    required this.name,
    required this.nameAr,
    required this.nameEn,
    required this.imageUrl,
    required this.priceMinor,
    required this.offerPriceMinor,
    required this.discountPercent,
  });

  factory CatalogOfferItem.fromJson(Map<String, dynamic> json) {
    return CatalogOfferItem(
      menuItemId: asString(json['menuItemId']),
      name: asString(json['name']),
      nameAr: asString(json['nameAr']),
      nameEn: asString(json['nameEn']),
      imageUrl: asStringOrNull(json['imageUrl']),
      priceMinor: asInt(json['priceMinor']),
      offerPriceMinor: asInt(json['offerPriceMinor']),
      discountPercent: asIntOrNull(json['discountPercent']),
    );
  }

  final String menuItemId;
  final String name;
  final String nameAr;
  final String nameEn;
  final String? imageUrl;
  final int priceMinor;
  final int offerPriceMinor;
  final int? discountPercent;

  String displayName(bool arabic) => arabic ? nameAr : (nameEn.isEmpty ? name : nameEn);
}

class CatalogOffer {
  const CatalogOffer({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.titleAr,
    required this.titleEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.imageUrl,
    required this.discountType,
    required this.discountValue,
    required this.endsAt,
    required this.items,
  });

  factory CatalogOffer.fromJson(Map<String, dynamic> json) {
    return CatalogOffer(
      id: asString(json['id']),
      restaurantId: asString(json['restaurantId']),
      restaurantName: asString(json['restaurantName']),
      titleAr: asString(json['titleAr']),
      titleEn: asString(json['titleEn']),
      descriptionAr: asString(json['descriptionAr']),
      descriptionEn: asString(json['descriptionEn']),
      imageUrl: asStringOrNull(json['imageUrl']),
      discountType: asString(json['discountType'], 'percentage'),
      discountValue: asInt(json['discountValue']),
      endsAt: asString(json['endsAt']),
      items: mapList(json['items'], CatalogOfferItem.fromJson),
    );
  }

  final String id;
  final String restaurantId;
  final String restaurantName;
  final String titleAr;
  final String titleEn;
  final String descriptionAr;
  final String descriptionEn;
  final String? imageUrl;
  final String discountType;
  final int discountValue;
  final String endsAt;
  final List<CatalogOfferItem> items;

  String title(bool arabic) => arabic ? titleAr : (titleEn.isEmpty ? titleAr : titleEn);
  String description(bool arabic) =>
      arabic ? descriptionAr : (descriptionEn.isEmpty ? descriptionAr : descriptionEn);
}

class CatalogRestaurant {
  const CatalogRestaurant({
    required this.id,
    required this.name,
    required this.cuisine,
    required this.rating,
    required this.ratingCount,
    required this.logoUrl,
    required this.bannerUrl,
    required this.accepting,
    required this.openNow,
    required this.statusLabel,
    required this.prepMinutes,
    required this.distanceKm,
    required this.deliveryFeeMinor,
    required this.minOrderMinor,
    required this.etaMinutes,
    required this.offerCount,
    required this.categories,
  });

  factory CatalogRestaurant.fromJson(Map<String, dynamic> json) {
    return CatalogRestaurant(
      id: asString(json['id']),
      name: asString(json['name']),
      cuisine: asString(json['cuisine']),
      rating: asDouble(json['rating']),
      ratingCount: asInt(json['ratingCount']),
      logoUrl: asStringOrNull(json['logoUrl']),
      bannerUrl: asStringOrNull(json['bannerUrl']),
      accepting: asBool(json['accepting']),
      openNow: asBool(json['openNow']),
      statusLabel: asString(json['statusLabel'], 'open'),
      prepMinutes: asInt(json['prepMinutes']),
      distanceKm: asDoubleOrNull(json['distanceKm']),
      deliveryFeeMinor: asIntOrNull(json['deliveryFeeMinor']),
      minOrderMinor: asIntOrNull(json['minOrderMinor']),
      etaMinutes: asIntOrNull(json['etaMinutes']),
      offerCount: asInt(json['offerCount']),
      categories: (json['categories'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  final String id;
  final String name;
  final String cuisine;
  final double rating;
  final int ratingCount;
  final String? logoUrl;
  final String? bannerUrl;
  final bool accepting;
  final bool openNow;
  final String statusLabel;
  final int prepMinutes;
  final double? distanceKm;
  final int? deliveryFeeMinor;
  final int? minOrderMinor;
  final int? etaMinutes;
  final int offerCount;
  final List<String> categories;

  bool get isOpen => openNow && accepting;
}

class MenuOption {
  const MenuOption({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.descriptionAr,
    required this.descriptionEn,
    required this.priceDeltaMinor,
    required this.isDefault,
    required this.available,
  });

  factory MenuOption.fromJson(Map<String, dynamic> json) {
    return MenuOption(
      id: asString(json['id']),
      nameAr: asString(json['nameAr']),
      nameEn: asString(json['nameEn']),
      descriptionAr: asString(json['descriptionAr']),
      descriptionEn: asString(json['descriptionEn']),
      priceDeltaMinor: asInt(json['priceDeltaMinor']),
      isDefault: asBool(json['isDefault']),
      available: asBool(json['available']),
    );
  }

  final String id;
  final String nameAr;
  final String nameEn;
  final String descriptionAr;
  final String descriptionEn;
  final int priceDeltaMinor;
  final bool isDefault;
  final bool available;

  String name(bool arabic) => arabic ? nameAr : (nameEn.isEmpty ? nameAr : nameEn);
}

class MenuOptionGroup {
  const MenuOptionGroup({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.selectionType,
    required this.minSelect,
    required this.maxSelect,
    required this.required,
    required this.options,
  });

  factory MenuOptionGroup.fromJson(Map<String, dynamic> json) {
    return MenuOptionGroup(
      id: asString(json['id']),
      nameAr: asString(json['nameAr']),
      nameEn: asString(json['nameEn']),
      selectionType: asString(json['selectionType'], 'single'),
      minSelect: asInt(json['minSelect']),
      maxSelect: asInt(json['maxSelect'], 1),
      required: asBool(json['required']),
      options: mapList(json['options'], MenuOption.fromJson),
    );
  }

  final String id;
  final String nameAr;
  final String nameEn;
  final String selectionType;
  final int minSelect;
  final int maxSelect;
  final bool required;
  final List<MenuOption> options;

  String name(bool arabic) => arabic ? nameAr : (nameEn.isEmpty ? nameAr : nameEn);
  bool get isSingle => selectionType == 'single';
  int get effectiveMin => required ? (minSelect < 1 ? 1 : minSelect) : minSelect;
}

class CatalogMenuItem {
  const CatalogMenuItem({
    required this.id,
    required this.restaurantId,
    required this.restaurantName,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.priceMinor,
    required this.offerPriceMinor,
    required this.offerTitleAr,
    required this.offerTitleEn,
    required this.offerDiscountPercent,
    required this.available,
    required this.prepMinutes,
    required this.imageUrls,
    required this.calories,
    required this.badgeAr,
    required this.badgeEn,
    required this.optionGroups,
  });

  factory CatalogMenuItem.fromJson(Map<String, dynamic> json) {
    return CatalogMenuItem(
      id: asString(json['id']),
      restaurantId: asString(json['restaurantId']),
      restaurantName: asString(json['restaurantName']),
      categoryId: asStringOrNull(json['categoryId']),
      categoryName: asStringOrNull(json['categoryName']),
      name: asString(json['name']),
      description: asString(json['description']),
      priceMinor: asInt(json['priceMinor']),
      offerPriceMinor: asIntOrNull(json['offerPriceMinor']),
      offerTitleAr: asStringOrNull(json['offerTitleAr']),
      offerTitleEn: asStringOrNull(json['offerTitleEn']),
      offerDiscountPercent: asIntOrNull(json['offerDiscountPercent']),
      available: asBool(json['available']),
      prepMinutes: asInt(json['prepMinutes']),
      imageUrls: (json['imageUrls'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      calories: asIntOrNull(json['calories']),
      badgeAr: asStringOrNull(json['badgeAr']),
      badgeEn: asStringOrNull(json['badgeEn']),
      optionGroups: mapList(json['optionGroups'], MenuOptionGroup.fromJson),
    );
  }

  final String id;
  final String restaurantId;
  final String restaurantName;
  final String? categoryId;
  final String? categoryName;
  final String name;
  final String description;
  final int priceMinor;
  final int? offerPriceMinor;
  final String? offerTitleAr;
  final String? offerTitleEn;
  final int? offerDiscountPercent;
  final bool available;
  final int prepMinutes;
  final List<String> imageUrls;
  final int? calories;
  final String? badgeAr;
  final String? badgeEn;
  final List<MenuOptionGroup> optionGroups;

  String? get imageUrl => imageUrls.isEmpty ? null : imageUrls.first;
  String? badge(bool arabic) => arabic ? badgeAr : badgeEn;
  bool get hasOptions => optionGroups.isNotEmpty;

  /// Effective unit price after any live offer.
  int get effectivePriceMinor => offerPriceMinor ?? priceMinor;
  bool get hasOffer =>
      offerPriceMinor != null && offerPriceMinor! < priceMinor;
  String? offerTitle(bool arabic) {
    final ar = offerTitleAr ?? '';
    final en = offerTitleEn ?? '';
    final value = arabic ? ar : (en.isEmpty ? ar : en);
    return value.isEmpty ? null : value;
  }
}

class CatalogMenuCategory {
  const CatalogMenuCategory({
    required this.id,
    required this.name,
    required this.position,
    required this.items,
  });

  factory CatalogMenuCategory.fromJson(Map<String, dynamic> json) {
    return CatalogMenuCategory(
      id: asString(json['id']),
      name: asString(json['name']),
      position: asInt(json['position']),
      items: mapList(json['items'], CatalogMenuItem.fromJson),
    );
  }

  final String id;
  final String name;
  final int position;
  final List<CatalogMenuItem> items;
}

class CatalogRestaurantDetail {
  const CatalogRestaurantDetail({
    required this.restaurant,
    required this.address,
    required this.phone,
    required this.opensAt,
    required this.closesAt,
    required this.deliveryFeeMinor,
    required this.minOrderMinor,
    required this.menu,
    required this.offers,
    required this.isFavorite,
  });

  factory CatalogRestaurantDetail.fromJson(Map<String, dynamic> json) {
    return CatalogRestaurantDetail(
      restaurant: CatalogRestaurant.fromJson(asMap(json['restaurant'])),
      address: asString(json['address']),
      phone: asString(json['phone']),
      opensAt: asStringOrNull(json['opensAt']),
      closesAt: asStringOrNull(json['closesAt']),
      deliveryFeeMinor: asIntOrNull(json['deliveryFeeMinor']),
      minOrderMinor: asIntOrNull(json['minOrderMinor']),
      menu: mapList(json['menu'], CatalogMenuCategory.fromJson),
      offers: mapList(json['offers'], CatalogOffer.fromJson),
      isFavorite: asBool(json['isFavorite']),
    );
  }

  final CatalogRestaurant restaurant;
  final String address;
  final String phone;
  final String? opensAt;
  final String? closesAt;
  final int? deliveryFeeMinor;
  final int? minOrderMinor;
  final List<CatalogMenuCategory> menu;
  final List<CatalogOffer> offers;
  final bool isFavorite;
}

class HomeService {
  const HomeService({
    required this.key,
    required this.enabled,
    required this.titleAr,
    required this.titleEn,
  });

  factory HomeService.fromJson(Map<String, dynamic> json) {
    return HomeService(
      key: asString(json['key']),
      enabled: asBool(json['enabled']),
      titleAr: asString(json['titleAr']),
      titleEn: asString(json['titleEn']),
    );
  }

  final String key;
  final bool enabled;
  final String titleAr;
  final String titleEn;

  String title(bool arabic) => arabic ? titleAr : (titleEn.isEmpty ? titleAr : titleEn);
}

class CatalogHome {
  const CatalogHome({
    required this.sections,
    required this.services,
    required this.banners,
    required this.offers,
    required this.nearby,
    required this.bestSellers,
    required this.restaurants,
    required this.categories,
    required this.address,
    required this.eligibility,
  });

  factory CatalogHome.fromJson(Map<String, dynamic> json) {
    return CatalogHome(
      sections: mapList(json['sections'], HomeSection.fromJson),
      services: mapList(json['services'], HomeService.fromJson),
      banners: mapList(json['banners'], CatalogBanner.fromJson),
      offers: mapList(json['offers'], CatalogOffer.fromJson),
      nearby: mapList(json['nearby'], CatalogRestaurant.fromJson),
      bestSellers: mapList(json['bestSellers'], CatalogMenuItem.fromJson),
      restaurants: mapList(json['restaurants'], CatalogRestaurant.fromJson),
      categories: mapList(json['categories'], CatalogCategory.fromJson),
      address: json['address'] == null
          ? null
          : CustomerAddressRecord.fromJson(asMap(json['address'])),
      eligibility: json['eligibility'] == null
          ? null
          : AddressEligibility.fromJson(asMap(json['eligibility'])),
    );
  }

  final List<HomeSection> sections;
  final List<HomeService> services;
  final List<CatalogBanner> banners;
  final List<CatalogOffer> offers;
  final List<CatalogRestaurant> nearby;
  final List<CatalogMenuItem> bestSellers;
  final List<CatalogRestaurant> restaurants;
  final List<CatalogCategory> categories;
  final CustomerAddressRecord? address;
  final AddressEligibility? eligibility;

  bool get isEmpty => banners.isEmpty && offers.isEmpty && nearby.isEmpty && restaurants.isEmpty;
}

class CatalogRestaurantList {
  const CatalogRestaurantList({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
    required this.sort,
    required this.availableSorts,
    required this.address,
    required this.eligibility,
  });

  factory CatalogRestaurantList.fromJson(Map<String, dynamic> json) {
    return CatalogRestaurantList(
      items: mapList(json['items'], CatalogRestaurant.fromJson),
      page: asInt(json['page'], 1),
      pageSize: asInt(json['pageSize'], 20),
      total: asInt(json['total']),
      hasMore: asBool(json['hasMore']),
      sort: asString(json['sort'], 'recommended'),
      availableSorts:
          (json['availableSorts'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      address: json['address'] == null
          ? null
          : CustomerAddressRecord.fromJson(asMap(json['address'])),
      eligibility: json['eligibility'] == null
          ? null
          : AddressEligibility.fromJson(asMap(json['eligibility'])),
    );
  }

  final List<CatalogRestaurant> items;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
  final String sort;
  final List<String> availableSorts;
  final CustomerAddressRecord? address;
  final AddressEligibility? eligibility;
}
