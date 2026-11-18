import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/bootstrap/app_bootstrap.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/green_web/photo_sync_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    final auth = context.read<AuthProvider>();
    await AppBootstrap.run(
      auth: auth,
      diseases: context.read<DiseasesProvider>(),
      sync: context.read<PhotoSyncService>(),
    );
    if (!mounted) return;
    final user = auth.currentUser;
    if (user == null) {
      context.go('/login');
    } else {
      context.go(user.hasSecurityQuestion ? '/home' : '/security-setup');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final t = context.watch<LocaleProvider>().t;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_white.png',
                width: 132,
                height: 132,
                cacheWidth: 400,
              ),
              const SizedBox(height: 20),
              Text('GREEN', style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary, letterSpacing: 2)),
              const SizedBox(height: 8),
              Text(t('appTagline'), style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 32),
              const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
            ],
          ),
        ),
      ),
    );
  }
}
