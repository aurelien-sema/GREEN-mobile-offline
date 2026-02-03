import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/theme_provider.dart';
import 'app_drawer.dart';
import 'app_pop_scope.dart';

/// Widget shell pour gérer la navigation principale avec BottomNavigationBar
class MainNavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationShell({super.key, required this.navigationShell});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell>
    with SingleTickerProviderStateMixin {
  late int _selectedIndex;
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.navigationShell.currentIndex;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
  }

  @override
  void didUpdateWidget(MainNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected index when the navigation shell's current index changes
    if (widget.navigationShell.currentIndex != _selectedIndex) {
      setState(() {
        _selectedIndex = widget.navigationShell.currentIndex;
      });
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      _animationController.forward(from: 0.0);
    }

    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.watch<ThemeProvider>().isDarkMode;

    // Migrate to PopScope to support Android predictive back gesture.
    return AppPopScope(
      onWillPop: () async {
        // If not on home tab, switch to home instead of exiting
        final currentIndex = widget.navigationShell.currentIndex;
        if (currentIndex != 0) {
          widget.navigationShell.goBranch(0);
          return false;
        }

        // If on home, ask for confirmation to exit
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Quitter'),
            content: const Text('Voulez-vous quitter l\'application ?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Quitter'),
              ),
            ],
          ),
        );

        if (shouldExit == true) {
          return true;
        }
        return false;
      },
      child: Scaffold(
        drawer: const AppDrawer(),
        body: widget.navigationShell,
        extendBody: true,
        bottomNavigationBar: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return SlideTransition(
              position: _slideAnimation,
              child: Container(
                margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: BottomNavigationBar(
                    currentIndex: _selectedIndex,
                    onTap: _onItemTapped,
                    type: BottomNavigationBarType.fixed,
                    backgroundColor: isDarkMode
                        ? const Color.fromRGBO(30, 30, 30, 0.95)
                        : const Color.fromRGBO(255, 255, 255, 0.95),
                    selectedItemColor: isDarkMode
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    unselectedItemColor: isDarkMode
                        ? AppColors.darkHint
                        : Color(0xFF999999),
                    elevation: 0,
                    items: [
                      BottomNavigationBarItem(
                        icon: ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1.2).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: const Icon(Icons.home),
                        ),
                        label: 'Accueil',
                      ),
                      BottomNavigationBarItem(
                        icon: ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1.2).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: const Icon(Icons.camera_alt),
                        ),
                        label: 'Scanner',
                      ),
                      BottomNavigationBarItem(
                        icon: ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1.2).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: const Icon(Icons.chat_bubble),
                        ),
                        label: 'Green Bot',
                      ),
                      BottomNavigationBarItem(
                        icon: ScaleTransition(
                          scale: Tween<double>(begin: 1, end: 1.2).animate(
                            CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.elasticOut,
                            ),
                          ),
                          child: const Icon(Icons.shopping_bag),
                        ),
                        label: 'Marketplace',
                      ),
                    ],
                  ), // BottomNavigationBar
                ), // ClipRRect
              ), // Container
            ); // SlideTransition
          },
        ),
      ),
    );
  }
}
