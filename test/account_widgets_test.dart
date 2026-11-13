import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/design/app_colors.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/data/api/token_store.dart';
import 'package:yalla_talabat_customer/data/models/account.dart';
import 'package:yalla_talabat_customer/data/models/catalog.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';
import 'package:yalla_talabat_customer/presentation/account/account_screen.dart';
import 'package:yalla_talabat_customer/presentation/account/widgets/account_footer.dart';
import 'package:yalla_talabat_customer/presentation/account/widgets/account_header.dart';
import 'package:yalla_talabat_customer/presentation/account/widgets/account_menu_section.dart';
import 'package:yalla_talabat_customer/presentation/account/widgets/account_profile_header.dart';
import 'package:yalla_talabat_customer/presentation/account/widgets/account_summary_cards.dart';
import 'package:yalla_talabat_customer/state/account_controllers.dart';
import 'package:yalla_talabat_customer/state/address_controller.dart';
import 'package:yalla_talabat_customer/state/home_controller.dart';
import 'package:yalla_talabat_customer/state/providers.dart';
import 'package:yalla_talabat_customer/state/session_controller.dart';

import 'support/test_app.dart';

const _l10n = L10n(true);

void main() {
  group('AccountHeader', () {
    testWidgets('shows the title and runs the share action', (tester) async {
      var shared = 0;
      await tester.pumpWidget(
        testApp(AccountHeader(onShare: () => shared++)),
      );

      expect(find.text(_l10n.profileTitle), findsOneWidget);
      // No back button on the root tab.
      expect(find.byIcon(Icons.arrow_forward), findsNothing);

      await tester.tap(find.byIcon(Icons.share_outlined));
      expect(shared, 1);
    });
  });

  group('AccountProfileHeader', () {
    testWidgets('renders name, phone and initials fallback', (tester) async {
      var edited = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: AccountProfileHeader(
              name: 'أحمد علي',
              phone: '+966500000000',
              email: 'ahmed@example.com',
              initials: 'أع',
              avatarUrl: null,
              onEdit: () => edited++,
            ),
          ),
        ),
      );

      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('+966500000000'), findsOneWidget);
      expect(find.text('ahmed@example.com'), findsOneWidget);
      expect(find.text('أع'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.photo_camera_outlined));
      expect(edited, 1);
    });
  });

  group('AccountSummaryCards', () {
    testWidgets('renders three cards and reports the tapped action',
        (tester) async {
      tester.view.physicalSize = const Size(430, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final tapped = <String>[];
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: AccountSummaryCards(
              cards: [
                AccountSummaryCardData(
                  label: _l10n.walletCardTitle,
                  value: '123.45',
                  unit: _l10n.currencyDefault,
                  icon: Icons.account_balance_wallet,
                  iconColor: AppColors.profileAccent,
                  actionLabel: _l10n.topUpBalance,
                  accentAction: true,
                  onAction: () => tapped.add('wallet'),
                ),
                AccountSummaryCardData(
                  label: _l10n.rewardPoints,
                  value: '120',
                  unit: _l10n.points,
                  icon: Icons.loyalty,
                  iconColor: AppColors.profileEmerald,
                  actionLabel: _l10n.redeem,
                  onAction: () => tapped.add('loyalty'),
                ),
                AccountSummaryCardData(
                  label: _l10n.offers,
                  value: '2',
                  unit: _l10n.offersUnit,
                  icon: Icons.local_activity_outlined,
                  iconColor: AppColors.profileAmber,
                  actionLabel: _l10n.browse,
                  onAction: () => tapped.add('offers'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text(_l10n.walletCardTitle), findsOneWidget);
      expect(find.text(_l10n.rewardPoints), findsOneWidget);
      expect(find.text(_l10n.offers), findsOneWidget);
      expect(find.text('123.45'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);

      await tester.tap(find.text(_l10n.topUpBalance));
      await tester.tap(find.text(_l10n.redeem));
      expect(tapped, ['wallet', 'loyalty']);
    });
  });

  group('AccountMenuSection', () {
    testWidgets('renders rows, badge, switch and fires taps', (tester) async {
      var rowTaps = 0;
      var enabled = false;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: AccountMenuSection(
              title: 'قسم',
              children: [
                AccountMenuTile(
                  icon: Icons.location_on,
                  iconColor: AppColors.profileAccent,
                  iconBackground: AppColors.profileAccentTint,
                  title: 'عنوان',
                  subtitle: 'تفاصيل',
                  titleBadge: const AccountCountBadge(label: '3'),
                  onTap: () => rowTaps++,
                ),
                AccountMenuTile(
                  icon: Icons.notifications_active,
                  iconColor: AppColors.profileOrange,
                  iconBackground: AppColors.profileOrangeTint,
                  title: 'تنبيهات',
                  showChevron: false,
                  trailing: AccountSwitch(
                    value: enabled,
                    onChanged: (value) => enabled = value,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('قسم'), findsOneWidget);
      expect(find.text('عنوان'), findsOneWidget);
      expect(find.text('تفاصيل'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      // Only the tappable row shows a chevron (RTL points left).
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);

      await tester.tap(find.text('عنوان'));
      expect(rowTaps, 1);

      await tester.tap(find.byType(AccountSwitch));
      expect(enabled, isTrue);
    });
  });

  group('AccountFooter', () {
    testWidgets('shows the version and only offers sign out when signed in',
        (tester) async {
      var signedOut = 0;
      await tester.pumpWidget(
        testApp(
          Scaffold(
            body: AccountFooter(
              versionLabel: 'الإصدار 1.0.0',
              onSignOut: () => signedOut++,
            ),
          ),
        ),
      );

      expect(find.text('الإصدار 1.0.0'), findsOneWidget);
      await tester.tap(find.text(_l10n.signOut));
      expect(signedOut, 1);

      await tester.pumpWidget(
        testApp(const Scaffold(body: AccountFooter(versionLabel: 'v1'))),
      );
      expect(find.text('v1'), findsOneWidget);
      expect(find.text(_l10n.signOut), findsNothing);
    });
  });

  group('AccountScreen', () {
    testWidgets('guest sees the sign-in card and no sign-out', (tester) async {
      await tester.pumpWidget(
        testApp(
          const AccountScreen(),
          overrides: [sessionProvider.overrideWith(_GuestSession.new)],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_l10n.guest), findsOneWidget);
      expect(find.text(_l10n.signIn), findsOneWidget);
      expect(find.text(_l10n.signOut), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('signed-in customer sees live summary and sections',
        (tester) async {
      tester.view.physicalSize = const Size(430, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final store = _FakeTokenStore();
      await tester.pumpWidget(
        testApp(
          const AccountScreen(),
          overrides: [
            sessionProvider.overrideWith(() => _SignedInSession(_profile)),
            walletProvider.overrideWith(
              () => _FakeWallet(
                const WalletSummary(
                  availableMinor: 12345,
                  heldMinor: 0,
                  currency: 'SAR',
                  entries: [],
                ),
              ),
            ),
            loyaltyProvider.overrideWith(
              () => _FakeLoyalty(
                const LoyaltySummary(points: 120, entries: []),
              ),
            ),
            homeProvider.overrideWith(() => _FakeHome(_home)),
            addressesProvider.overrideWith(
              () => _FakeAddresses(
                AddressSelection(
                    addresses: [_address], selectedId: _address.id),
              ),
            ),
            tokenStoreProvider.overrideWithValue(store),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('أحمد علي'), findsOneWidget);
      expect(find.text('+966500000000'), findsOneWidget);
      expect(find.text('123.45'), findsOneWidget);
      expect(find.text('120'), findsOneWidget);
      expect(find.text(_l10n.manageOrdersAndPayments), findsOneWidget);
      expect(find.text(_l10n.preferencesAndSettings), findsOneWidget);
      expect(find.text(_l10n.supportAndInfo), findsOneWidget);
      expect(find.text(_l10n.savedAddressesSubtitle(1)), findsOneWidget);
      expect(find.text(_l10n.signOut), findsOneWidget);

      await tester.tap(find.byType(AccountSwitch));
      await tester.pumpAndSettle();
      expect(store.enabled, isFalse);
      expect(tester.takeException(), isNull);
    });
  });
}

const _profile = CustomerProfile(
  id: 'cus_1',
  name: 'أحمد علي',
  initials: 'أع',
  phone: '+966500000000',
  email: 'ahmed@example.com',
  language: 'ar',
  avatarUrl: null,
  status: 'active',
  memberSince: '2024-01-01',
  orderCount: 12,
  defaultAddress: null,
);

const _address = CustomerAddressRecord(
  id: 'adr_1',
  label: 'المنزل',
  address: 'الرياض',
  lat: 24.7,
  lng: 46.7,
  isDefault: true,
  instructions: '',
  zoneId: null,
  cityId: null,
  updatedAt: '2024-01-01',
);

const _home = CatalogHome(
  sections: [],
  services: [],
  banners: [],
  offers: [],
  nearby: [],
  bestSellers: [],
  restaurants: [],
  categories: [],
  address: null,
  eligibility: null,
);

class _GuestSession extends SessionController {
  @override
  Future<CustomerProfile?> build() async => null;
}

class _SignedInSession extends SessionController {
  _SignedInSession(this.profile);

  final CustomerProfile profile;

  @override
  Future<CustomerProfile?> build() async => profile;
}

class _FakeWallet extends WalletController {
  _FakeWallet(this.summary);

  final WalletSummary summary;

  @override
  Future<WalletSummary> build() async => summary;
}

class _FakeLoyalty extends LoyaltyController {
  _FakeLoyalty(this.summary);

  final LoyaltySummary summary;

  @override
  Future<LoyaltySummary> build() async => summary;
}

class _FakeHome extends HomeController {
  _FakeHome(this.home);

  final CatalogHome home;

  @override
  Future<CatalogHome> build() async => home;
}

class _FakeAddresses extends AddressesController {
  _FakeAddresses(this.selection);

  final AddressSelection selection;

  @override
  Future<AddressSelection> build() async => selection;
}

class _FakeTokenStore extends TokenStore {
  bool enabled = true;

  @override
  bool get cachedNotificationsEnabled => enabled;

  @override
  Future<bool?> readNotificationsEnabled() async => enabled;

  @override
  Future<void> writeNotificationsEnabled(bool value) async {
    enabled = value;
  }
}
