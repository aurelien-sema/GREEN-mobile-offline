import 'package:flutter/material.dart';

import '../../core/theme/spacing.dart';

/// Carte de section : titre facultatif + contenu, bordure fine, sans ombre.
class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Widget? trailing;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding = Spacing.card,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(child: Text(title!, style: theme.textTheme.titleMedium)),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Titre de groupe dans une liste (Paramètres, Profil…).
class GroupLabel extends StatelessWidget {
  final String text;
  const GroupLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 28, 6, 10),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Groupe de lignes de réglage dans une carte, séparées par des filets.
class SettingsGroup extends StatelessWidget {
  final List<Widget> children;

  /// Retrait des filets : 60 dp quand les lignes ont une icône, 20 sinon.
  final double dividerIndent;
  const SettingsGroup({super.key, required this.children, this.dividerIndent = 60});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) items.add(Divider(height: 1, indent: dividerIndent, endIndent: 20));
      items.add(children[i]);
    }
    return Card(clipBehavior: Clip.antiAlias, child: Column(children: items));
  }
}

/// Ligne « libellé : valeur » (fiche terrain, à propos…).
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

/// Liste à puces lisible (symptômes, actions…).
class BulletList extends StatelessWidget {
  final List<String> items;
  final IconData? icon;
  final Color? color;
  const BulletList({super.key, required this.items, this.icon, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: icon != null
                      ? Icon(icon, size: 18, color: c)
                      : Container(
                          width: 7,
                          height: 7,
                          margin: const EdgeInsets.only(top: 6, left: 5, right: 6),
                          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(item, style: theme.textTheme.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}
