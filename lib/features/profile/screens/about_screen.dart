import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_pop_scope.dart';

class AboutScreen extends StatelessWidget {
  final String? from;

  const AboutScreen({super.key, this.from});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return AppPopScope(
      onWillPop: () async {
        if (from == 'profile') {
          context.go('/profile');
        } else {
          context.go('/home');
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: CustomAppBar(title: 'À propos', isDarkMode: isDarkMode),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.paddingLarge),
            child: Column(
              children: [
                // Logo Section
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: isDarkMode
                        ? AppColors.darkGradient
                        : AppColors.lightGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(0, 0, 0, 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.eco,
                    size: 60,
                    color: Colors.white,
                  ),
                ).animate().scale(duration: AppConstants.animationNormal).then().shimmer(delay: 1.seconds, duration: 2.seconds),
                const SizedBox(height: 24),
                
                Text(
                  'GREEN',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                  ),
                ).animate().fadeIn().slideY(begin: 10, end: 0),
                const SizedBox(height: 8),
                Text(
                  'v1.0.0',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                  ),
                ),
                const SizedBox(height: 32),

                // Description
                Text(
                  'Votre assistant intelligent pour la détection des maladies des plantes et l\'accompagnement agricole.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ).animate(delay: 200.ms).fadeIn(),
                const SizedBox(height: 32),

                // Contributors Section
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Équipe de réalisation',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Ingénieurs chercheurs en Sciences de Données et Intelligence Artificielle niveau 3',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'École Nationale Supérieure Polytechnique de Douala (ENSPD)',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: 400.ms).fadeIn().slideY(begin: 20, end: 0),
                
                const SizedBox(height: 32),
                
                // Copyright
                Text(
                  '© 2026 Green Project. Tous droits réservés.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
