import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool isDarkMode;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.isDarkMode = false,
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
      actions: actions,
      elevation: 2,
      shadowColor: const Color.fromRGBO(0, 0, 0, 0.1),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
