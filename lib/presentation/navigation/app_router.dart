import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/products/products_screen.dart';
import '../../features/product_detail/product_detail_screen.dart';
import '../../features/product_detail/combo_detail_screen.dart';
import '../../features/cart/cart_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../features/profile/notifications_screen.dart';
import '../../features/home/blog_detail_screen.dart';
import '../../presentation/providers/orders_provider.dart';
import 'main_shell.dart';

// Notifies GoRouter to re-evaluate redirect whenever auth state changes
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
  }
}

// ─── Route Names ──────────────────────────────────────────────────────────────

class AppRoutes {
  static const login = '/login';
  static const home = '/home';
  static const products = '/products';
  static const productDetail = '/product/:slug';
  static const comboDetail = '/combo/:id';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const orders = '/orders';
  static const profile = '/profile';
  static const addresses = '/addresses';
  static const notifications = '/notifications';
  static const blogDetailBase = '/blog';

  static String productDetailPath(String slug) => '/product/$slug';
  static String comboDetailPath(String id) => '/combo/$id';
  static String blogDetail(String slug) => '/blog/$slug';
}

// ─── Router Provider ─────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: notifier,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      // Wait until SharedPreferences load completes before redirecting
      if (!auth.isInitialized) return null;
      // Already logged in → skip login screen and go straight to home
      if (auth.isLoggedIn && state.matchedLocation == AppRoutes.login) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      // Login
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _slideTransition(
          state,
          const LoginScreen(),
        ),
      ),

      // Main Shell (Bottom Navigation)
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) => _noTransition(state, const HomeScreen()),
          ),
          GoRoute(
            path: AppRoutes.products,
            pageBuilder: (context, state) => _noTransition(state, const ProductsScreen()),
          ),
          GoRoute(
            path: AppRoutes.cart,
            pageBuilder: (context, state) => _noTransition(state, const CartScreen()),
          ),
          GoRoute(
            path: AppRoutes.orders,
            pageBuilder: (context, state) => _noTransition(state, const OrdersScreen()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) => _noTransition(state, const ProfileScreen()),
          ),
        ],
      ),

      // Product Detail (Hero push)
      GoRoute(
        path: AppRoutes.productDetail,
        pageBuilder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return _slideTransition(state, ProductDetailScreen(slug: slug));
        },
      ),

      // Combo Detail
      GoRoute(
        path: AppRoutes.comboDetail,
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _slideTransition(state, ComboDetailScreen(comboId: id));
        },
      ),

      // Addresses
      GoRoute(
        path: AppRoutes.addresses,
        pageBuilder: (context, state) =>
            _slideTransition(state, const AddressesScreen()),
      ),

      // Blog Detail
      GoRoute(
        path: '/blog/:slug',
        pageBuilder: (context, state) {
          final slug = state.pathParameters['slug']!;
          return _slideTransition(state, BlogDetailScreen(blogSlug: slug));
        },
      ),

      // Notifications
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _slideTransition(state, const NotificationsScreen()),
      ),

      // Checkout
      GoRoute(
        path: AppRoutes.checkout,
        pageBuilder: (context, state) => _slideTransition(state, const CheckoutScreen()),
      ),
    ],
  );
});

// ─── Transitions ─────────────────────────────────────────────────────────────

CustomTransitionPage<void> _fadeTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

CustomTransitionPage<void> _slideTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
    transitionDuration: const Duration(milliseconds: 350),
  );
}

CustomTransitionPage<void> _noTransition(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    transitionsBuilder: (_, __, ___, child) => child,
  );
}
