import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../models/scan_result_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/diseases_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../services/history_service.dart';
import '../../../shared/ui/ui.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../utils/date_formatter.dart';
import '../../history/scan_labels.dart';
import '../../weather/weather_texts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final w = context.read<WeatherProvider>();
      if (w.data == null && !w.loading) w.load(lang: context.read<LocaleProvider>().locale);
    });
  }

  Future<void> _refresh() => context.read<WeatherProvider>().load(lang: context.read<LocaleProvider>().locale);

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final user = context.watch<AuthProvider>().currentUser;
    final firstName = (user?.name ?? '').split(' ').first;

    return Scaffold(
      appBar: CustomAppBar(
        title: firstName.isEmpty ? t('home') : l.tf('helloName', {'name': firstName}),
        showProfileIcon: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: Spacing.page,
          children: [
            const _WeatherCard(),
            Spacing.gapBlock,
            _ScanCta(onTap: () => context.go('/camera')),
            Spacing.gapBlock,
            Row(
              children: [
                Expanded(
                  child: _ShortcutTile(
                    icon: Icons.chat_bubble_rounded,
                    label: t('greenBot'),
                    caption: t('aiAdviceShort'),
                    onTap: () => context.go('/chat'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutTile(
                    icon: Icons.history_rounded,
                    label: t('history'),
                    caption: t('historyShort'),
                    onTap: () => context.push('/history'),
                  ),
                ),
              ],
            ),
            Spacing.gapBlock,
            Row(
              children: [
                Expanded(
                  child: _ShortcutTile(
                    icon: Icons.menu_book_rounded,
                    label: t('diseasesLibrary'),
                    caption: t('diseasesLibraryShort'),
                    onTap: () => context.push('/diseases'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShortcutTile(
                    icon: Icons.storefront_rounded,
                    label: t('marketplaceTitle'),
                    caption: t('marketShort'),
                    onTap: () => context.go('/marketplace'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Text(t('recentScans'), style: Theme.of(context).textTheme.titleLarge)),
                TextButton(onPressed: () => context.push('/history'), child: Text(t('seeAll'))),
              ],
            ),
            const SizedBox(height: 4),
            const _RecentScans(),
          ],
        ),
      ),
    );
  }
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard();

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final w = context.watch<WeatherProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    Widget body;
    if (w.loading && w.data == null) {
      body = const SizedBox(height: 72, child: Center(child: CircularProgressIndicator()));
    } else if (w.data == null) {
      body = Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(child: Text(weatherErrorText(w.error, t), style: TextStyle(color: scheme.onPrimaryContainer))),
          TextButton(onPressed: () => w.load(lang: l.locale), child: Text(t('retry'))),
        ],
      );
    } else {
      final d = w.data!;
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(weatherIcon(d.condition), size: 44, color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${d.temperature.round()}°C', style: theme.textTheme.headlineMedium?.copyWith(color: scheme.onPrimaryContainer)),
                    Text(
                      '${capitalize(d.description)} · ${w.usingLocation ? (d.place.isEmpty ? t('myLocation') : d.place) : WeatherProvider.defaultCity}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onPrimaryContainer),
            ],
          ),
          Spacing.gapBlock,
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              _Metric(icon: Icons.water_drop_outlined, text: '${d.humidity} %'),
              _Metric(icon: Icons.air_rounded, text: '${(d.windSpeed * 3.6).round()} km/h'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t(d.sprayingDiscouraged ? 'sprayNo' : 'sprayOk'),
            style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer, fontWeight: FontWeight.w600),
          ),
          if (!w.usingLocation)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => w.load(lang: l.locale, requestLocation: true),
                icon: const Icon(Icons.my_location_rounded, size: 18),
                label: Text(t('useMyLocation')),
              ),
            ),
        ],
      );
    }

    return Card(
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/weather'),
        child: Padding(padding: Spacing.card, child: body),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Metric({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.onPrimaryContainer;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 18, color: c), const SizedBox(width: 4), Text(text, style: TextStyle(color: c))],
    );
  }
}

class _ScanCta extends StatelessWidget {
  final VoidCallback onTap;
  const _ScanCta({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.center_focus_strong_rounded, color: Colors.white, size: 40),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('scanAPlant'), style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(t('scanAPlantCaption'), style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String caption;
  final VoidCallback onTap;
  const _ShortcutTile({required this.icon, required this.label, required this.caption, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 10),
              Text(label, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(
                caption,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentScans extends StatelessWidget {
  const _RecentScans();

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final catalog = context.watch<DiseasesProvider>();
    return StreamBuilder<void>(
      stream: historyService.onChanged,
      builder: (context, _) => FutureBuilder<List<ScanResultModel>>(
        future: historyService.getRecentScans(3),
        builder: (context, snap) {
          final items = snap.data ?? const [];
          if (snap.connectionState == ConnectionState.waiting && items.isEmpty) {
            return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));
          }
          if (items.isEmpty) {
            return SectionCard(
              child: Row(
                children: [
                  Icon(Icons.eco_outlined, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t('noScansYetHint'))),
                ],
              ),
            );
          }
          return Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 76),
                  _ScanTile(scan: items[i], catalog: catalog, locale: l.locale, t: t),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScanTile extends StatelessWidget {
  final ScanResultModel scan;
  final DiseasesProvider catalog;
  final String locale;
  final String Function(String) t;
  const _ScanTile({required this.scan, required this.catalog, required this.locale, required this.t});

  @override
  Widget build(BuildContext context) {
    final style = scanStatusStyle(scan.status);
    return ListTile(
      onTap: () => context.push('/scan/${scan.id}'),
      leading: LocalImage(path: scan.thumbPath ?? scan.imagePath, width: 52, height: 52, cacheWidth: 160),
      title: Text(ScanLabels.title(scan, catalog, locale, t), maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${ScanLabels.plant(scan, catalog, locale, t)} · ${dayGroupLabel(scan.scannedAt, locale, t)}'),
      trailing: Icon(style.icon, color: style.color),
    );
  }
}
