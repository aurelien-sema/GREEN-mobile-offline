import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/locale_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/camera/screens/camera_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/diseases/screens/diseases_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

import '../../features/profile/screens/preferences_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../shared/widgets/main_navigation_shell.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/weather/screens/weather_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/marketplace/screens/product_detail_screen.dart';
import '../../features/marketplace/screens/category_products_screen.dart';
import '../../features/marketplace/screens/cart_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      name: 'register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      name: 'forgot-password',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    // Main navigation with BottomNavigationBar
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainNavigationShell(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/camera',
              name: 'camera',
              builder: (context, state) => const CameraScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/chat',
              name: 'chat',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return ChatScreen(
                  initialMessage: extra?['initialMessage'] as String?,
                  cacheKey: extra?['cacheKey'] as String?,
                  autoSend: extra?['autoSend'] as bool? ?? true,
                );
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/marketplace',
              name: 'marketplace',
              builder: (context, state) => const MarketplaceScreen(),
            ),
          ],
        ),
      ],
    ),
    // Profile (outside bottom nav with back button)
    GoRoute(
      path: '/profile',
      name: 'profile',
      builder: (context, state) =>
          ProfileScreen(from: (state.extra as Map?)?['from'] as String?),
    ),
    // Product detail (outside bottom nav)
    GoRoute(
      path: '/product-detail',
      name: 'product-detail',
      builder: (context, state) {
        final productId = (state.extra as Map?)?['productId'] as String? ?? '';
        return ProductDetailScreen(productId: productId);
      },
    ),
    // Tous les produits d'une catégorie ("Voir tout" depuis la Marketplace)
    GoRoute(
      path: '/marketplace/category',
      name: 'marketplace-category',
      builder: (context, state) {
        final categoryId = (state.extra as Map?)?['categoryId'] as String? ?? '';
        return CategoryProductsScreen(categoryId: categoryId);
      },
    ),
    // Panier
    GoRoute(
      path: '/cart',
      name: 'cart',
      builder: (context, state) => const CartScreen(),
    ),
    // Diseases (accessible from drawer or home)
    GoRoute(
      path: '/diseases',
      name: 'diseases',
      builder: (context, state) => const DiseasesScreen(),
    ),
    // Settings and other routes (without bottom nav)
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) =>
          SettingsScreen(from: (state.extra as Map?)?['from'] as String?),
    ),

    GoRoute(
      path: '/preferences',
      name: 'preferences',
      builder: (context, state) =>
          PreferencesScreen(from: (state.extra as Map?)?['from'] as String?),
    ),
    GoRoute(
      path: '/about',
      name: 'about',
      builder: (context, state) =>
          AboutScreen(from: (state.extra as Map?)?['from'] as String?),
    ),
    GoRoute(
      path: '/weather',
      name: 'weather',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return WeatherScreen(
          lat: extra?['lat'] as double?,
          lon: extra?['lon'] as double?,
        );
      },
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
  initialLocation: '/',
  errorBuilder: (context, state) {
    final t = context.watch<LocaleProvider>().t;
    return Scaffold(
    appBar: AppBar(title: Text(t('error'))),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('${t('error')}: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: Text(t('returnToHome')),
          ),
        ],
      ),
    ),
  );
  },
);
