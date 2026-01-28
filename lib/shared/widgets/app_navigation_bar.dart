import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class AppNavigationBar extends StatefulWidget {
  final int currentIndex;
  const AppNavigationBar({super.key, this.currentIndex = 0});

  @override
  State<AppNavigationBar> createState() => _AppNavigationBarState();
}

class _AppNavigationBarState extends State<AppNavigationBar> {
  late int _selected;

  final List<_NavItem> _items = [
    _NavItem(label: 'Accueil', icon: Icons.home, path: '/'),
    _NavItem(label: 'Scanner', icon: Icons.camera_alt, path: '/camera'),
    _NavItem(label: 'Chat', icon: Icons.chat, path: '/chat'),
    _NavItem(label: 'Maladies', icon: Icons.spa, path: '/diseases'),
    _NavItem(label: 'Profil', icon: Icons.person, path: '/profile'),
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.currentIndex;
  }

  void _onTap(int idx) {
    final item = _items[idx];
    setState(() => _selected = idx);
    // Use GoRouter to navigate; do not push if already there
    final router = GoRouter.of(context);
    // navigate to target route (GoRouter will handle no-op if already there)
    router.go(item.path);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      elevation: 8,
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : AppColors.lightGradient,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_items.length, (i) {
            final item = _items[i];
            final selected = i == _selected;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _onTap(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 6,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? (isDark
                              ? const Color.fromRGBO(76, 175, 80, 0.12)
                              : const Color.fromRGBO(46, 139, 87, 0.12))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedScale(
                        duration: const Duration(milliseconds: 360),
                        scale: selected ? 1.08 : 1.0,
                        curve: Curves.easeInOut,
                        child: Icon(
                          item.icon,
                          color: selected
                              ? (isDark
                                    ? AppColors.darkPrimary
                                    : AppColors.lightPrimary)
                              : (isDark
                                    ? AppColors.darkHint
                                    : AppColors.lightHint),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: selected ? 1.0 : 0.0,
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: selected
                                ? (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary)
                                : Colors.transparent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem({required this.label, required this.icon, required this.path});
}
