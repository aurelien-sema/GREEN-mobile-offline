import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/spacing.dart';
import '../../../models/product_model.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../shared/widgets/cart_icon_button.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/product_card.dart';

/// Grille listant tous les produits d'une catégorie — destination du bouton
/// "Voir tout" (auparavant sans action) sur l'écran principal de la
/// Marketplace, dont le carrousel horizontal n'est pas adapté à la
/// consultation de nombreux produits.
class CategoryProductsScreen extends StatelessWidget {
  final String categoryId;
  const CategoryProductsScreen({required this.categoryId, super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final t = context.watch<LocaleProvider>().t;
    final marketplace = context.read<MarketplaceProvider>();
    CategoryModel? category;
    try {
      category = marketplace.categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      category = null;
    }
    final products = marketplace.getProductsByCategory(categoryId);

    return Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: CustomAppBar(
          title: category?.name ?? t('productsLabel'),
          isDarkMode: isDarkMode,
          actions: [CartIconButton(isDarkMode: isDarkMode)],
        ),
        body: SafeArea(
            child: products.isEmpty
                ? Center(
                    child: Text(
                      t('noProductsInCategory'),
                      style: TextStyle(
                        color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(Spacing.gutter),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppConstants.paddingMedium,
                      crossAxisSpacing: AppConstants.paddingMedium,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: products[index],
                        isDarkMode: isDarkMode,
                        width: null,
                      );
                    },
                  ),
          ),
      );
  }
}
