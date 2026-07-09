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
import 'seller_chat_screen.dart';

class _PaymentOption {
  final String value;
  final String labelKey;
  final IconData icon;
  const _PaymentOption(this.value, this.labelKey, this.icon);
}

class _DeliveryOption {
  final String value;
  final String labelKey;
  final double fee;
  const _DeliveryOption(this.value, this.labelKey, this.fee);
}

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  static const _paymentOptions = [
    _PaymentOption('mobile_money', 'paymentMobileMoney', Icons.phone_android),
    _PaymentOption('cash_on_delivery', 'paymentCashOnDelivery', Icons.payments_outlined),
    _PaymentOption('bank_transfer', 'paymentBankTransfer', Icons.account_balance_outlined),
  ];

  static const _deliveryOptions = [
    _DeliveryOption('pickup', 'deliveryPickup', 0),
    _DeliveryOption('home_delivery', 'deliveryHome', 1500),
  ];

  String _paymentMethod = _paymentOptions.first.value;
  String _deliveryMethod = _deliveryOptions.first.value;

  double get _deliveryFee =>
      _deliveryOptions.firstWhere((o) => o.value == _deliveryMethod).fee;

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
                        child: ListView(
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          children: [
                            ...cart.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: AppConstants.paddingSmall),
                                child: _buildCartTile(context, item, isDarkMode, t),
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildSectionCard(
                              context,
                              isDarkMode,
                              title: t('paymentMethodTitle'),
                              child: Column(
                                children: _paymentOptions
                                    .map((o) => RadioListTile<String>(
                                          value: o.value,
                                          groupValue: _paymentMethod,
                                          onChanged: (v) => setState(() => _paymentMethod = v!),
                                          contentPadding: EdgeInsets.zero,
                                          activeColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                                          title: Row(
                                            children: [
                                              Icon(o.icon, size: 20, color: isDarkMode ? AppColors.darkHint : AppColors.lightHint),
                                              const SizedBox(width: 8),
                                              Expanded(child: Text(t(o.labelKey))),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            _buildSectionCard(
                              context,
                              isDarkMode,
                              title: t('deliveryMethodTitle'),
                              child: Column(
                                children: _deliveryOptions
                                    .map((o) => RadioListTile<String>(
                                          value: o.value,
                                          groupValue: _deliveryMethod,
                                          onChanged: (v) => setState(() => _deliveryMethod = v!),
                                          contentPadding: EdgeInsets.zero,
                                          activeColor: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                                          title: Text(t(o.labelKey)),
                                          subtitle: Text(
                                            o.fee > 0
                                                ? '+${o.fee.toStringAsFixed(0)} FCFA'
                                                : t('freeDelivery'),
                                            style: TextStyle(
                                              color: isDarkMode ? AppColors.darkHint : AppColors.lightHint,
                                            ),
                                          ),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
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

  Widget _buildSectionCard(BuildContext context, bool isDarkMode, {required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        border: Border.all(
          color: isDarkMode
              ? const Color.fromRGBO(66, 66, 66, 0.3)
              : const Color.fromRGBO(224, 224, 224, 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          child,
        ],
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

  Widget _buildCartTile(BuildContext context, CartItem item, bool isDarkMode, String Function(String) t) {
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
      child: Column(
        children: [
          Row(
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
                            color: isDarkMode ? AppColors.darkPriceAccent : AppColors.lightPriceAccent,
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => SellerChatScreen(product: item.product)),
              ),
              icon: const Icon(Icons.chat_bubble_outline, size: 16),
              label: Text(t('contactSupplier'), style: const TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
            ),
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
    final total = cart.totalPrice + _deliveryFee;
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
                  '${total.toStringAsFixed(0)} FCFA',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDarkMode ? AppColors.darkPriceAccent : AppColors.lightPriceAccent,
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

    // Les frais de livraison ne s'appliquent qu'une fois pour la commande
    // globale, pas par article — attribués au premier article uniquement.
    for (var i = 0; i < items.length; i++) {
      await marketplace.placeOrder(
        items[i].product.id,
        items[i].quantity,
        paymentMethod: _paymentMethod,
        deliveryMethod: _deliveryMethod,
        deliveryFee: i == 0 ? _deliveryFee : 0,
      );
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
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.go('/marketplace');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(t('backToMarketplace')),
            ),
          ),
        ],
      ),
    );
  }
}
