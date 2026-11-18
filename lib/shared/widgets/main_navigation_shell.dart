import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/locale_provider.dart';
import '../../services/green_web/photo_sync_service.dart';

/// Coque des quatre onglets principaux (Accueil, Scanner, GreenBot, Marché).
///
/// Corrections v2 :
/// - barre de navigation Material 3 ancrée en bas (l'ancienne barre
///   flottante, avec `extendBody`, recouvrait la fin des listes et le champ
///   de saisie du chat) ;
/// - retour système : depuis un onglet autre que l'Accueil, revient à
///   l'Accueil ; depuis l'Accueil, demande confirmation puis quitte vraiment
///   l'application (la v1 rouvrait la boîte de dialogue en boucle) ;
/// - au retour dans l'application, les photos en attente sont envoyées.
class MainNavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;
  const MainNavigationShell({super.key, required this.navigationShell});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final lang = context.read<LocaleProvider>().locale;
      context.read<PhotoSyncService>().syncPending(lang: lang);
    }
  }

  void _select(int index) {
    widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
  }

  Future<void> _onBack() async {
    if (widget.navigationShell.currentIndex != 0) {
      _select(0);
      return;
    }
    final t = context.read<LocaleProvider>().t;
    final quit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('quit')),
        content: Text(t('quitAppConfirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t('cancel'))),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t('quit')),
          ),
        ],
      ),
    );
    if (quit == true) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<LocaleProvider>().t;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBack();
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: _select,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home_rounded),
              label: t('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.center_focus_weak_rounded),
              selectedIcon: const Icon(Icons.center_focus_strong_rounded),
              label: t('scanner'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              selectedIcon: const Icon(Icons.chat_bubble_rounded),
              label: t('greenBot'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.storefront_outlined),
              selectedIcon: const Icon(Icons.storefront_rounded),
              label: t('marketplaceTitle'),
            ),
          ],
        ),
      ),
    );
  }
}
