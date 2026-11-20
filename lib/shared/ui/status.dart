import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../models/disease_catalog_model.dart';
import '../../models/scan_result_model.dart';

/// Couleur et icône d'un statut d'analyse.
({Color color, IconData icon}) scanStatusStyle(ScanStatus status) => switch (status) {
      ScanStatus.healthy => (color: AppColors.success, icon: Icons.check_circle_rounded),
      ScanStatus.diseased => (color: AppColors.danger, icon: Icons.coronavirus_rounded),
      ScanStatus.uncertain => (color: AppColors.warning, icon: Icons.help_rounded),
      // 2.2.0 : feuille d'une autre culture que celle choisie.
      ScanStatus.wrongCrop => (color: AppColors.warning, icon: Icons.swap_horiz_rounded),
      ScanStatus.error => (color: Colors.grey, icon: Icons.error_outline_rounded),
    };

Color severityColor(Severity s) => switch (s) {
      Severity.high => AppColors.danger,
      Severity.moderate => AppColors.warning,
      Severity.low => AppColors.info,
      Severity.none => AppColors.success,
    };

IconData diseaseTypeIcon(DiseaseType t) => switch (t) {
      DiseaseType.healthy => Icons.eco_rounded,
      DiseaseType.fungal => Icons.grain_rounded,
      DiseaseType.oomycete => Icons.water_drop_rounded,
      DiseaseType.bacterial => Icons.bubble_chart_rounded,
      DiseaseType.viral => Icons.blur_on_rounded,
      DiseaseType.pest => Icons.bug_report_rounded,
      DiseaseType.nematode => Icons.timeline_rounded,
      DiseaseType.physiological => Icons.wb_sunny_rounded,
    };

/// Pastille colorée : statut, gravité, état d'envoi…
class StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;

  const StatusPill({super.key, required this.label, required this.color, this.icon, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Color.lerp(color, Colors.white, 0.35)! : color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: dense ? 3 : 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: dense ? 14 : 16, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: dense ? 12 : 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Barre de confiance du modèle, avec pourcentage.
class ConfidenceBar extends StatelessWidget {
  final double value; // 0..1
  final String label;
  const ConfidenceBar({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (value * 100).round();
    final color = value >= 0.85
        ? AppColors.success
        : value >= 0.7
            ? AppColors.info
            : AppColors.warning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Text('$pct %', style: theme.textTheme.titleMedium?.copyWith(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }
}
