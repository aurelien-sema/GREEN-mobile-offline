import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../models/product_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/app_pop_scope.dart';
import '../../../shared/widgets/product_card.dart';
import '../../../shared/widgets/cart_icon_button.dart';

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

    return AppPopScope(
      onWillPop: () async {
        context.go('/marketplace');
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: CustomAppBar(
          title: category?.name ?? t('productsLabel'),
          isDarkMode: isDarkMode,
          actions: [CartIconButton(isDarkMode: isDarkMode)],
        ),
        body: GradientBackground(
          isDarkMode: isDarkMode,
          opacity: 0.1,
          child: SafeArea(
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
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
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
        ),
      ),
    );
  }
}
