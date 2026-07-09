import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:green_app/models/disease_catalog_model.dart';
import 'package:provider/provider.dart';
import '../../../providers/diseases_provider.dart';
import '../../../shared/widgets/app_pop_scope.dart';
import '../../../services/history_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../shared/widgets/animation_effects.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/custom_scroll_physics.dart';
import '../../../core/utils/disease_status.dart';

class DiseasesScreen extends StatefulWidget {
  const DiseasesScreen({super.key});

  @override
  State<DiseasesScreen> createState() => _DiseasesScreenState();
}

class _DiseasesScreenState extends State<DiseasesScreen> {
  late TextEditingController _searchController;
  List<DiseaseCatalogModel> _diseases = [];
  List<DiseaseCatalogModel> _filteredDiseases = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadDiseases();
  }

  Future<void> _loadDiseases() async {
    try {
      await context.read<DiseasesProvider>().load();
      final providerDiseases = context.read<DiseasesProvider>().diseases;
      final List<DiseaseCatalogModel> combined = List<DiseaseCatalogModel>.from(providerDiseases);

      // Add unique diseases from history (by name) — lightweight conversion
      try {
        final historyDiseases = await historyService.getUniqueDiseases();
        for (final d in historyDiseases) {
          final name = d['name'] ?? '';
          if (name.isEmpty) continue;
          if (!combined.any((e) => e.name.toLowerCase() == name.toLowerCase())) {
            combined.add(DiseaseCatalogModel(
              id: name.toLowerCase().replaceAll(' ', '-'),
              name: name,
              scientificName: d['scientificName'] ?? '',
              affectedPlants: (d['affectedPlants'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
              symptoms: [d['description'] ?? ''],
              actions: [d['treatment'] ?? ''],
              aliases: [],
            ));
          }
        }
      } catch (_) {}

      if (mounted) {
        setState(() {
          _diseases = combined;
          _filteredDiseases = _diseases;
        });
      }
    } catch (_) {}
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
                  disease.name.toLowerCase().contains(query.toLowerCase()) ||
                  disease.scientificName.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final t = context.watch<LocaleProvider>().t;

    return AppPopScope(
      onWillPop: () async {
        if (Navigator.canPop(context)) {
          return true;
        }
        context.go('/camera'); // Redirect to Camera (Scanner) as requested
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode
            ? AppColors.darkBackground
            : AppColors.lightBackground,
        appBar: AppBar(
          title: Text(t('diseasesTitle')),
          centerTitle: false,
          elevation: 0,
          backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/camera'),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: GestureDetector(
                  onTap: () => context.go('/profile'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDarkMode ? AppColors.darkChipNeutralBg : AppColors.lightChipNeutralBg,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
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
                        hintText: t('searchDiseaseHint'),
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
                              t('noDiseaseFound'),
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
    )
    );
  }

  Widget _buildDiseaseCard(
    BuildContext context,
    DiseaseCatalogModel disease,
    int index,
    bool isDarkMode,
  ) {
    final t = context.read<LocaleProvider>().t;
    final bool healthy = isHealthyDiseaseName(disease.name);
    final Color statusBg = healthy
        ? (isDarkMode ? AppColors.darkTertiary : AppColors.lightTertiary)
        : (isDarkMode ? AppColors.darkChipAmberBg : AppColors.lightChipAmberBg);
    final Color statusFg = healthy
        ? (isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary)
        : (isDarkMode ? AppColors.darkChipAmberText : AppColors.lightChipAmberText);
    final Color chipBg = healthy
        ? (isDarkMode ? AppColors.darkTertiary : AppColors.lightTertiary)
        : (isDarkMode ? AppColors.darkChipAmberBg : AppColors.lightChipAmberBg);
    final Color chipFg = healthy
        ? (isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary)
        : (isDarkMode ? AppColors.darkChipAmberText : AppColors.lightChipAmberText);
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
                        color: statusBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        healthy ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: statusFg,
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
                          disease.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          disease.scientificName,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: isDarkMode
                                    ? AppColors.darkHint
                                    : AppColors.lightHint,
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                '${t('affectedPlantsLabel')}:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: disease.affectedPlants
                    .map((p) => Chip(
                          label: Text(p, style: TextStyle(color: chipFg)),
                          backgroundColor: chipBg,
                          side: BorderSide.none,
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              Text(
                '${t('mainSymptomsLabel')}:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ...disease.symptoms.map((s) => Text('- $s', style: Theme.of(context).textTheme.bodySmall)),
              const SizedBox(height: 12),
              Text(
                '${t('recommendedActions')}:',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              ...disease.actions.map((a) => Text('- $a', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary, fontWeight: FontWeight.w500))),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: index * 50))
        .fadeSlideIn(delayMs: index * 50);
  }
}
