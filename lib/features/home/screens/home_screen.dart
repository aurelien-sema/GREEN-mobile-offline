import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../services/weather_service.dart';
import '../../../services/history_service.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/custom_scroll_physics.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    return Scaffold(
      body: GradientBackground(
        isDarkMode: isDarkMode,
        opacity: 0.1,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const SmoothScrollPhysics(),
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: isDarkMode
                            ? AppColors.darkGradient
                            : AppColors.lightGradient,
                        borderRadius: BorderRadius.circular(
                          AppConstants.radiusXLarge,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromRGBO(0, 0, 0, 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(AppConstants.paddingLarge),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bienvenue !',
                            style: Theme.of(context).textTheme.displayMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scannez vos plantes et obtenez des diagnostics instantanés',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: const Color.fromRGBO(
                                    255,
                                    255,
                                    255,
                                    0.9,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal)
                    .slideY(begin: 20, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),

                // Section Title
                Text(
                      'Fonctionnalités principales',
                      style: Theme.of(context).textTheme.headlineMedium,
                    )
                    .animate()
                    .fadeIn(delay: const Duration(milliseconds: 100))
                    .slideX(begin: -20, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),

                // Climate Card (full width)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusMedium,
                    ),
                  ),
                  color: isDarkMode ? null : null,
                  child: Container(
                    width: double.infinity,
                    // original height used elsewhere; we set card to two-thirds of that
                    // original default was 160 previously
                    height: 160 * 2 / 3,
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    decoration: BoxDecoration(
                      gradient: isDarkMode
                          ? AppColors.darkGradient
                          : AppColors.lightGradient,
                      borderRadius: BorderRadius.circular(
                        AppConstants.radiusMedium,
                      ),
                    ),
                    child: FutureBuilder<WeatherData>(
                      future: weatherService.fetchWeatherForCity('Douala'),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              SizedBox(),
                              Text(
                                'Chargement...',
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(),
                            ],
                          );
                        }
                        if (snap.hasError || snap.data == null) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Icon(Icons.error, color: Colors.white),
                              Text(
                                'Erreur météo',
                                style: TextStyle(color: Colors.white),
                              ),
                              SizedBox(),
                            ],
                          );
                        }
                        final w = snap.data!;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Temperature
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.thermostat,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${w.temperature.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Description
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.wb_sunny,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(height: 6),
                                  Flexible(
                                    child: Text(
                                      w.description,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Wind
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Icon(Icons.air, color: Colors.white),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${w.windSpeed.toStringAsFixed(1)} m/s',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: AppConstants.paddingLarge),

                // Action buttons (Scanner + Green Bot) in one row, equal size and responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    // Use card's original height (160) for buttons as requested
                    final buttonHeight = 160.0;
                    // Width reduced to leave margins and adapt responsively
                    final horizontalSpacing = AppConstants.paddingMedium;
                    final maxButtonWidth =
                        ((constraints.maxWidth - horizontalSpacing) * 0.46)
                            .clamp(120.0, constraints.maxWidth);

                    Widget buildAction({
                      required VoidCallback onTap,
                      required LinearGradient backgroundGradient,
                      required IconData icon,
                      required String title,
                      required String subtitle,
                    }) {
                      return ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: maxButtonWidth,
                          minWidth: 100,
                        ),
                        child: SizedBox(
                          height: buttonHeight,
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(12),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: backgroundGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Icon(
                                          icon,
                                          color: Colors.white,
                                          size: buttonHeight * 0.28,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          subtitle,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Color.fromRGBO(
                                              255,
                                              255,
                                              255,
                                              0.95,
                                            ),
                                          ),
                                          textAlign: TextAlign.center,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        buildAction(
                          onTap: () => context.go('/camera'),
                          backgroundGradient: isDarkMode
                              ? AppColors.darkGradient
                              : AppColors.lightGradient,
                          icon: Icons.camera_alt,
                          title: 'Scanner',
                          subtitle: 'Analyser une plante',
                        ),
                        SizedBox(width: horizontalSpacing),
                        buildAction(
                          onTap: () => context.go('/chat'),
                          backgroundGradient: isDarkMode
                              ? AppColors.darkGradient
                              : AppColors.lightGradient,
                          icon: Icons.chat_bubble,
                          title: 'Green Bot',
                          subtitle: 'Conseils et diagnostics IA',
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),

                // History header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Consulter l\'historique',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/history'),
                      child: const Text('Voir tout'),
                    ),
                  ],
                ),
                const SizedBox(height: AppConstants.paddingMedium),
                StreamBuilder<void>(
                  stream: historyService.onChanged,
                  builder: (context, _) {
                    return FutureBuilder<List<dynamic>>(
                      future: historyService.getRecentScans(5),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Text('Chargement...');
                        }
                        final list = snap.data ?? [];
                        if (list.isEmpty) {
                          return const Text('Aucun historique');
                        }
                        return Column(
                          children: list.map((item) {
                            final s = item as dynamic;
                            return ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  s.diseaseName.isNotEmpty
                                      ? s.diseaseName[0]
                                      : '?',
                                ),
                              ),
                              title: Text(s.diseaseName),
                              subtitle: Text(
                                'Analysée: ${s.scannedAt.toLocal()}',
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),

                // Fallback message when no scans (kept as visual hint)
                GradientCard(
                      isDarkMode: isDarkMode,
                      opacity: 0.1,
                      borderRadius: AppConstants.radiusLarge,
                      child: SizedBox(
                        height: 120,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 40,
                                color: isDarkMode
                                    ? AppColors.darkHint
                                    : AppColors.lightHint,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Aucun scan pour le moment',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isDarkMode
                                          ? AppColors.darkHint
                                          : AppColors.lightHint,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate(delay: const Duration(milliseconds: 400))
                    .fadeIn(duration: AppConstants.animationNormal),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
