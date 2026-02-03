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
import '../../../shared/widgets/custom_app_bar.dart';


enum HistorySort { dateDesc, dateAsc, nameAsc, nameDesc }


class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // ... existing code ...
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
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              child: Text(
                                it.diseaseName.isNotEmpty ? it.diseaseName[0] : '?',
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            title: Text(
                              it.diseaseName,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Plantes: ${it.affectedPlants.join(", ")}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  'Analysée: ${formatDateFrench(it.scannedAt)} - Confiance ${(it.confidence * 100).toStringAsFixed(0)}%',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isDark ? AppColors.darkHint : AppColors.lightHint,
                                  ),
                                ),
                              ],
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
                : (isDark ? const Color.fromRGBO(66, 66, 66, 0.3) : const Color.fromRGBO(224, 224, 224, 0.5)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : (isDark ? AppColors.darkHint : AppColors.lightHint),
          ),
        ),
      ),
    );
  }

}
