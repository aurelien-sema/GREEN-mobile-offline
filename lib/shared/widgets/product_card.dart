import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';

/// Carte produit (carrousel de la Marketplace et grille « Voir tout »).
/// v2 : sans pictogrammes décoratifs (étoiles, panier miniature) ; l'ajout
/// rapide est un vrai bouton texte, plus facile à viser.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final double? width;

  /// Conservé pour compatibilité ; le thème suffit désormais.
  final bool isDarkMode;

  const ProductCard({super.key, required this.product, this.width = 168, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/product-detail', extra: {'productId': product.id}),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(aspectRatio: 4 / 3, child: _image(theme)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const Spacer(),
                      Text(
                        '${product.priceMin.toStringAsFixed(0)} – ${product.priceMax.toStringAsFixed(0)} FCFA',
                        style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        product.reviewCount > 0 ? '${product.rating} / 5 (${product.reviewCount})' : t('noReviews'),
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      context.read<CartProvider>().addItem(product, quantity: 1);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(SnackBar(
                          content: Text('${product.name} ${t('addedToCartSuffix')}'),
                          action: SnackBarAction(label: t('viewCart'), onPressed: () => context.push('/cart')),
                        ));
                    },
                    child: Text(t('addToCartShort')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(ThemeData theme) {
    final placeholder = ColoredBox(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Center(
        child: Image.asset('assets/images/logo_white.png', width: 44, height: 44, cacheWidth: 132),
      ),
    );
    if (product.imageUrl == ProductModel.defaultImage || !product.imageUrl.startsWith('assets/')) {
      return placeholder;
    }
    return Image.asset(
      product.imageUrl,
      fit: BoxFit.cover,
      cacheWidth: 400,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
