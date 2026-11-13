import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/account/account_screen.dart';
import '../presentation/addresses/address_form_screen.dart';
import '../presentation/addresses/addresses_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/cart/cart_screen.dart';
import '../presentation/favorites/favorites_screen.dart';
import '../presentation/home/home_screen.dart';
import '../presentation/loyalty/loyalty_screen.dart';
import '../presentation/notifications/notifications_screen.dart';
import '../presentation/orders/order_detail_screen.dart';
import '../presentation/orders/orders_screen.dart';
import '../presentation/profile/profile_screen.dart';
import '../presentation/restaurant/restaurant_screen.dart';
import '../presentation/restaurants/restaurants_screen.dart';
import '../presentation/search/search_screen.dart';
import '../presentation/settings/settings_screen.dart';
import '../presentation/support/new_ticket_screen.dart';
import '../presentation/support/support_screen.dart';
import '../presentation/support/ticket_screen.dart';
import '../presentation/wallet/wallet_screen.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (context, state) => const OrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            SearchScreen(initialQuery: state.uri.queryParameters['q']),
      ),
      GoRoute(
        path: '/restaurants',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => RestaurantsScreen(
          initialCategoryId: state.uri.queryParameters['categoryId'],
        ),
      ),
      GoRoute(
        path: '/restaurants/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            RestaurantScreen(restaurantId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/cart',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/login',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            LoginScreen(next: state.uri.queryParameters['next']),
      ),
      GoRoute(
        path: '/orders/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/account/profile',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/account/addresses',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/account/addresses/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddressFormScreen(),
      ),
      GoRoute(
        path: '/account/addresses/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            AddressFormScreen(addressId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/account/wallet',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/account/loyalty',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const LoyaltyScreen(),
      ),
      GoRoute(
        path: '/account/notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/account/support',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SupportScreen(),
      ),
      GoRoute(
        path: '/account/support/new',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            NewTicketScreen(orderId: state.uri.queryParameters['orderId']),
      ),
      GoRoute(
        path: '/account/support/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            TicketScreen(ticketId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/account/settings',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
