import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/weather_service.dart';
import '../../../services/history_service.dart';
import '../../../utils/date_formatter.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/custom_scroll_physics.dart';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<WeatherData> _weatherFuture;
  
  @override
  void initState() {
    super.initState();
    _weatherFuture = weatherService.fetchWeatherForCity('Douala');
  }

  Future<void> _enableLocation() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      if (mounted) {
        setState(() {
           _weatherFuture = _fetchWeatherWithLocation();
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission de localisation refusée')),
        );
      }
    }
  }

  Future<WeatherData> _fetchWeatherWithLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition();
      return await weatherService.fetchWeatherForCoordinates(pos.latitude, pos.longitude);
    } catch (e) {
      return weatherService.fetchWeatherForCity('Douala');
    }
  }
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
                // Welcome Banner + Profile Card in one row
                Row(
                  children: [
                    // Welcome Card (50% width)
                    Expanded(
                      child: Container(
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
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Bienvenue !',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Scannez vos plantes',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color.fromRGBO(255, 255, 255, 0.9),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.paddingMedium),
                    // Profile Card (50% width) - avec données utilisateur
                    Expanded(
                      child: Consumer<AuthProvider>(
                        builder: (context, auth, _) {
                          final user = auth.currentUser;
                          return GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusXLarge,
                                ),
                                border: Border.all(
                                  color: isDarkMode
                                      ? const Color.fromRGBO(66, 66, 66, 0.3)
                                      : const Color.fromRGBO(224, 224, 224, 0.5),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color.fromRGBO(0, 0, 0, 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(AppConstants.paddingMedium),
                              child: Row(
                                children: [
                                  // Profile Photo
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDarkMode
                                          ? const Color.fromRGBO(27, 94, 32, 0.2)
                                          : const Color.fromRGBO(232, 245, 233, 0.2),
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppConstants.paddingSmall),
                                  // Profile Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          user?.name ?? 'Mon Profil',
                                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                            color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          user?.phone ?? user?.email ?? 'Non renseigné',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
                    // Dynamic height allocation (removed fixed height)
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
                      future: _weatherFuture,
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const SizedBox(),
                              Text(
                                'Chargement...',
                                style: const TextStyle(
                                  color: Colors.white, // Always white
                                ),
                              ),
                              const SizedBox(),
                            ],
                          );
                        }
                        if (snap.hasError || snap.data == null) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(
                                Icons.error, 
                                color: Colors.white, // Always white
                              ),
                              const Text(
                                'Erreur météo',
                                style: TextStyle(
                                  color: Colors.white, // Always white
                                ),
                              ),
                              const SizedBox(),
                            ],
                          );
                        }
                        final w = snap.data!;
                        return Column(
                          children: [
                             // Header buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    onPressed: _enableLocation,
                                    icon: const Icon(Icons.location_on, color: Colors.white, size: 16),
                                    label: const Text(
                                      'Activer Localisation',
                                      style: TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/weather'),
                                    child: const Text('Voir plus', style: TextStyle(color: Colors.white, fontSize: 12)),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 30),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8), // Added spacing
                              Row(
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
                                    color: Colors.white, // Always white
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${w.temperature.toStringAsFixed(1)}°C',
                                    style: const TextStyle(
                                      color: Colors.white, // Always white
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
                                    color: Colors.white, // Always white
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    w.description,
                                    style: const TextStyle(
                                      color: Colors.white, // Always white
                                    ),
                                    textAlign: TextAlign.center,
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
                                  const Icon(
                                    Icons.air, 
                                    color: Colors.white, // Always white
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${w.windSpeed.toStringAsFixed(1)} m/s',
                                    style: const TextStyle(
                                      color: Colors.white, // Always white
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                                            color: Color.fromRGBO(255, 255, 255, 0.8),
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
                      future: historyService.getRecentScans(3),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Text('Chargement...');
                        }
                        final list = snap.data ?? [];
                        if (list.isEmpty) {
                          return GradientCard(
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
                          .fadeIn(duration: AppConstants.animationNormal);
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
                                'Analysée: ${formatDateFrench(s.scannedAt)}',
                              ),
                            );
                          }).toList(),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: AppConstants.paddingLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
