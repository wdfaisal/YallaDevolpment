import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/data/models/account.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';
import 'package:yalla_talabat_customer/presentation/wallet/wallet_screen.dart';
import 'package:yalla_talabat_customer/presentation/wallet/widgets/wallet_balance_card.dart';
import 'package:yalla_talabat_customer/state/account_controllers.dart';
import 'package:yalla_talabat_customer/state/session_controller.dart';

import 'support/test_app.dart';

const L10n _l10n = L10n(true);

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

const _summary = WalletSummary(
  availableMinor: 14250,
  heldMinor: 500,
  currency: 'SAR',
  entries: [
    WalletEntry(
      id: 'w1',
      kind: 'order',
      amountMinor: -6850,
      reference: '#98241',
      note: 'طلب من شاورمر',
      createdAt: '2026-11-14T14:15:00.000Z',
    ),
    WalletEntry(
      id: 'w2',
      kind: 'order_refund',
      amountMinor: 1500,
      reference: null,
      note: 'كاش باك ترويجي',
      createdAt: '2026-11-13T20:30:00.000Z',
    ),
    WalletEntry(
      id: 'w3',
      kind: 'top_up',
      amountMinor: 10000,
      reference: 'TOP-4819',
      note: null,
      createdAt: '2026-10-12T11:20:00.000Z',
    ),
  ],
);

class _SignedInSession extends SessionController {
  @override
  Future<CustomerProfile?> build() async => _profile;
}

class _FakeWallet extends WalletController {
  _FakeWallet(this.summary);

  final WalletSummary summary;

  @override
  Future<WalletSummary> build() async => summary;
}

Future<void> _pumpWallet(
  WidgetTester tester, {
  WalletSummary summary = _summary,
}) async {
  tester.view.physicalSize = const Size(430, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    testApp(
      const WalletScreen(),
      overrides: [
        sessionProvider.overrideWith(_SignedInSession.new),
        walletProvider.overrideWith(() => _FakeWallet(summary)),
      ],
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders the redesigned wallet with live summary data', (
    tester,
  ) async {
    await _pumpWallet(tester);

    expect(tester.takeException(), isNull);
    expect(find.text(_l10n.walletCardTitle), findsOneWidget);
    expect(find.text(_l10n.walletDigitalBalance), findsOneWidget);
    expect(find.text(_l10n.walletCash), findsOneWidget);
    expect(find.text('142.50'), findsOneWidget);
    expect(find.text('SAR'), findsOneWidget);
    expect(find.text(_l10n.heldBalance), findsOneWidget);
    expect(find.text(_l10n.walletSecurePayment), findsOneWidget);

    expect(find.text(_l10n.walletTopUpAction), findsOneWidget);
    expect(find.text(_l10n.walletGift), findsOneWidget);
    expect(find.text(_l10n.walletRewards), findsOneWidget);
    expect(find.text(_l10n.walletReadOnlyNotice), findsOneWidget);

    expect(find.text(_l10n.walletRecent), findsOneWidget);
    expect(find.text(_l10n.walletViewAll), findsOneWidget);
    expect(find.text(_l10n.walletFilterAll), findsOneWidget);
    expect(find.text(_l10n.walletFilterTopUp), findsOneWidget);
    expect(find.text(_l10n.walletFilterPurchases), findsOneWidget);
    expect(find.text(_l10n.walletFilterCashback), findsOneWidget);

    expect(find.text('طلب من شاورمر'), findsOneWidget);
    expect(find.text('-68.50 SAR'), findsOneWidget);
    expect(find.text('+15.00 SAR'), findsOneWidget);
    expect(find.text('+100.00 SAR'), findsOneWidget);
    expect(find.text(_l10n.walletCompleted), findsNWidgets(2));
  });

  testWidgets('the ledger filters by top-up, purchases and cashback', (
    tester,
  ) async {
    await _pumpWallet(tester);

    await tester.tap(find.text(_l10n.walletFilterPurchases));
    await tester.pumpAndSettle();
    expect(find.text('-68.50 SAR'), findsOneWidget);
    expect(find.text('+15.00 SAR'), findsNothing);
    expect(find.text('+100.00 SAR'), findsNothing);

    await tester.tap(find.text(_l10n.walletFilterTopUp));
    await tester.pumpAndSettle();
    expect(find.text('-68.50 SAR'), findsNothing);
    expect(find.text('+100.00 SAR'), findsOneWidget);

    final cashback = find.text(_l10n.walletFilterCashback);
    await tester.ensureVisible(cashback);
    await tester.pumpAndSettle();
    await tester.tap(cashback);
    await tester.pumpAndSettle();
    expect(find.text('+15.00 SAR'), findsOneWidget);
    expect(find.text('+100.00 SAR'), findsNothing);

    await tester.tap(find.text(_l10n.walletViewAll));
    await tester.pumpAndSettle();
    expect(find.text('-68.50 SAR'), findsOneWidget);
    expect(find.text('+15.00 SAR'), findsOneWidget);
    expect(find.text('+100.00 SAR'), findsOneWidget);
  });

  testWidgets('shows the empty ledger state', (tester) async {
    await _pumpWallet(
      tester,
      summary: const WalletSummary(
        availableMinor: 0,
        heldMinor: 0,
        currency: 'SAR',
        entries: [],
      ),
    );

    expect(find.text(_l10n.noWalletEntries), findsOneWidget);
    expect(find.byType(WalletBalanceCard), findsOneWidget);
  });

  testWidgets('uses flat surfaces: no shadows or gradients', (tester) async {
    await _pumpWallet(tester);

    final containers = tester.widgetList<Container>(
      find.descendant(
        of: find.byType(WalletScreen),
        matching: find.byType(Container),
      ),
    );
    for (final container in containers) {
      final decoration = container.decoration;
      if (decoration is BoxDecoration) {
        expect(decoration.boxShadow, isNull);
        expect(decoration.gradient, isNull);
      }
    }
  });
}
