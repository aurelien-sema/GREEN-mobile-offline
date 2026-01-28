import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/animation_effects.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/custom_scroll_physics.dart';

class DiseasesScreen extends StatefulWidget {
  const DiseasesScreen({super.key});

  @override
  State<DiseasesScreen> createState() => _DiseasesScreenState();
}

class _DiseasesScreenState extends State<DiseasesScreen> {
  late TextEditingController _searchController;
  final List<Map<String, String>> _diseases = [
    {
      'name': 'Oïdium',
      'scientificName': 'Powdery Mildew',
      'description': 'Revêtement blanc sur les feuilles',
      'treatment': 'Soufre ou fongicide approprié',
    },
    {
      'name': 'Mildiou',
      'scientificName': 'Late Blight',
      'description': 'Taches brunes sur les feuilles',
      'treatment': 'Cuivre ou fongicide de synthèse',
    },
    {
      'name': 'Rouille',
      'scientificName': 'Rust',
      'description': 'Pustules oranges sur les feuilles',
      'treatment': 'Soufre ou fongicide cuivre',
    },
    {
      'name': 'Anthracnose',
      'scientificName': 'Anthracnose',
      'description': 'Taches nécrotiques circulaires',
      'treatment': 'Fongicide de contact',
    },
    {
      'name': 'Carie blanche',
      'scientificName': 'White Rot',
      'description': 'Pourriture blanche du collet',
      'treatment': 'Réduction de l\'humidité',
    },
  ];

  List<Map<String, String>> _filteredDiseases = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredDiseases = _diseases;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDiseases(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredDiseases = _diseases;
      } else {
        _filteredDiseases = _diseases
            .where(
              (disease) =>
                  disease['name']!.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  disease['scientificName']!.toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    context.read<ThemeProvider>();

    return Scaffold(
      backgroundColor: isDarkMode
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      appBar: CustomAppBar(
        title: 'Maladies des plantes',
        isDarkMode: isDarkMode,
      ),
      body: GradientBackground(
        isDarkMode: isDarkMode,
        opacity: 0.1,
        child: SafeArea(
          child: Column(
            children: [
              // Search Bar
              Padding(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterDiseases,
                      decoration: InputDecoration(
                        hintText: 'Rechercher une maladie...',
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                        filled: true,
                        fillColor: isDarkMode
                            ? const Color.fromRGBO(27, 94, 32, 0.3)
                            : const Color.fromRGBO(232, 245, 233, 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.radiusMedium,
                          ),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: AppConstants.animationNormal)
                  .slideY(begin: -10, end: 0),

              // Diseases List
              Expanded(
                child: _filteredDiseases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 80,
                              color: isDarkMode
                                  ? AppColors.darkHint
                                  : AppColors.lightHint,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune maladie trouvée',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const SmoothScrollPhysics(),
                        padding: const EdgeInsets.all(
                          AppConstants.paddingMedium,
                        ),
                        itemCount: _filteredDiseases.length,
                        itemBuilder: (context, index) {
                          final disease = _filteredDiseases[index];
                          return _buildDiseaseCard(
                            context,
                            disease,
                            index,
                            isDarkMode,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiseaseCard(
    BuildContext context,
    Map<String, String> disease,
    int index,
    bool isDarkMode,
  ) {
    return GradientCard(
          isDarkMode: isDarkMode,
          opacity: 0.12,
          borderRadius: AppConstants.radiusLarge,
          margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  PulseAnimation(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: isDarkMode
                            ? AppColors.darkGradient
                            : AppColors.lightGradient,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disease['name']!,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          disease['scientificName']!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isDarkMode
                                    ? AppColors.darkHint
                                    : AppColors.lightHint,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                'Description:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                disease['description']!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(
                'Traitement:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                disease['treatment']!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDarkMode
                      ? AppColors.darkPrimary
                      : AppColors.lightPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeSlideIn(delayMs: index * 50);
  }
}
