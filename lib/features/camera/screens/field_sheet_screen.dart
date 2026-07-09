import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/scan_result_model.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../models/disease_catalog_model.dart';
import '../../../core/constants/app_constants.dart';

class FieldSheetScreen extends StatefulWidget {
  final ScanResultModel scanResult;
  const FieldSheetScreen({required this.scanResult, super.key});

  @override
  State<FieldSheetScreen> createState() => _FieldSheetScreenState();
}

class _FieldSheetScreenState extends State<FieldSheetScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  bool _isHealthy() {
    return widget.scanResult.diseaseName.toLowerCase() == 'saine' ||
        widget.scanResult.diseaseName.toLowerCase() == 'healthy' ||
        widget.scanResult.diseaseId == 'healthy';
  }

  String _severityLabel(double severityLevel, String Function(String) t) {
    if (severityLevel >= 90) return t('severityVeryHigh');
    if (severityLevel >= 75) return t('severityHigh');
    if (severityLevel >= 50) return t('severityModerate');
    if (severityLevel >= 25) return t('severityLow');
    return t('severityLowSuspicion');
  }

  Color _severityColor(double severityLevel) {
    if (severityLevel >= 90) return Colors.red.shade700;
    if (severityLevel >= 75) return Colors.orange.shade700;
    if (severityLevel >= 50) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final diseasesProv = context.read<DiseasesProvider>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final t = context.watch<LocaleProvider>().t;
    final isHealthy = _isHealthy();

    return FutureBuilder(
      future: diseasesProv.load(),
      builder: (context, snapshot) {
        final DiseaseCatalogModel? diseaseInfo = diseasesProv.findByName(widget.scanResult.diseaseName);

        final screenW = MediaQuery.of(context).size.width;
        final imageSize = (screenW * 0.34).clamp(80.0, 160.0);
        final plantName = widget.scanResult.affectedPlants.isNotEmpty
            ? widget.scanResult.affectedPlants.first
            : t('unknownPlant');

        return Scaffold(
          appBar: AppBar(
            title: Text(t('fieldSheet')),
            centerTitle: false,
            elevation: 0,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image et gravité (en haut)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image à gauche
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                        child: Image.file(
                          File(widget.scanResult.imageUrl),
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      // Gravité à droite (sauf si plante saine)
                      if (!isHealthy)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t('severityLevel'),
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              // Barre de progression animée
                              ScaleTransition(
                                scale: Tween<double>(begin: 0.0, end: 1.0)
                                    .animate(CurvedAnimation(
                                  parent: _animationController,
                                  curve: Curves.easeOut,
                                )),
                                alignment: Alignment.centerLeft,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: widget.scanResult.severityLevel / 100,
                                        minHeight: 12,
                                        backgroundColor: isDarkMode
                                            ? const Color.fromRGBO(
                                                66, 66, 66, 0.3)
                                            : const Color.fromRGBO(
                                                224, 224, 224, 0.5),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _severityColor(
                                              widget.scanResult.severityLevel),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _severityLabel(
                                          widget.scanResult.severityLevel, t),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${t('confidenceLabel')}:\n${(widget.scanResult.confidence * 100).round()}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      else
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 48),
                              const SizedBox(height: 12),
                              Text(
                                t('healthyPlant'),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Nom de la plante
                  Text(
                    t('plantLabel'),
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plantName,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),

                  // Nom de la maladie (sauf si plante saine)
                  if (!isHealthy) ...[
                    Text(
                      t('detectedDisease'),
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.scanResult.diseaseName,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),

                    // Symptômes
                    Text(
                      t('symptoms'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (diseaseInfo != null && diseaseInfo.symptoms.isNotEmpty)
                      ...diseaseInfo.symptoms
                          .map((s) => _bulletItem(context, s))
                    else
                      Text(
                        t('insufficientSymptomsInfo'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: AppConstants.paddingLarge),

                    // Actions recommandées
                    Text(
                      t('recommendedActions'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (diseaseInfo != null && diseaseInfo.actions.isNotEmpty)
                      ...diseaseInfo.actions.map((a) => _bulletItem(context, a))
                    else
                      Text(
                        t('noLocalRecommendation'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ] else ...[
                    Text(
                      t('noTreatmentNeeded'),
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.green),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    Text(
                      t('preventiveAdvice'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    _bulletItem(context, t('keepObservingPlant')),
                    _bulletItem(context, t('maintainGardenHygiene')),
                    _bulletItem(context, t('ensureRegularWatering')),
                  ],
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Boutons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_circle),
                          label: Text(t('understood')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!isHealthy)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final prompt = t('chatPromptTemplate')
                                  .replaceAll('{disease}', widget.scanResult.diseaseName)
                                  .replaceAll('{plant}', plantName);
                              Navigator.pop(context);
                              Future.microtask(() => context.go('/chat',
                                  extra: {
                                    'initialMessage': prompt,
                                    'autoSend': true
                                  }));
                            },
                            icon: const Icon(Icons.chat_bubble),
                            label: Text(t('greenBot')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bulletItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 6),
          Container(width: 6, height: 6, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
