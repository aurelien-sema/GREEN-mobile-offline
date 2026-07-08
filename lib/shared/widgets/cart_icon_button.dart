import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/cart_provider.dart';

/// Icône panier avec badge (nombre d'articles), utilisée dans les AppBars de
/// la Marketplace, de l'écran catégorie et du détail produit.
class CartIconButton extends StatelessWidget {
  final bool isDarkMode;
  const CartIconButton({super.key, required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().itemCount;
    final color = isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined, color: color),
            onPressed: () => context.push('/cart'),
          ),
          if (count > 0)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
