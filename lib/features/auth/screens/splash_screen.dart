import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/animation_effects.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  void _navigateToHome() {
    Future.delayed(const Duration(seconds: 3), () async {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        // Wait for auth to be fully restored if needed, though main.dart calls restoreFromCache already.
        if (authProvider.isAuthenticated) {
          context.go('/home');
        } else {
          context.go('/login');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fond clair fixe (quel que soit le thème) pour rester cohérent avec le
    // fond blanc du logo lui-même, plutôt que le dégradé vert plein écran
    // utilisé ailleurs dans l'app.
    const backgroundColor = Colors.white;
    final t = context.watch<LocaleProvider>().t;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/logo_dark.png',
              width: 160,
              height: 160,
            ).scaleIn(duration: AppConstants.animationNormal),
            const SizedBox(height: 32),
            Text(
                  'Green',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppColors.lightPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 300))
                .slideY(begin: 20, end: 0),
            const SizedBox(height: 12),
            Text(
                  t('appTagline'),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.lightHint,
                    fontSize: AppConstants.fontSizeMedium,
                  ),
                )
                .animate()
                .fadeIn(delay: const Duration(milliseconds: 600))
                .slideY(begin: 20, end: 0),
            const SizedBox(height: 60),
            SizedBox(
              width: 44,
              height: 44,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.lightPrimary,
                ),
              ),
            ).animate().fadeIn(delay: const Duration(milliseconds: 900)),
          ],
        ),
      ),
    );
  }
}
