import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../models/scan_result_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/green_web/photo_sync_service.dart';
import '../../../services/history_service.dart';
import '../../../shared/ui/ui.dart';
import '../../../utils/date_formatter.dart';
import '../scan_labels.dart';

enum _Filter { all, diseased, healthy, uncertain }

/// Historique des analyses.
///
/// Corrections v2 : liste défilable dans tout l'écran (la v1 imbriquait une
/// liste dans une colonne avec rembourrage fixe), regroupement par jour,
/// recherche, filtres par statut et par culture, suppression par glissement
/// avec annulation, photos permanentes, retour système cohérent.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  List<ScanResultModel> _all = const [];
  bool _loading = true;
  _Filter _filter = _Filter.all;
  String? _crop;
  bool _newestFirst = true;
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _load();
    _sub = historyService.onChanged.listen((_) => _load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await historyService.getAllScans();
    if (!mounted) return;
    setState(() {
      _all = items;
      _loading = false;
    });
  }

  List<ScanResultModel> _visible(DiseasesProvider catalog, String locale, String Function(String) t) {
    final q = DiseasesProvider.normalize(_searchCtrl.text);
    final list = _all.where((s) {
      final okFilter = switch (_filter) {
        _Filter.all => true,
        _Filter.diseased => s.isDiseased,
        _Filter.healthy => s.isHealthy,
        _Filter.uncertain => s.isUncertain || s.isError,
      };
      if (!okFilter) return false;
      if (_crop != null) {
        final crop = s.cropId ?? ScanLabels.entry(s, catalog)?.crops.firstOrNull;
        if (crop != _crop) return false;
      }
      if (q.isEmpty) return true;
      final text = DiseasesProvider.normalize(
        '${ScanLabels.title(s, catalog, locale, t)} ${ScanLabels.plant(s, catalog, locale, t)}',
      );
      return q.split(' ').every(text.contains);
    }).toList();
    list.sort((a, b) => _newestFirst ? b.scannedAt.compareTo(a.scannedAt) : a.scannedAt.compareTo(b.scannedAt));
    return list;
  }

  Future<void> _remove(ScanResultModel scan) async {
    final t = context.read<LocaleProvider>().t;
    final messenger = ScaffoldMessenger.of(context);
    // Retrait immédiat de la liste affichée : Dismissible exige que l'élément
    // glissé disparaisse dans la même image.
    setState(() => _all = _all.where((s) => s.id != scan.id).toList());
    final removed = await historyService.removeScan(scan.id);
    if (removed == null) return;
    var undone = false;
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(SnackBar(
      content: Text(t('scanDeleted')),
      action: SnackBarAction(
        label: t('undo'),
        onPressed: () {
          undone = true;
          historyService.restoreScan(removed);
        },
      ),
    ));
    await controller.closed;
    if (undone) return;
    await historyService.purgeFiles(removed);
    if (mounted) await context.read<PhotoSyncService>().cancel(removed.id);
  }

  Future<void> _clearAll() async {
    final t = context.read<LocaleProvider>().t;
    final ok = await showConfirmDialog(
      context,
      title: t('clearHistoryTitle'),
      message: t('clearHistoryMessage'),
      confirmLabel: t('deleteAll'),
      cancelLabel: t('cancel'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    final sync = context.read<PhotoSyncService>();
    final uid = context.read<AuthProvider>().currentUser?.id;
    await historyService.clearAll();
    if (uid != null) await sync.forget(uid);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final catalog = context.watch<DiseasesProvider>();
    final items = _visible(catalog, l.locale, t);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('history')),
        actions: [
          IconButton(
            tooltip: t(_newestFirst ? 'sortDateDesc' : 'sortDateAsc'),
            onPressed: () => setState(() => _newestFirst = !_newestFirst),
            icon: Icon(_newestFirst ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded),
          ),
          PopupMenuButton<String>(
            enabled: _all.isNotEmpty,
            onSelected: (v) {
              if (v == 'clear') _clearAll();
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'clear', child: Text(t('clearHistoryTitle'))),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _all.isEmpty
              ? EmptyState(
                  icon: Icons.history_rounded,
                  title: t('noScansYet'),
                  message: t('noScansYetHint'),
                  action: FilledButton.icon(
                    onPressed: () => context.go('/camera'),
                    icon: const Icon(Icons.center_focus_strong_rounded),
                    label: Text(t('scanAPlant')),
                  ),
                )
              : CustomScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(child: _filters(catalog, l)),
                    if (items.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(icon: Icons.search_off_rounded, title: t('noResults')),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(Spacing.gutter, 0, Spacing.gutter, Spacing.xxxl),
                        sliver: SliverList.builder(
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final scan = items[i];
                            final header = dayGroupLabel(scan.scannedAt, l.locale, t);
                            final showHeader = i == 0 || dayGroupLabel(items[i - 1].scannedAt, l.locale, t) != header;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (showHeader) GroupLabel(header),
                                _HistoryTile(
                                  scan: scan,
                                  catalog: catalog,
                                  locale: l.locale,
                                  t: t,
                                  onDelete: () => _remove(scan),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
      ),
    );
  }

  Widget _filters(DiseasesProvider catalog, LocaleProvider l) {
    final t = l.t;
    final counts = {
      _Filter.all: _all.length,
      _Filter.diseased: _all.where((s) => s.isDiseased).length,
      _Filter.healthy: _all.where((s) => s.isHealthy).length,
      _Filter.uncertain: _all.where((s) => s.isUncertain || s.isError).length,
    };
    final labels = {
      _Filter.all: t('filterAll'),
      _Filter.diseased: t('filterDiseased'),
      _Filter.healthy: t('filterHealthy'),
      _Filter.uncertain: t('filterUncertain'),
    };
    const crops = ['maize', 'cassava', 'tomato'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(Spacing.gutter, Spacing.md, Spacing.gutter, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchCtrl,
            textInputAction: TextInputAction.search,
            keyboardType: TextInputType.text,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t('searchHistory'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: t('clear'),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => setState(_searchCtrl.clear),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final f in _Filter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text('${labels[f]} (${counts[f]})'),
                      selected: _filter == f,
                      onSelected: (_) => setState(() => _filter = f),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final c in crops)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(catalog.cropName(c, l.locale)),
                      selected: _crop == c,
                      onSelected: (v) => setState(() => _crop = v ? c : null),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final ScanResultModel scan;
  final DiseasesProvider catalog;
  final String locale;
  final String Function(String) t;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.scan,
    required this.catalog,
    required this.locale,
    required this.t,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = scanStatusStyle(scan.status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: ValueKey(scan.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(14)),
          child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onErrorContainer),
        ),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push('/scan/${scan.id}'),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Hero(
                    tag: 'scan-${scan.id}',
                    child: LocalImage(path: scan.thumbPath ?? scan.imagePath, width: 64, height: 64, cacheWidth: 192),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ScanLabels.title(scan, catalog, locale, t),
                          style: theme.textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${ScanLabels.plant(scan, catalog, locale, t)} · ${formatTime(scan.scannedAt)} · ${(scan.confidence * 100).round()} %',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Icon(style.icon, color: style.color),
                      if (scan.sync.status == SyncStatus.sent) ...[
                        const SizedBox(height: 6),
                        Icon(Icons.cloud_done_rounded, size: 16, color: theme.colorScheme.onSurfaceVariant),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
