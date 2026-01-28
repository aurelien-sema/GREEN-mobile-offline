import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/history_service.dart';
import '../../../models/scan_result_model.dart';

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Historique')),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            Row(
              children: [
                const Text('Trier par : '),
                const SizedBox(width: 8),
                DropdownButton<HistorySort>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(
                      value: HistorySort.dateDesc,
                      child: Text('Date (desc)'),
                    ),
                    DropdownMenuItem(
                      value: HistorySort.dateAsc,
                      child: Text('Date (asc)'),
                    ),
                    DropdownMenuItem(
                      value: HistorySort.nameAsc,
                      child: Text('Nom (A-Z)'),
                    ),
                    DropdownMenuItem(
                      value: HistorySort.nameDesc,
                      child: Text('Nom (Z-A)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() {
                      _sort = v;
                      _applySort();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _items.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun historique pour le moment',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkHint
                              : AppColors.lightHint,
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
                            child: Text(
                              it.diseaseName.isNotEmpty
                                  ? it.diseaseName[0]
                                  : '?',
                            ),
                          ),
                          title: Text(it.diseaseName),
                          subtitle: Text(
                            'Analysée le ${it.scannedAt.toLocal()} - Confiance ${(it.confidence * 100).toStringAsFixed(1)}%',
                          ),
                          trailing: Text('${it.affectedPlants.length} plantes'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
