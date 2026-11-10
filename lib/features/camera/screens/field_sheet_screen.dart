import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../models/disease_catalog_model.dart';
import '../../../models/scan_result_model.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../services/green_web/photo_sync_service.dart';
import '../../../services/history_service.dart';
import '../../../shared/ui/ui.dart';
import '../../../utils/date_formatter.dart';
import '../../history/scan_labels.dart';

/// Fiche terrain d'une analyse (hors ligne).
///
/// Corrections v2 :
/// - la gravité vient de la fiche de la maladie, et non plus de la confiance
///   du modèle (une plante saine reconnue à 95 % s'affichait « gravité très
///   élevée ») ; la confiance est montrée à part ;
/// - la fiche est rattachée par correspondance exacte de classe, et non par
///   ressemblance de nom (« Mildiou » de la tomate pouvait ouvrir celle du maïs) ;
/// - résultat incertain : les trois possibilités sont présentées, avec le
///   conseil de reprendre la photo ;
/// - photo permanente, page entièrement défilable, retour cohérent.
class FieldSheetScreen extends StatefulWidget {
  final String scanId;
  const FieldSheetScreen({super.key, required this.scanId});

  @override
  State<FieldSheetScreen> createState() => _FieldSheetScreenState();
}

class _FieldSheetScreenState extends State<FieldSheetScreen> {
  late Future<ScanResultModel?> _future = historyService.findById(widget.scanId);
  StreamSubscription<void>? _changes;

