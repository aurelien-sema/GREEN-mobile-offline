import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/app_info.dart';
import '../../../core/theme/spacing.dart';
import '../../../providers/locale_provider.dart';
import '../../../shared/ui/ui.dart';
import '../../../utils/date_formatter.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(t('about'))),
      body: SafeArea(
        top: false,
        child: ListView(
        padding: Spacing.page,
        children: [
          Center(
            child: Image.asset(
              isDark ? 'assets/images/logo_dark.png' : 'assets/images/logo_white.png',
              width: 96,
              height: 96,
              cacheWidth: 300,
            ),
          ),
          Spacing.gapBlock,
          Text(AppInfo.name, style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary), textAlign: TextAlign.center),
          Text(t('appTagline'), style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            '${t('version')} ${AppInfo.fullVersion} · ${formatDate(DateTime.parse(AppInfo.releaseDate), l.locale)}',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SectionCard(child: Text(t('aboutDescription'), style: theme.textTheme.bodyLarge)),
          Spacing.gapBlock,
          SectionCard(
            title: t('whatGreenDoes'),
            child: BulletList(
              icon: Icons.check_circle_outline_rounded,
              items: [t('aboutFeature1'), t('aboutFeature2'), t('aboutFeature3'), t('aboutFeature4'), t('aboutFeature5')],
            ),
          ),
          Spacing.gapBlock,
          SectionCard(
            title: t('teamSection'),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(child: Text(t('teamDescription'), style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
          Spacing.gapBlock,
          SectionCard(
            title: t('privacyTitle'),
            child: BulletList(
              icon: Icons.lock_outline_rounded,
              items: [t('privacyPoint1'), t('privacyPoint2'), t('privacyPoint3')],
            ),
          ),
          Spacing.gapBlock,
          SectionCard(
            title: t('limitsTitle'),
            child: Text(t('diagnosisDisclaimer')),
          ),
          Spacing.gapBlock,
          OutlinedButton.icon(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: AppInfo.name,
              applicationVersion: AppInfo.fullVersion,
            ),
            icon: const Icon(Icons.description_outlined),
            label: Text(t('openSourceLicenses')),
          ),
          const SizedBox(height: 16),
          Text(t('copyrightNotice'), style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
        ],
      ),
      )
    );
  }
}
