import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
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
    Future.delayed(const Duration(seconds: 7), () {
      if (mounted) {
        context.go('/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: isDarkMode
              ? AppColors.darkGradient
              : AppColors.lightGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color.fromRGBO(255, 255, 255, 0.2),
                ),
                child: const Icon(Icons.eco, size: 70, color: Colors.white),
              ).scaleIn(duration: AppConstants.animationNormal),
              const SizedBox(height: 40),
              Text(
                    'Green',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 300))
                  .slideY(begin: 20, end: 0),
              const SizedBox(height: 12),
              Text(
                    'Naturellement Intelligent',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color.fromRGBO(255, 255, 255, 0.9),
                      fontSize: AppConstants.fontSizeMedium,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: const Duration(milliseconds: 600))
                  .slideY(begin: 20, end: 0),
              const SizedBox(height: 60),
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color.fromRGBO(255, 255, 255, 0.8),
                  ),
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 900)),
            ],
          ),
        ),
      ),
    );
  }
}