  @override
  void initState() {
    super.initState();
    // L'état d'envoi (GREEN Web) peut changer pendant que la fiche est ouverte.
    _changes = historyService.onChanged.listen((_) {
      if (mounted) setState(() => _future = historyService.findById(widget.scanId));
    });
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _delete(ScanResultModel scan) async {
    final t = context.read<LocaleProvider>().t;
    final ok = await showConfirmDialog(
      context,
      title: t('deleteScanTitle'),
      message: t('deleteScanMessage'),
      confirmLabel: t('delete'),
      cancelLabel: t('cancel'),
      destructive: true,
    );
    if (!ok || !mounted) return;
    final sync = context.read<PhotoSyncService>();
    final removed = await historyService.removeScan(scan.id);
    if (removed != null) {
      await historyService.purgeFiles(removed);
      await sync.cancel(removed.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('scanDeleted'))));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _askBot(ScanResultModel scan, String plant, String disease) {
    final l = context.read<LocaleProvider>();
    final prompt = scan.isUncertain
        ? l.tf('chatPromptUncertain', {'plant': plant})
        : l.tf('chatPromptTemplate', {'disease': disease, 'plant': plant});
    context.go('/chat', extra: {
      'initialMessage': prompt,
      'cacheKey': scan.isUncertain ? null : (scan.diseaseId ?? scan.label),
      'autoSend': true,
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final catalog = context.watch<DiseasesProvider>();

    return FutureBuilder<ScanResultModel?>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final scan = snap.data;
        if (scan == null) {
          return Scaffold(
            appBar: AppBar(title: Text(t('fieldSheet'))),
            body: EmptyState(icon: Icons.search_off_rounded, title: t('scanNotFound')),
          );
        }
        final entry = ScanLabels.entry(scan, catalog);
        final plant = ScanLabels.plant(scan, catalog, l.locale, t);
        final title = ScanLabels.title(scan, catalog, l.locale, t);
        return _buildSheet(context, l, catalog, scan, entry, plant, title);
      },
    );
  }

  Widget _buildSheet(
    BuildContext context,
    LocaleProvider l,
    DiseasesProvider catalog,
    ScanResultModel scan,
    DiseaseCatalogModel? entry,
    String plant,
    String title,
  ) {
    final t = l.t;
    final loc = l.locale;
    final theme = Theme.of(context);
    final style = scanStatusStyle(scan.status);
    final healthyAdvice = scan.isHealthy
        ? (entry ?? catalog.diseases.where((d) => d.isHealthy && d.crops.contains(scan.cropId)).firstOrNull)
        : null;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            title: Text(t('fieldSheet')),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'delete') _delete(scan);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: Text(t('delete')),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: 'scan-${scan.id}',
                child: LocalImage(path: scan.imagePath, borderRadius: BorderRadius.zero, cacheWidth: 1080),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Spacing.gutter, Spacing.xl, Spacing.gutter, 40),
            sliver: SliverList.list(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusPill(label: ScanLabels.status(scan, t), color: style.color, icon: style.icon),
                    if (scan.isDiseased && entry != null)
                      StatusPill(
                        label: '${t('severityLabel')} : ${ScanLabels.severity(entry.severity, t)}',
                        color: severityColor(entry.severity),
                      ),
                    _SyncPill(sync: scan.sync, t: t),
                  ],
                ),
                Spacing.gapBlock,
                Text(title, style: theme.textTheme.headlineSmall),
                if (scan.isDiseased && entry != null && entry.scientificName.isNotEmpty)
                  Text(entry.scientificName, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text(
                  '$plant · ${formatDateTime(scan.scannedAt, loc)}',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                SectionCard(
                  child: ConfidenceBar(value: scan.confidence, label: t('confidenceLabel')),
                ),
                if (scan.sync.serverDiagnosis != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.cloud_done_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l.tf('serverDiagnosis', {
                            'name': scan.sync.serverDiagnosis!,
                            'pct': scan.sync.serverConfidence == null ? '–' : (scan.sync.serverConfidence! * 100).round(),
                          }),
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
                Spacing.gapBlock,
                if (scan.isUncertain) ..._uncertain(context, scan, catalog, l),
                if (scan.isDiseased && entry != null) ..._disease(entry, loc, t),
                if (scan.isDiseased && entry == null)
                  SectionCard(child: Text(t('noLocalRecommendation'))),
                if (scan.isHealthy) ..._healthy(healthyAdvice, loc, t),
                const SizedBox(height: 4),
                _Disclaimer(text: t('diagnosisDisclaimer')),
                const SizedBox(height: 20),
                if (!scan.isHealthy)
                  FilledButton.icon(
                    onPressed: () => _askBot(scan, plant, title),
                    icon: const Icon(Icons.chat_bubble_rounded),
                    label: Text(t('askGreenBot')),
                  ),
                Spacing.gapBlock,
                OutlinedButton.icon(
                  onPressed: () => context.go('/camera'),
                  icon: const Icon(Icons.center_focus_strong_rounded),
                  label: Text(t('newScan')),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  List<Widget> _uncertain(BuildContext context, ScanResultModel scan, DiseasesProvider catalog, LocaleProvider l) {
    final t = l.t;
    return [
      SectionCard(
        title: t('modelHesitates'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in scan.topPredictions)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: ConfidenceBar(value: p.confidence, label: ScanLabels.labelName(p.label, catalog, l.locale)),
              ),
            const SizedBox(height: 8),
            Text(t('uncertainAdvice')),
          ],
        ),
      ),
      Spacing.gapBlock,
      SectionCard(
        title: t('goodPhotoTips'),
        child: BulletList(
          icon: Icons.check_rounded,
          items: [t('instructionStep1'), t('instructionStep2'), t('instructionStep3')],
        ),
      ),
      Spacing.gapBlock,
    ];
  }

  List<Widget> _disease(DiseaseCatalogModel e, String loc, String Function(String) t) {
    Widget section(String title, List<String> items, IconData icon, {Color? color}) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SectionCard(title: title, child: BulletList(items: items, icon: icon, color: color)),
        );
    final out = <Widget>[];
    final actions = e.actions.of(loc);
    if (actions.isNotEmpty) out.add(section(t('whatToDoNow'), actions, Icons.task_alt_rounded));
    final symptoms = e.symptoms.of(loc);
    if (symptoms.isNotEmpty) out.add(section(t('symptoms'), symptoms, Icons.visibility_outlined));
    final cause = e.causes.of(loc);
    if (cause.isNotEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionCard(title: t('cause'), child: Text(cause)),
      ));
    }
    final conditions = e.conditions.of(loc);
    if (conditions.isNotEmpty) out.add(section(t('favorableConditions'), conditions, Icons.thermostat_rounded));
    final prevention = e.prevention.of(loc);
    if (prevention.isNotEmpty) out.add(section(t('prevention'), prevention, Icons.shield_outlined));
    final look = e.lookalikes.of(loc);
    if (look.isNotEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionCard(title: t('lookalikes'), child: Text(look)),
      ));
    }
    final help = e.whenToSeekHelp.of(loc);
    if (help.isNotEmpty) {
      out.add(Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionCard(title: t('whenToSeekHelp'), child: Text(help)),
      ));
    }
    return out;
  }

  List<Widget> _healthy(DiseaseCatalogModel? e, String loc, String Function(String) t) {
    final items = e?.prevention.of(loc) ?? const <String>[];
    return [
      SectionCard(
        title: t('preventiveAdvice'),
        child: BulletList(
          icon: Icons.eco_outlined,
          items: items.isNotEmpty ? items : [t('keepObservingPlant'), t('maintainGardenHygiene'), t('ensureRegularWatering')],
        ),
      ),
      Spacing.gapBlock,
    ];
  }
}

class _SyncPill extends StatelessWidget {
  final SyncState sync;
  final String Function(String) t;
  const _SyncPill({required this.sync, required this.t});

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (sync.status) {
      SyncStatus.sent => (t('syncSent'), Colors.teal, Icons.cloud_done_rounded),
      SyncStatus.pending => (t('syncPending'), Colors.blueGrey, Icons.cloud_upload_outlined),
      SyncStatus.failed => (t('syncFailed'), Colors.deepOrange, Icons.cloud_off_rounded),
      SyncStatus.local => (t('syncLocal'), Colors.grey, Icons.phone_android_rounded),
    };
    return StatusPill(label: label, color: color, icon: icon);
  }
}

class _Disclaimer extends StatelessWidget {
  final String text;
  const _Disclaimer({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
