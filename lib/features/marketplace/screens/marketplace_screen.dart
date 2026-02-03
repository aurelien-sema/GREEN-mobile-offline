import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/gradient_background.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final marketplace = context.read<MarketplaceProvider>();

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: CustomAppBar(
        title: 'Marketplace',
        showProfileIcon: true,
      ),
      body: GradientBackground(
        isDarkMode: isDarkMode,
        opacity: 0.1,
        child: SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(vertical: AppConstants.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenue à la Marketplace',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      )
                          .animate()
                          .fadeIn(duration: AppConstants.animationNormal)
                          .slideY(begin: -10, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        'Trouvez tous les produits agricoles dont vous avez besoin',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                            ),
                      )
                          .animate()
                          .fadeIn(duration: AppConstants.animationNormal, delay: const Duration(milliseconds: 100))
                          .slideY(begin: -10, end: 0),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.paddingLarge),

                // Catégories
                ...List.generate(
                  marketplace.categories.length,
                  (catIndex) {
                    final category = marketplace.categories[catIndex];
                    final productsInCategory = marketplace.getProductsByCategory(category.id);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Catégorie header
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    category.icon,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        category.name,
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        '${productsInCategory.length} produits',
                                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text(
                                  'Voir tout',
                                  style: TextStyle(
                                    color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                            .animate(delay: Duration(milliseconds: catIndex * 100))
                            .fadeIn()
                            .slideY(begin: 10, end: 0),
                        const SizedBox(height: 12),

                        // Carousel de produits
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                          child: Row(
                            children: List.generate(
                              productsInCategory.length,
                              (prodIndex) {
                                final product = productsInCategory[prodIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(right: AppConstants.paddingMedium),
                                  child: _buildProductCard(context, product, isDarkMode, catIndex, prodIndex),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, dynamic product, bool isDarkMode, int catIndex, int prodIndex) {
    return GestureDetector(
      onTap: () => context.go('/product-detail', extra: {'productId': product.id}),
      child: Container(
        width: 160,
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
            // Image
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color.fromRGBO(27, 94, 32, 0.2)
                    : const Color.fromRGBO(232, 245, 233, 0.3),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppConstants.radiusLarge),
                  topRight: Radius.circular(AppConstants.radiusLarge),
                ),
              ),
              child: _buildProductImage(product.imageUrl, isDarkMode),
            ),

            // Contenu
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
                        Text(
                          '${product.rating}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
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
                      'Aucun avis',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                          ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '${product.priceMin.toStringAsFixed(0)} - ${product.priceMax.toStringAsFixed(0)} FCFA',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
          .animate(
            delay: Duration(milliseconds: (catIndex * 300) + (prodIndex * 50)),
          )
          .fadeIn(duration: AppConstants.animationNormal)
          .slideY(begin: 20, end: 0),
    );
  }

  Widget _buildProductImage(String imageUrl, bool isDarkMode) {
    if (imageUrl.startsWith('assets/')) {
      return ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppConstants.radiusLarge),
          topRight: Radius.circular(AppConstants.radiusLarge),
        ),
        child: Image.asset(
          imageUrl,
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
