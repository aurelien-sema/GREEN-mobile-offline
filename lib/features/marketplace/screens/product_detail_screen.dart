import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../models/product_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/gradient_background.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  const ProductDetailScreen({required this.productId, super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final marketplace = context.read<MarketplaceProvider>();
    final product = marketplace.getProductById(widget.productId);

    if (product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Produit')),
        body: Center(child: Text('Produit non trouvé')),
      );
    }

    // Calcul du total en utilisant le prix moyen (priceMin + priceMax) / 2
    final avgPrice = (product.priceMin + product.priceMax) / 2;
    final totalPrice = avgPrice * _quantity;

    return WillPopScope(
      onWillPop: () async {
        context.go('/marketplace');
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: Text(product.name),
          elevation: 0,
          backgroundColor: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/marketplace'),
          ),
        ),
        body: GradientBackground(
          isDarkMode: isDarkMode,
          opacity: 0.1,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color.fromRGBO(27, 94, 32, 0.2)
                          : const Color.fromRGBO(232, 245, 233, 0.3),
                      borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
                      border: Border.all(
                        color: isDarkMode
                            ? const Color.fromRGBO(66, 66, 66, 0.3)
                            : const Color.fromRGBO(224, 224, 224, 0.5),
                        width: 1,
                      ),
                    ),
                    child: _buildProductImage(product.imageUrl, isDarkMode),
                  )
                      .animate()
                      .fadeIn(duration: AppConstants.animationNormal)
                      .slideY(begin: -20, end: 0),
                  const SizedBox(height: AppConstants.paddingLarge),

                  // Nom et note
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                  )
                      .animate()
                      .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 100))
                      .slideY(begin: 10, end: 0),
                  const SizedBox(height: 8),
                  if (product.reviewCount > 0)
                    Row(
                      children: [
                        const Icon(Icons.star, size: 18, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                          '${product.rating} · ${product.reviewCount} avis',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.star_border,
                          size: 18,
                          color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Aucun avis pour le moment',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                              ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 150))
                    .slideY(begin: 10, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),

                // Fournisseur
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color.fromRGBO(66, 66, 66, 0.3)
                          : const Color.fromRGBO(224, 224, 224, 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.store, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: AppConstants.paddingMedium),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fournisseur',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                                ),
                          ),
                          Text(
                            product.supplierName,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 200))
                    .slideY(begin: 10, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),

                // Description
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                )
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 250))
                    .slideY(begin: 10, end: 0),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 300))
                    .slideY(begin: 10, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),

                // Tags
                if (product.tags.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: product.tags
                            .map((tag) => Chip(
                                  label: Text(tag),
                                  backgroundColor: isDarkMode
                                      ? const Color.fromRGBO(27, 94, 32, 0.2)
                                      : const Color.fromRGBO(232, 245, 233, 0.3),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                    ],
                  )
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 350))
                    .slideY(begin: 10, end: 0),

                // Prix
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: isDarkMode
                          ? const Color.fromRGBO(66, 66, 32, 0.3)
                          : const Color.fromRGBO(255, 193, 7, 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${product.priceMin.toStringAsFixed(0)} - ${product.priceMax.toStringAsFixed(0)} FCFA',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.amber,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Prix moyen: ${avgPrice.toStringAsFixed(0)} FCFA',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                            ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 375))
                    .slideY(begin: 10, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),

                // Caractéristiques
                if (product.characteristics.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Caractéristiques',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      )
                          .animate()
                          .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 400))
                          .slideY(begin: 10, end: 0),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: product.characteristics
                            .asMap()
                            .entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '• ',
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                      Expanded(
                                        child: Text(
                                          entry.value,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                    ],
                                  ),
                                ))
                            .toList(),
                      )
                          .animate()
                          .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 425))
                          .slideY(begin: 10, end: 0),
                      const SizedBox(height: AppConstants.paddingLarge),
                    ],
                  ),

                // Lieu
                if (product.location.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lieu de disponibilité',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            product.location,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppConstants.paddingLarge),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 450))
                      .slideY(begin: 10, end: 0),

                // Quantité et total
                Container(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  decoration: BoxDecoration(
                    color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
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
                      Text(
                        'Quantité',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            iconSize: 28,
                          ),
                          SizedBox(
                            width: 60,
                            child: Center(
                              child: Text(
                                _quantity.toString(),
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _quantity++),
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 28,
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Total',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                                    ),
                              ),
                              Text(
                                '${totalPrice.toStringAsFixed(0)} FCFA',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 400))
                    .slideY(begin: 10, end: 0),
                const SizedBox(height: AppConstants.paddingLarge),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
          child: ElevatedButton(
            onPressed: () => _showOrderConfirmation(context, product, isDarkMode),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
              ),
            ),
            child: Text(
              'Commander',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          )
              .animate()
              .fadeIn(duration: AppConstants.animationNormal)
              .slideY(begin: 20, end: 0),
        ),
      ),
    ));
  }

  Widget _buildProductImage(String imageUrl, bool isDarkMode) {
    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
        child: Image.asset(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.image_not_supported,
                color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                size: 80,
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
        size: 80,
      ),
    );
  }

  void _showOrderConfirmation(BuildContext context, ProductModel product, bool isDarkMode) async {
    final marketplace = context.read<MarketplaceProvider>();

    // Simuler la création de la commande
    final success = await marketplace.placeOrder(product.id, _quantity);

    if (mounted && success) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: isDarkMode ? AppColors.darkSurface : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
          title: Center(
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.check_circle, size: 48, color: Colors.green),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Commande confirmée',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Votre commande a bien été prise en compte.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: isDarkMode ? const Color.fromRGBO(27, 94, 32, 0.2) : const Color.fromRGBO(232, 245, 233, 0.3),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Quantité: $_quantity',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ${(product.price * _quantity).toStringAsFixed(0)} FCFA',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.go('/marketplace');
                },
                child: const Text('Retour à la Marketplace'),
              ),
            ),
          ],
        ),
      );
    }
  }
}
