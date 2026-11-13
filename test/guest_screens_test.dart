import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yalla_talabat_customer/core/localization/app_localizations.dart';
import 'package:yalla_talabat_customer/core/localization/l10n.dart';
import 'package:yalla_talabat_customer/data/models/customer.dart';
import 'package:yalla_talabat_customer/presentation/addresses/addresses_screen.dart';
import 'package:yalla_talabat_customer/presentation/auth/login_screen.dart';
import 'package:yalla_talabat_customer/presentation/favorites/favorites_screen.dart';
import 'package:yalla_talabat_customer/presentation/loyalty/loyalty_screen.dart';
import 'package:yalla_talabat_customer/presentation/notifications/notifications_screen.dart';
import 'package:yalla_talabat_customer/presentation/orders/orders_screen.dart';
import 'package:yalla_talabat_customer/presentation/profile/profile_screen.dart';
import 'package:yalla_talabat_customer/presentation/support/support_screen.dart';
import 'package:yalla_talabat_customer/presentation/wallet/wallet_screen.dart';
import 'package:yalla_talabat_customer/state/session_controller.dart';

/// Deterministic guest session: no secure-storage plugin in widget tests.
class _GuestSession extends SessionController {
  @override
  Future<CustomerProfile?> build() async => null;
}

Widget _routerApp(Widget child, {Locale locale = const Locale('ar')}) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (_, __) => child)],
  );
  return ProviderScope(
    overrides: [sessionProvider.overrideWith(_GuestSession.new)],
    child: MaterialApp.router(
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        AppMaterialLocalizationsDelegate(),
        AppCupertinoLocalizationsDelegate(),
        GlobalWidgetsLocalizations.delegate,
      ],
    ),
  );
}

void main() {
  group('guest screens ask for sign in', () {
    final screens = <String, Widget>{
      'favorites': const FavoritesScreen(),
      'orders': const OrdersScreen(),
      'wallet': const WalletScreen(),
      'loyalty': const LoyaltyScreen(),
      'notifications': const NotificationsScreen(),
      'support': const SupportScreen(),
      'profile': const ProfileScreen(),
      'addresses': const AddressesScreen(),
    };

    for (final entry in screens.entries) {
      testWidgets('${entry.key} shows the sign-in prompt', (tester) async {
        await tester.pumpWidget(_routerApp(entry.value));
        await tester.pumpAndSettle();
        expect(find.text(const L10n(true).notAuthorized), findsOneWidget);
      });
    }
  });

  group('LoginScreen phone validation', () {
    testWidgets('rejects a short phone number without calling the API',
        (tester) async {
      await tester.pumpWidget(_routerApp(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '123');
      await tester.tap(find.text(const L10n(true).sendCode));
      await tester.pump();

      expect(find.text(const L10n(true).invalidPhone), findsOneWidget);
    });

    testWidgets('renders English copy when the locale is English',
        (tester) async {
      await tester.pumpWidget(
        _routerApp(const LoginScreen(), locale: const Locale('en')),
      );
      await tester.pumpAndSettle();

      expect(find.text(const L10n(false).sendCode), findsOneWidget);
      expect(find.text(const L10n(false).loginSubtitle), findsOneWidget);
    });
  });
}
