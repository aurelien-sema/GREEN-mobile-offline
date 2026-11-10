import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../ui/images.dart';

/// Barre d'application commune. [showProfileIcon] affiche la photo de
/// profil, qui ouvre le Profil par-dessus l'écran courant (le retour y
/// ramène naturellement, sans paramètre « from »).
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showProfileIcon;
  final Widget? leading;

  /// Conservé pour compatibilité ; le thème suffit désormais.
  final bool isDarkMode;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.isDarkMode = false,
    this.showProfileIcon = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    final user = context.watch<AuthProvider>().currentUser;
    return AppBar(
      title: Text(title),
      leading: leading,
      actions: [
        ...?actions,
        if (showProfileIcon)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: t('profile'),
              onPressed: () => context.push('/profile'),
              icon: UserAvatar(user: user, radius: 16),
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
