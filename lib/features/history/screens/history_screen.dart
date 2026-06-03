import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/history_service.dart';
import '../../../models/scan_result_model.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/date_formatter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/app_pop_scope.dart';
import 'dart:io';

enum HistorySort { dateDesc, dateAsc, nameAsc, nameDesc }

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanResultModel> _items = [];
  HistorySort _sort = HistorySort.dateDesc;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await historyService.getAllScans();
    setState(() {
      _items = all;
      _applySort();
    });
  }

  void _applySort() {
    switch (_sort) {
      case HistorySort.dateDesc:
        _items.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
        break;
      case HistorySort.dateAsc:
        _items.sort((a, b) => a.scannedAt.compareTo(b.scannedAt));
        break;
      case HistorySort.nameAsc:
        _items.sort((a, b) => a.diseaseName.compareTo(b.diseaseName));
        break;
      case HistorySort.nameDesc:
        _items.sort((a, b) => b.diseaseName.compareTo(a.diseaseName));
        break;
    }
  }

  void _showScanDetails(ScanResultModel scan, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildScanDetailSheet(scan, isDark),
    );
  }

  Widget _buildScanDetailSheet(ScanResultModel scan, bool isDark) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec titre
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkHint : AppColors.lightHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Détails du scan',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),

              // Image si disponible
              if (scan.imageUrl.isNotEmpty && File(scan.imageUrl).existsSync())
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    image: DecorationImage(
                      image: FileImage(File(scan.imageUrl)),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 48,
                      color: isDark ? AppColors.darkHint : AppColors.lightHint,
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Maladie
              _buildDetailSection(
                context,
                'Maladie détectée',
                scan.diseaseName,
                isDark,
              ),
              const SizedBox(height: 16),

              // Plantes affectées
              _buildDetailSection(
                context,
                'Plantes affectées',
                scan.affectedPlants.isNotEmpty
                    ? scan.affectedPlants.join(', ')
                    : 'Non spécifiée',
                isDark,
              ),
              const SizedBox(height: 16),

              // Confiance
              _buildDetailSection(
                context,
                'Niveau de confiance',
                '${(scan.confidence * 100).toStringAsFixed(1)}%',
                isDark,
              ),
              const SizedBox(height: 16),

              // Date du scan
              _buildDetailSection(
                context,
                'Date du scan',
                formatDateFrench(scan.scannedAt),
                isDark,
              ),
              const SizedBox(height: 16),

              // Traitement/Recommandation
              _buildDetailSection(
                context,
                'Recommandations',
                scan.treatment,
                isDark,
              ),
              const SizedBox(height: 24),

              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Fermer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkHint
                            : AppColors.lightHint,
                        foregroundColor:
                            isDark ? Colors.black : Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await historyService.removeScan(scan.id);
                        setState(() {
                          _items.removeWhere((e) => e.id == scan.id);
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Supprimer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
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
  }

  Widget _buildDetailSection(
    BuildContext context,
    String label,
    String value,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: isDark ? AppColors.darkHint : AppColors.lightHint,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkBackground : AppColors.lightBackground,
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
            border: Border.all(
              color: isDark
                  ? const Color.fromRGBO(66, 66, 66, 0.3)
                  : const Color.fromRGBO(224, 224, 224, 0.5),
            ),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    return AppPopScope(
      onWillPop: () async {
        context.go('/camera');
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historique'),
          elevation: 0,
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            children: [
              // Tri avec boutons cliquables au lieu de dropdown
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text(
                      'Trier par : ',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    _sortButton(
                      context,
                      'Date ↓',
                      _sort == HistorySort.dateDesc,
                      () => _updateSort(HistorySort.dateDesc),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _sortButton(
                      context,
                      'Date ↑',
                      _sort == HistorySort.dateAsc,
                      () => _updateSort(HistorySort.dateAsc),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _sortButton(
                      context,
                      'Nom A-Z',
                      _sort == HistorySort.nameAsc,
                      () => _updateSort(HistorySort.nameAsc),
                      isDark,
                    ),
                    const SizedBox(width: 6),
                    _sortButton(
                      context,
                      'Nom Z-A',
                      _sort == HistorySort.nameDesc,
                      () => _updateSort(HistorySort.nameDesc),
                      isDark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun scan pour le moment',
                          style: TextStyle(
                            color: isDark ? AppColors.darkHint : AppColors.lightHint,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, index) {
                          final it = _items[index];
                          return GestureDetector(
                            onTap: () => _showScanDetails(it, isDark),
                            child: Card(
                              elevation: 0,
                              color: isDark
                                  ? AppColors.darkSurface
                                  : AppColors.lightSurface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppConstants.radiusMedium,
                                ),
                                side: BorderSide(
                                  color: isDark
                                      ? const Color.fromRGBO(66, 66, 66, 0.3)
                                      : const Color.fromRGBO(224, 224, 224, 0.5),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  AppConstants.paddingMedium,
                                ),
                                child: Row(
                                  children: [
                                    // Image thumbnail
                                    if (it.imageUrl.isNotEmpty &&
                                        File(it.imageUrl).existsSync())
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            AppConstants.radiusSmall,
                                          ),
                                          image: DecorationImage(
                                            image:
                                                FileImage(File(it.imageUrl)),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 60,
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            AppConstants.radiusSmall,
                                          ),
                                          color: isDark
                                              ? AppColors.darkBackground
                                              : AppColors.lightBackground,
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 24,
                                            color: isDark
                                                ? AppColors.darkHint
                                                : AppColors.lightHint,
                                          ),
                                        ),
                                      ),
                                    const SizedBox(
                                      width: AppConstants.paddingMedium,
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            it.diseaseName,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Plantes: ${it.affectedPlants.join(", ")}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${formatDateFrench(it.scannedAt)} • ${(it.confidence * 100).toStringAsFixed(0)}%',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                              color: isDark
                                                  ? AppColors.darkHint
                                                  : AppColors.lightHint,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: isDark
                                          ? AppColors.darkHint
                                          : AppColors.lightHint,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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

  void _updateSort(HistorySort sort) {
    setState(() {
      _sort = sort;
      _applySort();
    });
  }

  Widget _sortButton(
    BuildContext context,
    String label,
    bool isActive,
    VoidCallback onTap,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark
                    ? const Color.fromRGBO(66, 66, 66, 0.3)
                    : const Color.fromRGBO(224, 224, 224, 0.5)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive
                ? Colors.white
                : (isDark ? AppColors.darkHint : AppColors.lightHint),
          ),
        ),
      ),
    );
  }
}
