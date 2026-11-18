import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/weather_provider.dart';
import '../../../shared/ui/ui.dart';
import '../../../utils/date_formatter.dart';
import '../weather_texts.dart';

/// Météo détaillée. Toutes les valeurs viennent d'OpenWeatherMap (la v1
/// affichait une pression fixe « 1012 hPa » et une météo inventée sans clé).
class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final w = context.watch<WeatherProvider>();
    final theme = Theme.of(context);
    final d = w.data;

    return Scaffold(
      appBar: AppBar(
        title: Text(t('detailedWeather')),
        actions: [
          IconButton(
            tooltip: t('refresh'),
            onPressed: w.loading ? null : () => w.load(lang: l.locale),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
        onRefresh: () => w.load(lang: l.locale),
        child: ListView(
          padding: Spacing.page,
          children: [
            if (w.loading && d == null)
              const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
            else if (d == null)
              EmptyState(
                icon: Icons.cloud_off_rounded,
                title: t('weatherUnavailable'),
                message: weatherErrorText(w.error, t),
                action: FilledButton(onPressed: () => w.load(lang: l.locale), child: Text(t('retry'))),
              )
            else ...[
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(weatherIcon(d.condition), size: 64, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(height: 8),
                      Text('${d.temperature.round()}°C', style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                      Text(capitalize(d.description), style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text(
                        '${w.usingLocation ? (d.place.isEmpty ? t('myLocation') : d.place) : WeatherProvider.defaultCity} · ${l.tf('observedAt', {'time': formatTime(d.observedAt)})}',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: t('fieldConditions'),
                child: Column(
                  children: [
                    InfoRow(label: t('feelsLike'), value: '${d.feelsLike.round()}°C'),
                    InfoRow(label: t('humidity'), value: '${d.humidity} %'),
                    InfoRow(label: t('wind'), value: '${(d.windSpeed * 3.6).round()} km/h'),
                    InfoRow(label: t('cloudiness'), value: '${d.cloudiness} %'),
                    InfoRow(label: t('rainLastHour'), value: '${d.rainLastHour.toStringAsFixed(1)} mm'),
                    InfoRow(label: t('pressure'), value: '${d.pressure} hPa'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                title: t('farmAdvice'),
                child: BulletList(
                  icon: Icons.lightbulb_outline_rounded,
                  items: [
                    t(d.sprayingDiscouraged ? 'sprayNoLong' : 'sprayOkLong'),
                    if (d.humidity >= 85) t('highHumidityAdvice'),
                    if (d.temperature >= 33) t('heatAdvice'),
                  ],
                ),
              ),
              if (!w.usingLocation) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    await w.load(lang: l.locale, requestLocation: true);
                    if (!context.mounted || w.locationIssue == LocationIssue.none) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(t(w.locationIssue == LocationIssue.serviceDisabled ? 'gpsDisabled' : 'locationPermissionDenied')),
                      action: SnackBarAction(label: t('openSettings'), onPressed: w.openLocationSettings),
                    ));
                  },
                  icon: const Icon(Icons.my_location_rounded),
                  label: Text(t('useMyLocation')),
                ),
              ],
              Spacing.gapBlock,
              Text(t('weatherSource'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
      ),
    );
  }
}
