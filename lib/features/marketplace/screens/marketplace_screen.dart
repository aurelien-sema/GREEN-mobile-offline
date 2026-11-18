import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/spacing.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../shared/widgets/cart_icon_button.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/product_card.dart';

/// Marketplace : une rangée de produits par catégorie.
/// v2 : sans les petites icônes décoratives (emoji de catégorie, étoiles,
/// pictogrammes), titres de catégorie lisibles, nombre de produits traduit.
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.watch<LocaleProvider>();
    final t = l.t;
    final theme = Theme.of(context);
    final market = context.read<MarketplaceProvider>();

    return Scaffold(
      appBar: CustomAppBar(
        title: t('marketplaceTitle'),
        showProfileIcon: true,
        actions: const [CartIconButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('welcomeToMarketplace'), style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  t('findAllAgriProducts'),
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (final category in market.categories) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(Spacing.gutter, Spacing.sm, Spacing.sm, Spacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: theme.textTheme.titleMedium),
                        Text(
                          l.tf('productsCount', {'n': market.getProductsByCategory(category.id).length}),
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/marketplace/category', extra: {'categoryId': category.id}),
                    child: Text(t('seeAll')),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 262,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Spacing.gutter),
                itemCount: market.getProductsByCategory(category.id).length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) => ProductCard(product: market.getProductsByCategory(category.id)[i]),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
