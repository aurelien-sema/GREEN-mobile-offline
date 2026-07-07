import 'package:flutter/material.dart';

/// Wrapper autour de `PopScope` qui conserve l'API `onWillPop` (façon
/// `WillPopScope`) utilisée dans tout le reste de l'app : une fonction async
/// qui renvoie `true` pour laisser le retour se faire, ou `false` après avoir
/// géré elle-même la navigation (ex: changer d'onglet, afficher une
/// confirmation). `PopScope` gère nativement le geste de retour prédictif
/// d'Android 13+, contrairement à `WillPopScope`.
class AppPopScope extends StatelessWidget {
  final Widget child;
  final Future<bool> Function()? onWillPop;

  const AppPopScope({super.key, required this.child, this.onWillPop});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Si onWillPop est fourni, on intercepte toujours le pop pour pouvoir
      // évaluer la condition async avant de décider ; sinon comportement par défaut.
      canPop: onWillPop == null,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || onWillPop == null) return;
        final shouldPop = await onWillPop!();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: child,
    );
  }
}
