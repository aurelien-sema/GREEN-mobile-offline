import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
import '../../features/profile/screens/notifications_screen.dart';
import '../../features/profile/screens/preferences_screen.dart';
import '../../shared/widgets/main_navigation_shell.dart';
import '../../features/history/screens/history_screen.dart';

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
              builder: (context, state) => const ChatScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
        // Profile branch removed from bottom navigation per UI request
      ],
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
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) =>
          NotificationsScreen(from: (state.extra as Map?)?['from'] as String?),
    ),
    GoRoute(
      path: '/preferences',
      name: 'preferences',
      builder: (context, state) =>
          PreferencesScreen(from: (state.extra as Map?)?['from'] as String?),
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
  initialLocation: '/',
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(title: const Text('Erreur')),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Erreur: ${state.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/home'),
            child: const Text('Retourner à l\'accueil'),
          ),
        ],
      ),
    ),
  ),
);
