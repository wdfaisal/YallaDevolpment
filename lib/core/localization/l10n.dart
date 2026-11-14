import 'package:flutter/widgets.dart';

/// Lightweight bilingual strings. Arabic is the default; English is a full
/// translation. No string is invented at runtime and no third-party
/// localization package is required.
class L10n {
  const L10n(this.isArabic);

  final bool isArabic;

  static L10n of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return L10n(locale.languageCode == 'ar');
  }

  String _t(String ar, String en) => isArabic ? ar : en;

  // Brand & shell
  String get appName => _t('يلا طلبات', 'Yalla Talabat');
  String get explore => _t('استكشف', 'Explore');
  String get favorites => _t('المفضلة', 'Favorites');
  String get myOrders => _t('طلباتي', 'My Orders');
  String get account => _t('حسابي', 'Account');
  String get search => _t('بحث', 'Search');
  String get cart => _t('السلة', 'Cart');
  String get wallet => _t('المحفظة', 'Wallet');
  String get notifications => _t('الإشعارات', 'Notifications');
  String get retry => _t('إعادة المحاولة', 'Retry');
  String get cancel => _t('إلغاء', 'Cancel');
  String get confirm => _t('تأكيد', 'Confirm');
  String get save => _t('حفظ', 'Save');
  String get close => _t('إغلاق', 'Close');
  String get back => _t('رجوع', 'Back');
  String get seeAll => _t('عرض الكل', 'See all');
  String get loading => _t('جارٍ التحميل…', 'Loading…');
  String get somethingWentWrong => _t('تعذّر إكمال العملية', 'Something went wrong');
  String get connectionError =>
      _t('تعذّر الاتصال بالخادم. تحقق من الشبكة.', 'Cannot reach the server. Check your connection.');
  String get emptyState => _t('لا توجد بيانات لعرضها', 'Nothing to show yet');
  String get offline => _t('غير متصل', 'Offline');

  // Home
  String get deliverTo => _t('التوصيل إلى', 'Deliver to');
  String get chooseAddress => _t('اختر عنواناً', 'Choose an address');
  String get services => _t('الخدمات', 'Services');
  String get food => _t('المطاعم', 'Restaurants');
  String get parcel => _t('طلبات مارت', 'Parcel');
  String get exclusiveOffers => _t('عروض حصرية اليوم', 'Exclusive offers today');
  String get exclusiveOffer => _t('عرض حصري', 'Exclusive offer');
  String get orderNow => _t('اطلب الآن', 'Order now');
  String get restaurantsNearYou => _t('مطاعم بالقرب منك', 'Restaurants near you');
  String get bestSellersThisWeek =>
      _t('الأكثر طلباً هذا الأسبوع', 'Most ordered this week');
  String get nearby => _t('الأقرب إليك', 'Near you');
  String get bestSellers => _t('الأكثر طلباً', 'Best sellers');
  String get topBrands => _t('أشهر العلامات', 'Top brands');
  String get allRestaurants => _t('جميع المطاعم', 'All restaurants');
  String get more => _t('المزيد', 'More');
  String get grocery => _t('البقالة', 'Grocery');
  String get dineOut => _t('DineOut', 'DineOut');
  String get pharmacy => _t('صيدلية', 'Pharmacy');
  String get fastBadge => _t('سريع', 'Fast');
  String get newBadge => _t('جديد', 'New');
  String get serviceUnavailable =>
      _t('هذه الخدمة غير متاحة حالياً', 'This service is not available yet');
  String get featuredDiscounts =>
      _t('أبرز عروض الخصم', 'Top discounted items');
  String discountedItems(int count) =>
      _t('$count أصناف مخفضة', '$count discounted items');
  String get codeLabel => _t('كود', 'Code');
  String get popularItem => _t('طلب شائع', 'Popular');
  String get minutesLong => _t('دقيقة', 'min');
  String seeAllCount(int count) => _t('عرض الكل ($count)', 'See all ($count)');
  String endsInHours(int hours) {
    if (!isArabic) return 'Ends in ${hours}h';
    if (hours == 2) return 'ينتهي خلال ساعتين';
    final unit = hours == 1 ? 'ساعة' : (hours <= 10 ? 'ساعات' : 'ساعة');
    return 'ينتهي خلال $hours $unit';
  }

  String get endsIn => _t('ينتهي خلال', 'Ends in');
  String get discountPrefix => _t('خصم', 'Off');
  String discountBadge(String value) => _t('خصم $value', '$value off');
  String get viewList => _t('عرض القائمة', 'List view');
  String get viewGrid => _t('عرض الشبكة', 'Grid view');
  String get hoursShort => _t('س', 'h');
  String get daysShort => _t('ي', 'd');
  String get categories => _t('التصنيفات', 'Categories');
  String get noOffers => _t('لا توجد عروض متاحة الآن', 'No offers available right now');
  String get noRestaurantsNearby =>
      _t('لا توجد مطاعم قريبة من عنوانك الحالي', 'No restaurants near your current address');
  String get addAddressToSeeNearby =>
      _t('أضف عنواناً لعرض المطاعم القريبة', 'Add an address to see nearby restaurants');

  // Restaurant list & filters
  String get sortBy => _t('ترتيب حسب', 'Sort by');
  String get filters => _t('تصفية', 'Filters');
  String get resetFilters => _t('تصفير الفلاتر', 'Reset filters');
  String get applyFilters => _t('تطبيق', 'Apply');
  String get openNow => _t('مفتوح الآن', 'Open now');
  String get freeDelivery => _t('توصيل مجاني', 'Free delivery');
  String get hasOffers => _t('لديه عروض', 'Has offers');
  String get rating => _t('التقييم', 'Rating');
  String get distance => _t('المسافة', 'Distance');
  String get deliveryTime => _t('مدة التوصيل', 'Delivery time');
  String get deliveryFee => _t('رسوم التوصيل', 'Delivery fee');
  String get minimumOrder => _t('الحد الأدنى', 'Minimum order');
  String get any => _t('الكل', 'Any');
  String get sortRecommended => _t('الأنسب', 'Recommended');
  String get sortRating => _t('الأعلى تقييماً', 'Top rated');
  String get sortDistance => _t('الأقرب', 'Nearest');
  String get sortPopular => _t('الأكثر طلباً', 'Most popular');
  String get sortFastest => _t('الأسرع', 'Fastest');
  String get sortLowestFee => _t('الأقل رسوماً', 'Lowest fee');
  String get sortNewest => _t('الأحدث', 'Newest');
  String get noResults => _t('لا توجد نتائج مطابقة', 'No matching results');
  String get clearSearch => _t('مسح البحث', 'Clear search');

  // Restaurant status
  String get open => _t('مفتوح', 'Open');
  String get closed => _t('مغلق', 'Closed');
  String get temporarilyClosed => _t('مغلق مؤقتاً', 'Temporarily closed');
  String get unavailable => _t('غير متاح', 'Unavailable');
  String get minuteShort => _t('د', 'min');
  String get km => _t('كم', 'km');
  String get currencyDefault => _t('ر.س', 'SAR');

  // Restaurant details
  String get menu => _t('القائمة', 'Menu');
  String get offers => _t('العروض', 'Offers');
  String get info => _t('معلومات', 'Info');
  String get reviews => _t('التقييمات', 'Reviews');
  String get openingHours => _t('ساعات العمل', 'Opening hours');
  String get deliveryInfo => _t('التوصيل', 'Delivery');
  String get addToCart => _t('أضف إلى السلة', 'Add to cart');
  String get viewCart => _t('عرض السلة', 'View cart');
  String get itemUnavailable => _t('غير متاح حالياً', 'Currently unavailable');
  String get outOfStock => _t('نفد', 'Sold out');
  String get favoriteAdded => _t('أُضيف إلى المفضلة', 'Added to favorites');
  String get favoriteRemoved => _t('أُزيل من المفضلة', 'Removed from favorites');
  String get restaurantClosedNotice =>
      _t('المطعم مغلق حالياً ولا يمكن استقبال الطلبات.', 'The restaurant is closed and not accepting orders.');

  // Restaurant details (Stitch redesign)
  String get menuSections => _t('قائمة الأقسام', 'Menu sections');
  String get searchMenuHint => _t('ابحث في القائمة…', 'Search the menu…');
  String get fastDelivery => _t('توصيل سريع جداً', 'Very fast delivery');
  String get exclusiveYallaOffers =>
      _t('خصومات حصرية يلا', 'Exclusive Yalla offers');
  String menuItemsCount(int count) {
    if (!isArabic) return count == 1 ? '1 tasty item' : '$count tasty items';
    if (count == 1) return 'صنف واحد شهي';
    if (count == 2) return 'صنفان شهيان';
    return '$count أصناف شهية';
  }

  String itemCountShort(int count) {
    if (!isArabic) return count == 1 ? '1 item' : '$count items';
    if (count == 1) return 'صنف واحد';
    if (count == 2) return 'صنفان';
    return '$count أصناف';
  }

  String ratingCountLabel(int count) =>
      _t('+$count تقييم', '+$count reviews');
  String caloriesLabel(int kcal) => _t('$kcal سعرة', '$kcal kcal');
  String get includesVat => _t('(شامل الضريبة)', '(incl. VAT)');

  String cartItemsCount(int count) {
    if (count <= 0) return _t('السلة فارغة', 'Cart is empty');
    if (!isArabic) {
      return count == 1 ? '1 item in cart' : '$count items in cart';
    }
    if (count == 1) return 'صنف واحد في السلة';
    if (count == 2) return 'صنفان في السلة';
    return '$count أصناف في السلة';
  }

  // Meal drawer
  String get required => _t('إلزامي', 'Required');
  String get optional => _t('اختياري', 'Optional');
  String get chooseOne => _t('اختر واحداً', 'Choose one');
  String get chooseUpTo => _t('اختر حتى', 'Choose up to');
  String get specialInstructions => _t('ملاحظات خاصة', 'Special instructions');
  String get notesHint => _t('مثال: بدون بصل، صوص إضافي…', 'e.g. no onions, extra sauce…');
  String get quantity => _t('الكمية', 'Quantity');
  String get decreaseQuantity => _t('تقليل', 'Decrease quantity');
  String get increaseQuantity => _t('زيادة', 'Increase quantity');
  String get addFor => _t('إضافة', 'Add');
  String get selectRequiredOptions =>
      _t('أكمل الخيارات الإلزامية أولاً', 'Complete the required options first');
  String get addedToCart => _t('أُضيف إلى السلة', 'Added to cart');

  // Cart & checkout
  String get yourCart => _t('سلتك', 'Your cart');
  String get emptyCart => _t('سلتك فارغة', 'Your cart is empty');
  String get emptyCartHint =>
      _t('أضف أصنافاً من مطعمك المفضل لتبدأ الطلب.', 'Add items from your favourite restaurant to start.');
  String get browseRestaurants => _t('تصفح المطاعم', 'Browse restaurants');
  String get oneRestaurantOnly =>
      _t('يمكن الطلب من مطعم واحد فقط. أفرغ السلة أولاً.', 'Only one restaurant per order. Clear the cart first.');
  String get clearCart => _t('إفراغ السلة', 'Clear cart');
  String get clearCartConfirm =>
      _t('سيُحذف كل ما في السلة. هل تريد المتابعة؟', 'All cart items will be removed. Continue?');
  String get subtotal => _t('المجموع الفرعي', 'Subtotal');
  String get vat => _t('الضريبة', 'VAT');
  String get discount => _t('الخصم', 'Discount');
  String get total => _t('الإجمالي', 'Total');
  String get couponCode => _t('كود الخصم', 'Coupon code');
  String get applyCoupon => _t('تطبيق', 'Apply');
  String get couponApplied => _t('تم تطبيق الكوبون', 'Coupon applied');
  String get couponInvalid => _t('كود الخصم غير صالح', 'Invalid coupon code');
  String get removeCoupon => _t('إزالة', 'Remove');
  String get minimumNotMet => _t('لم تصل للحد الأدنى للطلب', 'Minimum order not met');
  String get minimumRemaining => _t('أضف', 'Add');
  String get checkout => _t('إتمام الطلب', 'Checkout');
  String get delivery => _t('توصيل', 'Delivery');
  String get pickup => _t('استلام', 'Pickup');
  String get deliveryAddress => _t('عنوان التوصيل', 'Delivery address');
  String get addAddress => _t('إضافة عنوان', 'Add address');
  String get paymentMethod => _t('طريقة الدفع', 'Payment method');
  String get cashOnDelivery => _t('الدفع عند الاستلام', 'Cash on delivery');
  String get payWithWallet => _t('المحفظة', 'Wallet');
  String get cardGateway => _t('بطاقة', 'Card');
  String get bankTransfer => _t('تحويل بنكي', 'Bank transfer');
  String get mixedPayment => _t('دفع مختلط', 'Mixed payment');
  String get orderNote => _t('ملاحظة على الطلب', 'Order note');
  String get scheduleOrder => _t('جدولة الطلب', 'Schedule order');
  String get now => _t('الآن', 'Now');
  String get placeOrder => _t('تأكيد الطلب', 'Place order');
  String get placingOrder => _t('جارٍ إنشاء الطلب…', 'Placing order…');
  String get orderPlaced => _t('تم إنشاء طلبك', 'Order placed');
  String get orderFailed => _t('تعذّر إنشاء الطلب', 'Could not place the order');
  String get trackOrder => _t('تتبع الطلب', 'Track order');
  String get continueShopping => _t('متابعة التسوق', 'Continue shopping');
  String get walletBalance => _t('رصيد المحفظة', 'Wallet balance');
  String get insufficientWallet =>
      _t('رصيد المحفظة غير كافٍ لهذا الجزء', 'Wallet balance is not enough for this part');
  String get paymentUnavailable => _t('غير متاح', 'Unavailable');
  String get deliveryFeeFree => _t('مجاني', 'Free');
  String get orderSummary => _t('ملخص الطلب', 'Order summary');
  String get items => _t('الأصناف', 'Items');

  // Cart & checkout (Stitch redesign)
  String get checkoutTitle =>
      _t('إتمام الدفع / سلة الطلبات', 'Checkout / Your cart');
  String get orderFrom => _t('طلبك من', 'Ordering from');
  String get openForOrders => _t('مفتوح للطلبات', 'Open for orders');
  String get editOrder => _t('تعديل الطلب', 'Edit order');
  String requestedItems(int count) =>
      _t('الأصناف المطلوبة ($count)', 'Items ($count)');
  String get addMoreFromRestaurant =>
      _t('أضف أصناف أخرى من هذا المطعم', 'Add more items from this restaurant');
  String get deleteItem => _t('حذف الصنف', 'Remove item');
  String get orderNotesHint => _t(
        'ملاحظات إضافية للمطعم أو السائق (مثال: يرجى رن الجرس بهدوء أو ترك الطلب عند الباب)…',
        'Extra notes for the restaurant or driver (e.g. ring the bell quietly)…',
      );
  String get notesDeliveryHint => _t(
        'سنحرص على إيصال التنبيهات بدقة للكابتن والمطعم',
        'We make sure your notes reach the driver and restaurant',
      );
  String get couponAppliedBadge => _t('مطبق', 'Applied');
  String couponSaved(String amount) =>
      _t('تم توفير $amount بنجاح على طلبك!', 'You saved $amount on this order!');
  String get changeAddress => _t('تغيير العنوان', 'Change address');
  String get addDriverInstructions =>
      _t('إضافة تعليمات الوصول للسائق', 'Add driver instructions');
  String get secureOnlinePayment =>
      _t('دفع إلكتروني آمن', 'Secure online payment');
  String get priceDetails => _t('تفاصيل الحساب', 'Price details');
  String get finalTotal => _t('الإجمالي النهائي', 'Final total');
  String get finalTotalHint =>
      _t('شامل الضريبة وكافة الرسوم', 'Includes VAT and all fees');
  String get orderGuarantee => _t(
        'ضمان يلا طلبات: استرجاع فوري في حال لم يطابق الطلب المواصفات',
        'Yalla Talabat guarantee: instant refund if the order does not match',
      );
  String get confirmAndPay => _t('تأكيد ودفع الطلب', 'Confirm & pay');
  String freeDeliverySaved(String amount) => _t(
        'وفرت $amount على رسوم التوصيل!',
        'You saved $amount on delivery!',
      );
  String get freeDeliveryApplied =>
      _t('تم تطبيق التوصيل المجاني', 'Free delivery applied');
  String completedPercent(int percent) =>
      _t('مكتمل $percent%', '$percent% complete');
  String get paymentWalletHint =>
      _t('خصم مباشر من رصيد محفظتك', 'Pay directly from your wallet balance');
  String get paymentCashHint =>
      _t('يرجى تحضير المبلغ المساوي قدر الإمكان', 'Please prepare the exact amount');
  String get paymentCardHint => _t('بطاقة مدى أو ائتمانية', 'Mada or credit card');
  String get paymentTransferHint =>
      _t('حوّل المبلغ ثم أرفق رقم العملية', 'Transfer the amount then add the reference');

  // Search
  String get searchHint => _t('ابحث عن مطعم أو طبق…', 'Search restaurants or dishes…');
  String get recentSearches => _t('عمليات البحث الأخيرة', 'Recent searches');
  String get clearHistory => _t('مسح السجل', 'Clear history');
  String get suggestions => _t('اقتراحات', 'Suggestions');
  String get searchResults => _t('نتائج البحث', 'Search results');
  String get dishes => _t('الأطباق', 'Dishes');
  String get startTyping => _t('اكتب للبحث', 'Start typing to search');
  String get minCharsHint => _t('أدخل حرفين على الأقل', 'Enter at least two characters');

  // Account
  String get guest => _t('زائر', 'Guest');
  String get signIn => _t('تسجيل الدخول', 'Sign in');
  String get signOut => _t('تسجيل الخروج', 'Sign out');
  String get signOutConfirm => _t('هل تريد تسجيل الخروج؟', 'Sign out of your account?');
  String get editProfile => _t('تعديل الملف الشخصي', 'Edit profile');
  String get fullName => _t('الاسم الكامل', 'Full name');
  String get phone => _t('رقم الهاتف', 'Phone number');
  String get email => _t('البريد الإلكتروني', 'Email');
  String get language => _t('اللغة', 'Language');
  String get arabic => _t('العربية', 'Arabic');
  String get english => _t('English', 'English');
  String get addresses => _t('العناوين', 'Addresses');
  String get loyalty => _t('نقاط الولاء', 'Loyalty points');
  String get points => _t('نقطة', 'points');
  String get support => _t('الدعم والشكاوى', 'Support & complaints');
  String get about => _t('عن التطبيق', 'About');
  String get memberSince => _t('عضو منذ', 'Member since');
  String get orderCount => _t('طلب', 'orders');
  String get noAddresses => _t('لا توجد عناوين محفوظة', 'No saved addresses');
  String get defaultAddress => _t('افتراضي', 'Default');
  String get deleteAddress => _t('حذف العنوان', 'Delete address');
  String get addressLabel => _t('اسم العنوان', 'Address label');
  String get addressDetails => _t('تفاصيل العنوان', 'Address details');
  String get addressInstructions => _t('تعليمات الوصول', 'Access instructions');
  String get setDefault => _t('تعيين كافتراضي', 'Set as default');
  String get useMyLocation => _t('استخدام موقعي', 'Use my location');
  String get latitude => _t('خط العرض', 'Latitude');
  String get longitude => _t('خط الطول', 'Longitude');
  String get saveAddress => _t('حفظ العنوان', 'Save address');
  String get covered => _t('داخل نطاق التغطية', 'Inside coverage');
  String get outsideCoverage => _t('خارج نطاق التغطية', 'Outside coverage');
  String get noPosition => _t('لا يوجد موقع محدد', 'No position set');
  String get noZone => _t('لا توجد منطقة تغطية', 'No coverage zone');

  // Account sections
  String get settings => _t('الإعدادات', 'Settings');
  String get ordersAndPayments => _t('الطلبات والمدفوعات', 'Orders & payments');
  String get addressesSubtitle =>
      _t('إدارة عناوين التوصيل', 'Manage your delivery addresses');
  String get ordersSubtitle =>
      _t('تابع طلباتك السابقة والنشطة', 'Track active and past orders');
  String get loyaltySubtitle => _t('اجمع النقاط مع كل طلب', 'Earn points with every order');
  String get walletSubtitle => _t('رصيدك وحركات المحفظة', 'Your balance and transactions');
  String get preferences => _t('التفضيلات', 'Preferences');
  String get notificationsSubtitle => _t('تنبيهات الطلبات والعروض', 'Order and offer alerts');
  String get settingsSubtitle => _t('الخصوصية والإشعارات', 'Privacy and notifications');
  String get supportAndInfo => _t('الدعم والمعلومات', 'Support & info');
  String get supportSubtitle => _t('تواصل معنا أو قدّم شكوى', 'Contact us or file a complaint');
  String get shareAppSubtitle => _t('شارك التطبيق مع أصدقائك', 'Share the app with friends');
  String get shareAppMessage =>
      _t('اطلب من مطاعمك المفضلة عبر يلا طلبات.', 'Order from your favourite restaurants on Yalla Talabat.');

  // Profile screen (Stitch profile redesign)
  String get profileTitle => _t('حسابي والملف الشخصي', 'My account & profile');
  String get walletCardTitle => _t('محفظة يلا', 'Yalla wallet');
  String get topUpBalance => _t('شحن رصيد', 'Top up');
  String get rewardPoints => _t('نقاط المكافآت', 'Reward points');
  String get redeem => _t('استبدال', 'Redeem');
  String get coupons => _t('الكوبونات', 'Coupons');
  String get offersUnit => _t('عروض', 'offers');
  String get browse => _t('استعراض', 'View');
  String get manageOrdersAndPayments =>
      _t('إدارة الطلبات والمدفوعات', 'Manage orders & payments');
  String get savedAddresses => _t('العناوين المحفوظة', 'Saved addresses');
  String get paymentMethods => _t('طرق الدفع والبطاقات', 'Payment methods & cards');
  String get paymentMethodsSubtitle => _t('الدفع عند الاستلام متاح', 'Cash on delivery available');
  String get paymentMethodsInfo => _t(
        'الدفع عند الاستلام متاح حالياً. الدفع الإلكتروني غير متاح بعد.',
        'Cash on delivery is available now. Online card payments are not available yet.',
      );
  String get orderHistory => _t('سجل الطلبات والفواتير', 'Order history & invoices');
  String get orderHistorySubtitle => _t(
        'تحميل الفواتير الضريبية وتكرار الطلبات',
        'Download tax invoices and reorder',
      );
  String get loyaltyProgram => _t('برنامج الولاء والمكافآت', 'Loyalty & rewards');
  String get loyaltyProgramSubtitle =>
      _t('عروض حصرية ومستويات الخصم', 'Exclusive offers and discount tiers');
  String get preferencesAndSettings =>
      _t('التفضيلات والإعدادات', 'Preferences & settings');
  String get notificationSettings => _t('الإشعارات والتنبيهات', 'Notifications & alerts');
  String get notificationSettingsSubtitle => _t(
        'تحديثات فورية لحالة الطلب والعروض',
        'Instant order status and offer updates',
      );
  String get languageAndAppearance =>
      _t('تفضيلات اللغة والمظهر', 'Language & appearance');
  String get languageAndAppearanceSubtitle =>
      _t('العربية • مظهر النهار الفاتح', 'English • Light theme');
  String get helpAndSupport => _t('المساعدة وخدمة العملاء', 'Help & customer service');
  String get availableNow => _t('متاح الآن', 'Available now');
  String get termsAndPrivacy => _t('الشروط وسياسة الخصوصية', 'Terms & privacy policy');
  String get termsAndPrivacySubtitle => _t(
        'حقوق المستخدم والاتفاقيات الرسمية',
        'User rights and official agreements',
      );
  String get notificationsEnabledToast => _t('تم تفعيل التنبيهات', 'Notifications enabled');
  String get notificationsDisabledToast => _t('تم إيقاف التنبيهات', 'Notifications disabled');
  String get changePhoto => _t('تغيير الصورة الشخصية', 'Change profile photo');
  String get lightTheme => _t('مظهر النهار الفاتح', 'Light theme');
  String savedAddressesSubtitle(int count) => _t(
        '$count عناوين مسجلة للتوصيل السريع',
        '$count saved delivery addresses',
      );
  String get termsNotice => _t(
        'لم تُنشر الشروط وسياسة الخصوصية داخل التطبيق بعد. للاستفسار تواصل مع خدمة العملاء.',
        'Terms and the privacy policy are not published in the app yet. Contact customer service for details.',
      );

  // Auth
  String get loginTitle => _t('تسجيل الدخول', 'Sign in');
  String get loginSubtitle =>
      _t('أدخل رقم هاتفك لاستلام رمز التحقق', 'Enter your phone number to receive a verification code');
  String get phoneHint => _t('9xxxxxxxx', '9xxxxxxxx');
  String get sendCode => _t('إرسال الرمز', 'Send code');
  String get otpTitle => _t('رمز التحقق', 'Verification code');
  String get otpSubtitle => _t('أدخل الرمز المرسل إلى', 'Enter the code sent to');
  String get verify => _t('تحقق', 'Verify');
  String get resend => _t('إعادة الإرسال', 'Resend');
  String get resendIn => _t('إعادة الإرسال بعد', 'Resend in');
  String get changePhone => _t('تغيير الرقم', 'Change number');
  String get devCode => _t('رمز التطوير', 'Development code');
  String get nameHint => _t('الاسم (اختياري للتسجيل)', 'Name (optional for sign up)');
  String get invalidPhone => _t('رقم الهاتف غير صالح', 'Invalid phone number');
  String get invalidCode => _t('رمز التحقق غير صالح', 'Invalid verification code');
  String get sessionExpired => _t('انتهت الجلسة. سجّل الدخول مجدداً.', 'Session expired. Please sign in again.');

  // Orders
  String get activeOrders => _t('الطلبات النشطة', 'Active orders');
  String get pastOrders => _t('الطلبات السابقة', 'Past orders');
  String get noOrders => _t('لا توجد طلبات بعد', 'No orders yet');
  String get noActiveOrders => _t('لا توجد طلبات نشطة', 'No active orders');
  String get orderDetails => _t('تفاصيل الطلب', 'Order details');
  String get cancelOrder => _t('إلغاء الطلب', 'Cancel order');
  String get cancelReason => _t('سبب الإلغاء (اختياري)', 'Cancellation reason (optional)');
  String get reorder => _t('إعادة الطلب', 'Reorder');
  String get rateOrder => _t('قيّم الطلب', 'Rate order');
  String get track => _t('تتبع', 'Track');
  String get delivered => _t('تم التوصيل', 'Delivered');
  String get cancelled => _t('ملغي', 'Cancelled');
  String get orderTimeline => _t('مسار الطلب', 'Order timeline');
  String get driver => _t('السائق', 'Driver');
  String get callDriver => _t('اتصال', 'Call');
  String get eta => _t('الوصول المتوقع', 'ETA');

  // Ratings
  String get rateRestaurant => _t('قيّم المطعم', 'Rate the restaurant');
  String get rateDriver => _t('قيّم السائق', 'Rate the driver');
  String get yourComment => _t('تعليقك (اختياري)', 'Your comment (optional)');
  String get submitRating => _t('إرسال التقييم', 'Submit rating');
  String get ratingSubmitted => _t('تم إرسال تقييمك', 'Rating submitted');
  String get ratingWindowClosed => _t('انتهت فترة التقييم', 'Rating window has closed');

  // Notifications
  String get markAllRead => _t('تعليم الكل كمقروء', 'Mark all as read');
  String get noNotifications => _t('لا توجد إشعارات', 'No notifications');
  String get markAllReadAction =>
      _t('تحديد الكل كمقروء', 'Mark all as read');
  String get notificationsAllFilter => _t('الكل', 'All');
  String get notificationsOrdersFilter =>
      _t('حالة الطلبات', 'Order status');
  String get notificationsOffersFilter =>
      _t('العروض والخصومات', 'Offers & discounts');
  String get notificationsAccountFilter =>
      _t('المحفظة والحساب', 'Wallet & account');
  String get notificationsGroupToday => _t('اليوم', 'Today');
  String get notificationsGroupYesterday => _t('أمس', 'Yesterday');
  String get notificationsGroupThisWeek => _t('هذا الأسبوع', 'This week');
  String get notificationsGroupOlder => _t('أقدم', 'Older');
  String get allNotificationsRead =>
      _t('تمت قراءة جميع الإشعارات بنجاح', 'All notifications read');
  String get notificationMarkRead => _t('تحديد كمقروء', 'Mark as read');
  String get viewOrder => _t('عرض الطلب', 'View order');
  String get trackOrderFull => _t('تتبع مسار الطلب', 'Track order');
  String get notificationsSettingsTitle =>
      _t('تخصيص الإشعارات الذكية', 'Smart notification preferences');
  String get notificationsSettingsBody => _t(
        'يمكنك تفعيل أو إيقاف تنبيهات الطلبات داخل التطبيق في أي وقت.',
        'Turn in-app order alerts on or off at any time.',
      );
  String get manageNotificationSettings =>
      _t('إدارة إعدادات التنبيهات', 'Manage notification settings');
  String get versionShort => _t('الإصدار', 'Version');
  String get notificationsEmptyTitle =>
      _t('لا توجد إشعارات في هذا القسم', 'No notifications in this section');
  String get notificationsEmptyMessage => _t(
        'أنت على اطلاع دائم بكل شيء! سنرسل لك تنبيهاً فور حدوث أي تحديث جديد لطلباتك أو عروضنا.',
        'You are all caught up. We will alert you as soon as something new happens with your orders or offers.',
      );
  String get backToAllNotifications =>
      _t('العودة لجميع الإشعارات', 'Back to all notifications');
  String get notificationsDisabledTitle =>
      _t('التنبيهات متوقفة', 'Notifications are off');
  String get notificationsDisabledMessage => _t(
        'فعّل التنبيهات لتصلك تحديثات طلباتك داخل التطبيق.',
        'Turn notifications on to receive your order updates in the app.',
      );
  String get enableNotifications =>
      _t('تفعيل التنبيهات', 'Enable notifications');
  String get unreadNotificationsPrefix => _t('لديك', 'You have');
  String get unreadNotificationsSuffix =>
      _t('إشعارات غير مقروءة', 'unread notifications');
  String unreadNotificationsNotice(int count) => _t(
        'لديك $count إشعارات غير مقروءة',
        'You have $count unread notifications',
      );
  String newNotificationsCount(int count) =>
      _t('$count جديد', '$count new');
  String notificationCount(int count) {
    if (isArabic) {
      if (count == 1) return 'إشعار واحد';
      if (count == 2) return 'إشعاران';
      if (count <= 10) return '$count إشعارات';
      return '$count إشعاراً';
    }
    return count == 1 ? '1 notification' : '$count notifications';
  }

  // Wallet / loyalty
  String get availableBalance => _t('الرصيد المتاح', 'Available balance');
  String get heldBalance => _t('المحتجز', 'Held');
  String get noWalletEntries => _t('لا توجد حركات على المحفظة', 'No wallet transactions');
  String get noLoyaltyEntries => _t('لا توجد حركات نقاط', 'No points activity');
  String get topUpUnavailable =>
      _t('شحن المحفظة غير متاح حالياً', 'Wallet top-up is not available yet');

  // Support
  String get newTicket => _t('تذكرة جديدة', 'New ticket');
  String get ticketSubject => _t('عنوان المشكلة', 'Subject');
  String get ticketDescription => _t('وصف المشكلة', 'Describe the issue');
  String get ticketCategory => _t('التصنيف', 'Category');
  String get priority => _t('الأولوية', 'Priority');
  String get send => _t('إرسال', 'Send');
  String get ticketCreated => _t('أُنشئت التذكرة', 'Ticket created');
  String get noTickets => _t('لا توجد تذاكر دعم', 'No support tickets');
  String get reply => _t('رد', 'Reply');
  String get writeReply => _t('اكتب ردك…', 'Write your reply…');

  // Favorites
  String get noFavorites => _t('لا توجد مفضلات بعد', 'No favorites yet');
  String get noFavoriteRestaurants =>
      _t('أضف مطاعم إلى المفضلة لتجدها هنا.', 'Save restaurants to find them here.');
  String get noFavoriteItems => _t('أضف أطباقاً إلى المفضلة لتجدها هنا.', 'Save dishes to find them here.');

  // Sharing
  String get share => _t('مشاركة', 'Share');
  String get shareRestaurant => _t('مشاركة المطعم', 'Share restaurant');
  String get shareItem => _t('مشاركة الطبق', 'Share dish');
  String get shareOffer => _t('مشاركة العرض', 'Share offer');
  String get shareOrder => _t('مشاركة الطلب', 'Share order');

  // Shared actions & labels
  String get edit => _t('تعديل', 'Edit');
  String get change => _t('تغيير', 'Change');
  String get delete => _t('حذف', 'Delete');
  String get add => _t('إضافة', 'Add');
  String get useAddress => _t('استخدام هذا العنوان', 'Use this address');
  String get viewRestaurant => _t('عرض المطعم', 'View restaurant');
  String get today => _t('اليوم', 'Today');
  String get secondsShort => _t('ث', 's');

  // Auth extras
  String get sendingCode => _t('جارٍ إرسال الرمز…', 'Sending code…');
  String get verifying => _t('جارٍ التحقق…', 'Verifying…');
  String get codeSent => _t('أُرسل رمز التحقق', 'Verification code sent');
  String get otpResent => _t('أُعيد إرسال الرمز', 'Code resent');
  String get enterCodeHint =>
      _t('أدخل الرمز المكوّن من 6 أرقام', 'Enter the 6-digit code');
  String get otpExpiresIn => _t('ينتهي الرمز خلال', 'Code expires in');
  String get codeExpired => _t('انتهت صلاحية الرمز. أعد الإرسال.', 'The code expired. Send a new one.');
  String get signInToContinue => _t('سجّل الدخول للمتابعة', 'Sign in to continue');

  // Order extras
  String get orderStatus => _t('حالة الطلب', 'Order status');
  String get orderReference => _t('رقم الطلب', 'Order reference');
  String get placedAt => _t('تاريخ الطلب', 'Placed at');
  String get paymentStatus => _t('حالة الدفع', 'Payment status');
  String get paid => _t('مدفوع', 'Paid');
  String get unpaid => _t('غير مدفوع', 'Unpaid');
  String get authorized => _t('مُصرّح', 'Authorized');
  String get paymentFailed => _t('فشل الدفع', 'Payment failed');
  String get refunded => _t('مسترد', 'Refunded');
  String get partiallyRefunded => _t('مسترد جزئياً', 'Partially refunded');
  String get cancelOrderConfirm =>
      _t('هل تريد إلغاء هذا الطلب؟', 'Cancel this order?');
  String get orderCancelled => _t('تم إلغاء الطلب', 'Order cancelled');
  String get rateYourOrder => _t('قيّم تجربتك', 'Rate your experience');
  String get starsRequired =>
      _t('اختر تقييماً للمطعم أو السائق', 'Rate the restaurant or driver');
  String get noDriver => _t('لم يُسند سائق بعد', 'No driver assigned yet');
  String get lastSignal => _t('آخر تحديث للموقع', 'Last location update');
  String get staleSignal => _t('الموقع غير محدّث', 'Location is stale');
  String get scheduledFor => _t('موعد الطلب', 'Scheduled for');
  String get fulfillment => _t('طريقة الاستلام', 'Fulfillment');
  String get notes => _t('ملاحظات', 'Notes');
  String get paymentBreakdown => _t('تفاصيل الدفع', 'Payment details');
  String get reorderUnavailable =>
      _t('افتح قائمة المطعم وأضف الأصناف من جديد', 'Open the restaurant menu to add the items again');
  String get callUnavailable => _t('لا يوجد رقم هاتف متاح', 'No phone number available');
  String get orderShareText => _t('تفاصيل طلبي من', 'My order from');
  String get helpWithOrder =>
      _t('تحتاج مساعدة بهذا الطلب؟', 'Need help with this order?');
  String get yourRating => _t('تقييمك', 'Your rating');

  // Address extras
  String get addNewAddress => _t('إضافة عنوان جديد', 'Add a new address');
  String get editAddress => _t('تعديل العنوان', 'Edit address');
  String get deleteAddressConfirm =>
      _t('سيُحذف هذا العنوان نهائياً.', 'This address will be permanently deleted.');
  String get addressSaved => _t('تم حفظ العنوان', 'Address saved');
  String get addressDeleted => _t('تم حذف العنوان', 'Address deleted');
  String get labelHint => _t('مثال: المنزل، العمل', 'e.g. Home, Work');
  String get addressDetailsHint =>
      _t('الشارع، المبنى، الطابق', 'Street, building, floor');
  String get instructionsHint => _t('مثال: اتصل عند الوصول', 'e.g. call on arrival');
  String get locationOptional =>
      _t('الموقع اختياري لكنه يحسّن دقة التوصيل', 'Location is optional but improves delivery accuracy');
  String get coverage => _t('نطاق التغطية', 'Coverage');
  String get checkingCoverage => _t('جارٍ التحقق من التغطية…', 'Checking coverage…');
  String get zone => _t('المنطقة', 'Zone');
  String get invalidCoordinates =>
      _t('أدخل خط عرض وخط طول صحيحين', 'Enter valid latitude and longitude');

  // Wallet extras
  String get walletHistory => _t('حركات المحفظة', 'Wallet activity');
  String get walletInfo =>
      _t('يمكنك استخدام الرصيد للدفع عند إتمام الطلب.', 'You can use this balance to pay at checkout.');
  String get orderPayment => _t('دفع طلب', 'Order payment');
  String get orderRefund => _t('استرداد طلب', 'Order refund');
  String get walletAdjustment => _t('تسوية', 'Adjustment');
  String get walletTopUp => _t('شحن المحفظة', 'Wallet top-up');
  String get walletWithdrawal => _t('سحب من المحفظة', 'Wallet withdrawal');

  // Loyalty extras
  String get loyaltyInfo =>
      _t('تُضاف النقاط بعد إتمام الطلبات.', 'Points are added after completed orders.');
  String get loyaltyHistory => _t('حركات النقاط', 'Points activity');
  String get pointsEarned => _t('نقاط مكتسبة', 'Points earned');
  String get pointsRedeemed => _t('نقاط مستخدمة', 'Points used');

  // Notification extras
  String get markRead => _t('تعليم كمقروء', 'Mark as read');
  String get unread => _t('غير مقروء', 'Unread');
  String get notificationOrder => _t('عرض الطلب', 'View order');

  // Support extras
  String get ticketStatus => _t('الحالة', 'Status');
  String get ticketOpen => _t('مفتوحة', 'Open');
  String get ticketClosed => _t('مغلقة', 'Closed');
  String get ticketResolved => _t('تم الحل', 'Resolved');
  String get ticketInProgress => _t('قيد المعالجة', 'In progress');
  String get priorityLow => _t('منخفضة', 'Low');
  String get priorityNormal => _t('عادية', 'Normal');
  String get priorityHigh => _t('عالية', 'High');
  String get priorityUrgent => _t('عاجلة', 'Urgent');
  String get categoryGeneral => _t('عام', 'General');
  String get categoryOrder => _t('الطلب', 'Order');
  String get categoryPayment => _t('الدفع', 'Payment');
  String get categoryDelivery => _t('التوصيل', 'Delivery');
  String get categoryAccount => _t('الحساب', 'Account');
  String get relatedOrder => _t('الطلب المرتبط', 'Related order');
  String get replySent => _t('أُرسل الرد', 'Reply sent');
  String get ticketClosedNotice => _t('هذه التذكرة مغلقة.', 'This ticket is closed.');
  String get supportIntro =>
      _t('أرسل تذكرة وسيتواصل معك فريق الدعم.', 'Send a ticket and our support team will follow up.');
  String get subjectHint => _t('مثال: الطلب متأخر', 'e.g. the order is late');
  String get descriptionHint =>
      _t('اشرح المشكلة بالتفصيل…', 'Describe the issue in detail…');

  // Profile & settings extras
  String get saveChanges => _t('حفظ التغييرات', 'Save changes');
  String get profileUpdated => _t('تم تحديث الملف الشخصي', 'Profile updated');
  String get nameRequired => _t('الاسم مطلوب', 'Name is required');
  String get emailHint => _t('example@email.com', 'example@email.com');
  String get phoneReadOnly =>
      _t('لا يمكن تغيير رقم الهاتف من هنا', 'Phone number cannot be changed here');
  String get appLanguage => _t('لغة التطبيق', 'App language');
  String get privacy => _t('الخصوصية', 'Privacy');
  String get privacyNotice =>
      _t('تُحفظ جلستك بشكل آمن على هذا الجهاز.', 'Your session is stored securely on this device.');
  String get appVersion => _t('إصدار التطبيق', 'App version');
  String get accountStatus => _t('حالة الحساب', 'Account status');
  String get statusActive => _t('نشط', 'Active');
  String get statusSuspended => _t('موقوف', 'Suspended');
  String get notificationsManagedBySystem =>
      _t('تُدار إشعارات النظام من إعدادات الجهاز.', 'System notifications are managed in device settings.');

  // Favorites extras
  String get favoriteRestaurant => _t('مطعم', 'Restaurant');
  String get favoriteDish => _t('طبق', 'Dish');

  // Errors
  String get requiredField => _t('هذا الحقل مطلوب', 'This field is required');
  String get invalidValue => _t('قيمة غير صالحة', 'Invalid value');
  String get notAuthorized => _t('سجّل الدخول للمتابعة', 'Sign in to continue');
  String get accountSuspended =>
      _t('الحساب موقوف. تواصل مع الدعم.', 'Account suspended. Contact support.');
}
