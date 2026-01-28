import 'package:flutter/material.dart';
import 'app_navigation_bar.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBottomNav;
  final int? selectedBottomNav;
  final Function(int)? onBottomNavChanged;
  final PreferredSizeWidget? appBar;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final ScrollPhysics? scrollPhysics;

  const AppScaffold({
    super.key,
    this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showBottomNav = false,
    this.selectedBottomNav,
    this.onBottomNavChanged,
    this.appBar,
    this.showBackButton = false,
    this.onBackPressed,
    this.backgroundColor,
    this.scrollPhysics,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: appBar,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: scrollPhysics ?? const ClampingScrollPhysics(),
          child: body,
        ),
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: showBottomNav
          ? AppNavigationBar(currentIndex: selectedBottomNav ?? 0)
          : null,
    );
  }
}
