import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../models/disease_catalog_model.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../shared/ui/ui.dart';
import '../../history/scan_labels.dart';

/// Base des maladies, ravageurs et carences, consultable hors ligne.
class DiseasesScreen extends StatefulWidget {
  const DiseasesScreen({super.key});

  @override
  State<DiseasesScreen> createState() => _DiseasesScreenState();
}

class _DiseasesScreenState extends State<DiseasesScreen> {
  final _search = TextEditingController();
  String? _crop;
  DiseaseType? _type;

  @override
  void initState() {
    super.initState();
    context.read<DiseasesProvider>().load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _typeLabel(DiseaseType type, String Function(String) t) => t('type_${type.name}');

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final catalog = context.watch<DiseasesProvider>();
    final items = catalog.search(_search.text, locale: l.locale, cropId: _crop, type: _type)
        .where((d) => !d.isHealthy)
        .toList();
    final cropIds = catalog.crops.keys.toList()
      ..sort((a, b) => catalog.cropName(a, l.locale).compareTo(catalog.cropName(b, l.locale)));

    return Scaffold(
      appBar: AppBar(title: Text(t('diseasesLibrary'))),
      body: SafeArea(
        top: false,
        child: !catalog.isLoaded
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(Spacing.gutter, Spacing.md, Spacing.gutter, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          inputFormatters: [LengthLimitingTextInputFormatter(60)],
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: t('searchDisease'),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: t('clear'),
                                    onPressed: () => setState(_search.clear),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(t('allCrops')),
                                  selected: _crop == null,
                                  onSelected: (_) => setState(() => _crop = null),
                                ),
                              ),
                              for (final c in cropIds)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ChoiceChip(
                                    label: Text(catalog.cropName(c, l.locale)),
                                    selected: _crop == c,
                                    onSelected: (_) => setState(() => _crop = _crop == c ? null : c),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final type in DiseaseType.values.where((x) => x != DiseaseType.healthy))
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    avatar: Icon(diseaseTypeIcon(type), size: 18),
                                    label: Text(_typeLabel(type, t)),
                                    selected: _type == type,
                                    onSelected: (v) => setState(() => _type = v ? type : null),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(l.tf('resultsCount', {'n': items.length}), style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(icon: Icons.search_off_rounded, title: t('noResults')),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(Spacing.gutter, 0, Spacing.gutter, Spacing.xxxl),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final d = items[i];
                        return Card(
                          clipBehavior: Clip.antiAlias,
                          child: ListTile(
                            onTap: () => context.push('/diseases/${d.id}'),
                            leading: CircleAvatar(
                              backgroundColor: severityColor(d.severity).withValues(alpha: 0.14),
                              child: Icon(diseaseTypeIcon(d.type), color: severityColor(d.severity)),
                            ),
                            title: Text(d.name.of(l.locale)),
                            subtitle: Text(
                              '${d.crops.map((c) => catalog.cropName(c, l.locale)).join(', ')} · ${_typeLabel(d.type, t)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: catalog.isDetectable(d)
                                ? Tooltip(message: t('detectableByScan'), child: const Icon(Icons.center_focus_strong_rounded))
                                : null,
                          ),
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

class DiseaseDetailScreen extends StatelessWidget {
  final String diseaseId;
  const DiseaseDetailScreen({super.key, required this.diseaseId});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final loc = l.locale;
    final catalog = context.watch<DiseasesProvider>();
    final d = catalog.findById(diseaseId);
    final theme = Theme.of(context);
    if (d == null) {
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.search_off_rounded, title: t('noResults')));
    }
    Widget list(String title, List<String> items, IconData icon) => items.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(title: title, child: BulletList(items: items, icon: icon)),
          );
    Widget text(String title, String value) => value.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SectionCard(title: title, child: Text(value)),
          );

    return Scaffold(
      appBar: AppBar(title: Text(d.name.of(loc), maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: Spacing.page,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusPill(label: t('type_${d.type.name}'), color: theme.colorScheme.primary, icon: diseaseTypeIcon(d.type)),
              if (!d.isHealthy)
                StatusPill(label: '${t('severityLabel')} : ${ScanLabels.severity(d.severity, t)}', color: severityColor(d.severity)),
              if (catalog.isDetectable(d))
                StatusPill(label: t('detectableByScan'), color: Colors.teal, icon: Icons.center_focus_strong_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Text(d.name.of(loc), style: theme.textTheme.headlineSmall),
          if (d.scientificName.isNotEmpty)
            Text(d.scientificName, style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          Text(d.crops.map((c) => catalog.cropName(c, loc)).join(', '), style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          list(t('symptoms'), d.symptoms.of(loc), Icons.visibility_outlined),
          text(t('cause'), d.causes.of(loc)),
          list(t('favorableConditions'), d.conditions.of(loc), Icons.thermostat_rounded),
          list(t('whatToDoNow'), d.actions.of(loc), Icons.task_alt_rounded),
          list(t('prevention'), d.prevention.of(loc), Icons.shield_outlined),
          text(t('lookalikes'), d.lookalikes.of(loc)),
          text(t('whenToSeekHelp'), d.whenToSeekHelp.of(loc)),
          const SizedBox(height: 4),
          Text(t('libraryDisclaimer'), style: theme.textTheme.bodySmall),
        ],
      ),
      ),
    );
  }
}
