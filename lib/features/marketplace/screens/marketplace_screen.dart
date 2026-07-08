import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/cart_icon_button.dart';

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
    final t = context.watch<LocaleProvider>().t;
    final marketplace = context.read<MarketplaceProvider>();

    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: CustomAppBar(
        title: t('marketplaceTitle'),
        isDarkMode: isDarkMode,
        showProfileIcon: true,
        actions: [CartIconButton(isDarkMode: isDarkMode)],
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
                        t('welcomeToMarketplace'),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      )
                          .animate()
                          .fadeIn(duration: AppConstants.animationNormal)
                          .slideY(begin: -10, end: 0),
                      const SizedBox(height: 8),
                      Text(
                        t('findAllAgriProducts'),
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
                                onPressed: () => context.push(
                                  '/marketplace/category',
                                  extra: {'categoryId': category.id},
                                ),
                                child: Text(
                                  t('seeAll'),
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
                                  child: ProductCard(product: product, isDarkMode: isDarkMode)
                                      .animate(
                                        delay: Duration(milliseconds: (catIndex * 300) + (prodIndex * 50)),
                                      )
                                      .fadeIn(duration: AppConstants.animationNormal)
                                      .slideY(begin: 20, end: 0),
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

}
