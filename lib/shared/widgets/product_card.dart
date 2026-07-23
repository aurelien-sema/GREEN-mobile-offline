import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';
import '../../core/extensions/context_extensions.dart';

/// Carte produit réutilisée par la Marketplace (carrousel horizontal) et par
/// l'écran "Voir tout" d'une catégorie (grille), pour éviter de dupliquer le
/// style de carte à deux endroits.
class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool isDarkMode;
  final double? width;

  const ProductCard({
    super.key,
    required this.product,
    required this.isDarkMode,
    this.width = 160,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    return GestureDetector(
      onTap: () => context.go('/product-detail', extra: {'productId': product.id}),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          border: Border.all(
            color: isDarkMode
                ? const Color.fromRGBO(66, 66, 66, 0.3)
                : const Color.fromRGBO(224, 224, 224, 0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color.fromRGBO(27, 94, 32, 0.2)
                        : const Color.fromRGBO(232, 245, 233, 0.3),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.radiusLarge),
                      topRight: Radius.circular(AppConstants.radiusLarge),
                    ),
                  ),
                  child: _buildImage(),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _buildQuickAddButton(context),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(AppConstants.paddingSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  if (product.reviewCount > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${product.rating}', style: Theme.of(context).textTheme.labelSmall),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.reviewCount})',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                              ),
                        ),
                      ],
                    )
                  else
                    Text(
                      t('noReviews'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                          ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.priceMin.toStringAsFixed(0)} - ${product.priceMax.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isDarkMode ? AppColors.darkPriceAccent : AppColors.lightPriceAccent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Ajout rapide au panier (1 unité) sans passer par le détail produit.
  Widget _buildQuickAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.read<CartProvider>().addItem(product, quantity: 1);
        final t = context.read<LocaleProvider>().t;
        context.showSnackBarMessage('${product.name} ${t('addedToCartSuffix')}');
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.2), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildImage() {
    final borderRadius = const BorderRadius.only(
      topLeft: Radius.circular(AppConstants.radiusLarge),
      topRight: Radius.circular(AppConstants.radiusLarge),
    );

    if (product.imageUrl == ProductModel.defaultImage) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Image.asset(
              'assets/images/logo.png',
              width: 44,
              height: 44,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    if (product.imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.asset(
          product.imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.image_not_supported,
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                size: 40,
              ),
            );
          },
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.image_not_supported,
        color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
        size: 40,
      ),
    );
  }
}
