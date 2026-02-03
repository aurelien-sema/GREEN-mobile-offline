import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/weather_service.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/app_pop_scope.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Future<WeatherData>? _weatherFuture;
  
  // Hardcoded city for now, or could pass as argument. 
  // Ideally this screen receives coords or city.
  // For now let's use the same default as home or fetch dynamically if we had global state.
  final String _city = 'Douala';

  @override
  void initState() {
    super.initState();
    // Load immediately if possible, or wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_weatherFuture == null) {
      _loadWeather();
    }
  }

  void _loadWeather() {
    final locale = context.read<LocaleProvider>().locale;
    setState(() {
      _weatherFuture = weatherService.fetchWeatherForCity(_city, lang: locale);
    });
  }

  void _refresh() {
    _loadWeather();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    return AppPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) return true;
        context.go('/home');
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Météo détaillée'),
          elevation: 0,
          backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
            ),
          ],
        ),
        body: GradientBackground(
          isDarkMode: isDarkMode,
          opacity: 0.1,
          child: SafeArea(
            child: FutureBuilder<WeatherData>(
              future: _weatherFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                }
                
                final w = snapshot.data!;
                
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: Column(
                    children: [
                      // Main Card
                      GradientCard(
                        isDarkMode: isDarkMode,
                        opacity: 0.2,
                        borderRadius: AppConstants.radiusXLarge,
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Text(
                              _city,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Icon(
                              Icons.wb_sunny, 
                              size: 80,
                              color: isDarkMode ? Colors.white : AppColors.lightPrimary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${w.temperature.toStringAsFixed(1)}°C',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                              ),
                            ),
                            Text(
                              w.description,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 20, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Grid details
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildDetailCard(
                            context, 
                            'Humidité', 
                            '${w.humidity}%', 
                            Icons.water_drop, 
                            isDarkMode
                          ),
                          _buildDetailCard(
                            context, 
                            'Vent', 
                            '${w.windSpeed} m/s', 
                            Icons.air, 
                            isDarkMode
                          ),
                          _buildDetailCard(
                            context, 
                            'Pression', 
                            '1012 hPa', // Mocked as not in WeatherData yet
                            Icons.speed, 
                            isDarkMode
                          ),
                          _buildDetailCard(
                            context, 
                            'Visibilité', 
                            '10 km', // Mocked
                            Icons.visibility, 
                            isDarkMode
                          ),
                        ],
                      ).animate(delay: 200.ms).fadeIn().slideY(begin: 20, end: 0),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard(BuildContext context, String label, String value, IconData icon, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDarkMode ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
            ),
          ),
        ],
      ),
    );
  }
}
