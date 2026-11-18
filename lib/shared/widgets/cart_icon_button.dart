import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/cart_provider.dart';
import '../../providers/locale_provider.dart';

/// Panier avec badge du nombre d'articles (Material 3 Badge).
class CartIconButton extends StatelessWidget {
  /// Conservé pour compatibilité ; le thème suffit désormais.
  final bool isDarkMode;
  const CartIconButton({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<CartProvider>().itemCount;
    final t = context.watch<LocaleProvider>().t;
    return IconButton(
      tooltip: t('cartTitle'),
      onPressed: () => context.push('/cart'),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
