import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../features/auth/screens/account_recovery_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/security_question_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/camera/screens/camera_screen.dart';
import '../../features/camera/screens/field_sheet_screen.dart';
import '../../features/chat/screens/chat_screen.dart';
import '../../features/diseases/screens/diseases_screen.dart';
import '../../features/history/screens/history_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/marketplace/screens/cart_screen.dart';
import '../../features/marketplace/screens/category_products_screen.dart';
import '../../features/marketplace/screens/marketplace_screen.dart';
import '../../features/marketplace/screens/product_detail_screen.dart';
import '../../features/profile/screens/about_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/weather/screens/weather_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../shared/widgets/main_navigation_shell.dart';

/// Navigation de l'application.
///
/// Règles v2 :
/// - les quatre onglets vivent dans la coque ; tout le reste est empilé
///   par-dessus avec `push`, si bien que le bouton retour (et le geste
///   système) ramène toujours à l'écran précédent — la v1 utilisait `go` et
///   un paramètre « from » qui cassait la pile de navigation ;
/// - garde d'accès : sans session, toute page protégée renvoie à la connexion.
GoRouter createRouter(AuthProvider auth) {
  const publicPaths = {'/', '/login', '/register', '/recover'};

  return GoRouter(
    initialLocation: '/',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.matchedLocation;
      if (path == '/') return null; // le démarrage décide lui-même
      final loggedIn = auth.isAuthenticated;
      if (!loggedIn && !publicPaths.contains(path)) return '/login';
      // Ancien compte sans question de sécurité : configuration obligatoire.
      if (loggedIn && auth.currentUser?.hasSecurityQuestion == false && path != '/security-setup') {
        return '/security-setup';
      }
      if (loggedIn && (path == '/login' || path == '/register' || path == '/recover')) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: '/recover',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>? ?? const {};
          return AccountRecoveryScreen(
            identifier: extra['identifier'] as String? ?? '',
            questionId: extra['questionId'] as String? ?? 'q1',
          );
        },
      ),
      GoRoute(path: '/forgot-password', redirect: (_, _) => '/login'),
      GoRoute(path: '/security-setup', builder: (_, _) => const SecurityQuestionScreen()),
      GoRoute(path: '/security-question', builder: (_, _) => const SecurityQuestionScreen(change: true)),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainNavigationShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/home', builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/camera', builder: (_, _) => const CameraScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/chat',
              builder: (_, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return ChatScreen(
                  initialMessage: extra?['initialMessage'] as String?,
                  cacheKey: extra?['cacheKey'] as String?,
                  autoSend: extra?['autoSend'] as bool? ?? true,
                );
              },
            ),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/marketplace', builder: (_, _) => const MarketplaceScreen())]),
        ],
      ),
      GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/preferences', redirect: (_, _) => '/settings'),
      GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
      GoRoute(path: '/weather', builder: (_, _) => const WeatherScreen()),
      GoRoute(path: '/history', builder: (_, _) => const HistoryScreen()),
      GoRoute(path: '/scan/:id', builder: (_, state) => FieldSheetScreen(scanId: state.pathParameters['id']!)),
      GoRoute(path: '/diseases', builder: (_, _) => const DiseasesScreen()),
      GoRoute(
        path: '/diseases/:id',
        builder: (_, state) => DiseaseDetailScreen(diseaseId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/product-detail',
        builder: (_, state) =>
            ProductDetailScreen(productId: (state.extra as Map?)?['productId'] as String? ?? ''),
      ),
      GoRoute(
        path: '/marketplace/category',
        builder: (_, state) =>
            CategoryProductsScreen(categoryId: (state.extra as Map?)?['categoryId'] as String? ?? ''),
      ),
      GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
    ],
    errorBuilder: (context, state) {
      final t = context.watch<LocaleProvider>().t;
      return Scaffold(
        appBar: AppBar(title: Text(t('error'))),
        body: Center(
          child: FilledButton(onPressed: () => context.go('/home'), child: Text(t('returnToHome'))),
        ),
      );
    },
  );
}
