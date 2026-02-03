import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../models/scan_result_model.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/theme_provider.dart';
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

  String _severityLabel(double confidence) {
    if (confidence >= 0.9) return 'Très élevé';
    if (confidence >= 0.75) return 'Élevé';
    if (confidence >= 0.5) return 'Modéré';
    if (confidence >= 0.35) return 'Faible';
    return 'Suspicion faible';
  }

  Color _severityColor(double confidence) {
    if (confidence >= 0.9) return Colors.red.shade700;
    if (confidence >= 0.75) return Colors.orange.shade700;
    if (confidence >= 0.5) return Colors.amber.shade700;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final diseasesProv = context.read<DiseasesProvider>();
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final isHealthy = _isHealthy();

    return FutureBuilder(
      future: diseasesProv.load(),
      builder: (context, snapshot) {
        final DiseaseCatalogModel? diseaseInfo = diseasesProv.findByName(widget.scanResult.diseaseName);

        final screenW = MediaQuery.of(context).size.width;
        final imageSize = (screenW * 0.34).clamp(80.0, 160.0);
        final plantName = widget.scanResult.affectedPlants.isNotEmpty
            ? widget.scanResult.affectedPlants.first
            : 'Plante inconnue';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Fiche terrain'),
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
                              const Text(
                                'Niveau de gravité',
                                style: TextStyle(
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
                                        value: widget.scanResult.confidence,
                                        minHeight: 12,
                                        backgroundColor: isDarkMode
                                            ? const Color.fromRGBO(
                                                66, 66, 66, 0.3)
                                            : const Color.fromRGBO(
                                                224, 224, 224, 0.5),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          _severityColor(
                                              widget.scanResult.confidence),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _severityLabel(
                                          widget.scanResult.confidence),
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
                                'Confiance:\n${(widget.scanResult.confidence * 100).round()}%',
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
                                'Plante saine',
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
                    'Plante',
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
                      'Maladie détectée',
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
                      'Symptômes',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (diseaseInfo != null && diseaseInfo.symptoms.isNotEmpty)
                      ...diseaseInfo.symptoms
                          .map((s) => _bulletItem(context, s))
                    else
                      Text(
                        'Informations insuffisantes sur les symptômes pour cette maladie.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    const SizedBox(height: AppConstants.paddingLarge),

                    // Actions recommandées
                    Text(
                      'Actions recommandées',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    if (diseaseInfo != null && diseaseInfo.actions.isNotEmpty)
                      ...diseaseInfo.actions.map((a) => _bulletItem(context, a))
                    else
                      Text(
                        'Aucune recommandation locale disponible. Consultez Green Bot pour des conseils pratiques.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                  ] else ...[
                    Text(
                      'Aucun traitement nécessaire',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Colors.green),
                    ),
                    const SizedBox(height: AppConstants.paddingLarge),
                    Text(
                      'Conseil préventif',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    _bulletItem(
                        context,
                        'Continuez à observer régulièrement votre plante'),
                    _bulletItem(context,
                        'Maintenez une bonne hygiène du jardin'),
                    _bulletItem(context,
                        'Assurez un arrosage régulier et adapté'),
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
                          label: const Text('Compris'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (!isHealthy)
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final prompt =
                                  "J'ai détecté une ${widget.scanResult.diseaseName} sur ma ${plantName}. Donne-moi des conseils pratiques et simples pour la traiter avec les ressources disponibles au village.";
                              Navigator.pop(context);
                              Future.microtask(() => context.go('/chat',
                                  extra: {
                                    'initialMessage': prompt,
                                    'autoSend': true
                                  }));
                            },
                            icon: const Icon(Icons.chat_bubble),
                            label: const Text('Green Bot'),
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
