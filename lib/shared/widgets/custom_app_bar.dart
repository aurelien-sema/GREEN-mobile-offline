import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool isDarkMode;
  final bool showProfileIcon;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.isDarkMode = false,
    this.showProfileIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title, style: Theme.of(context).appBarTheme.titleTextStyle),
      centerTitle: true,
      backgroundColor: isDarkMode
          ? AppColors.darkSurface
          : AppColors.lightSurface,
      leading: null,
      actions: [
        ...?actions,
        if (showProfileIcon)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: GestureDetector(
                // Transmet la route courante pour que le bouton retour du
                // Profil y ramène (au lieu de forcer /home quel que soit
                // l'écran d'où l'on vient : Caméra, Chat, Marketplace...).
                onTap: () => context.go(
                  '/profile',
                  extra: {'from': GoRouterState.of(context).uri.toString()},
                ),
                child: Icon(
                  Icons.person,
                  color: isDarkMode ? AppColors.darkPrimary : AppColors.lightPrimary,
                  size: 24,
                ),
              ),
            ),
          ),
      ],
      elevation: 2,
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
