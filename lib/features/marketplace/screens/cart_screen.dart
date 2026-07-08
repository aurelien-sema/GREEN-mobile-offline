import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/locale_provider.dart';
import '../../../providers/cart_provider.dart';
import '../../../providers/marketplace_provider.dart';
import '../../../models/product_model.dart';
import '../../../shared/widgets/custom_app_bar.dart';
import '../../../shared/widgets/gradient_background.dart';
import '../../../shared/widgets/app_pop_scope.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;
    final t = context.watch<LocaleProvider>().t;
    final cart = context.watch<CartProvider>();

    return AppPopScope(
      onWillPop: () async {
        context.go('/marketplace');
        return false;
      },
      child: Scaffold(
        backgroundColor: isDarkMode ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: CustomAppBar(title: t('myCart'), isDarkMode: isDarkMode),
        body: GradientBackground(
          isDarkMode: isDarkMode,
          opacity: 0.1,
          child: SafeArea(
            child: cart.isEmpty
                ? _buildEmptyState(context, isDarkMode, t)
                : Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          itemCount: cart.items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: AppConstants.paddingSmall),
                          itemBuilder: (context, index) => _buildCartTile(context, cart.items[index], isDarkMode),
                        ),
                      ),
                      _buildSummary(context, cart, isDarkMode, t),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDarkMode, String Function(String) t) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 72,
            color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
          ),
          const SizedBox(height: 16),
          Text(
            t('emptyCartMessage'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/marketplace'),
            child: Text(t('backToMarketplace')),
          ),
        ],
      ),
    );
  }

  Widget _buildCartTile(BuildContext context, CartItem item, bool isDarkMode) {
    final cart = context.read<CartProvider>();
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingSmall),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDarkMode
              ? const Color.fromRGBO(66, 66, 66, 0.3)
              : const Color.fromRGBO(224, 224, 224, 0.5),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.radiusSmall),
            child: SizedBox(width: 56, height: 56, child: _buildThumbnail(item.product, isDarkMode)),
          ),
          const SizedBox(width: AppConstants.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.totalPrice.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1),
          ),
          Text('${item.quantity}', style: Theme.of(context).textTheme.titleSmall),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => cart.updateQuantity(item.product.id, item.quantity + 1),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => cart.removeItem(item.product.id),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnail(ProductModel product, bool isDarkMode) {
    if (product.imageUrl == ProductModel.defaultImage) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Image.asset('assets/images/logo.png', width: 24, height: 24, color: Colors.white),
        ),
      );
    }
    if (product.imageUrl.startsWith('assets/')) {
      return Image.asset(
        product.imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.image_not_supported,
          color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
        ),
      );
    }
    return Icon(Icons.image_not_supported, color: isDarkMode ? AppColors.darkHint : AppColors.lightHint);
  }

  Widget _buildSummary(BuildContext context, CartProvider cart, bool isDarkMode, String Function(String) t) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        boxShadow: [
          BoxShadow(color: const Color.fromRGBO(0, 0, 0, 0.08), blurRadius: 12, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    '${t('totalLabel')} (${cart.itemCount} ${cart.itemCount > 1 ? t('itemPlural') : t('itemSingular')})',
                    style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  '${cart.totalPrice.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _validateOrder(context, cart, isDarkMode),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppConstants.radiusLarge)),
                ),
                child: Text(t('validateOrder'), style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateOrder(BuildContext context, CartProvider cart, bool isDarkMode) async {
    final marketplace = context.read<MarketplaceProvider>();
    final t = context.read<LocaleProvider>().t;
    final items = List<CartItem>.from(cart.items);

    for (final item in items) {
      await marketplace.placeOrder(item.product.id, item.quantity);
    }
    cart.clear();

    if (!context.mounted) return;
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
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.check_circle, size: 44, color: Colors.green)),
              ),
              const SizedBox(height: 16),
              Text(t('orderConfirmed'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        content: Text(
          t('orderConfirmedMessage')
              .replaceAll('{count}', '${items.length}')
              .replaceAll('{plural}', items.length > 1 ? t('productPlural') : t('productSingular')),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/marketplace');
              },
              child: Text(t('backToMarketplace')),
            ),
          ),
        ],
      ),
    );
  }
}
