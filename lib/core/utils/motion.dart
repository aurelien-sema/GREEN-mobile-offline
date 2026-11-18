import 'package:flutter/widgets.dart';

/// Durées d'animation qui respectent le réglage d'accessibilité Android
/// « Supprimer les animations » : renvoie Duration.zero quand il est actif.
class Motion {
  Motion._();

  static Duration of(BuildContext context, Duration duration) {
    return MediaQuery.maybeDisableAnimationsOf(context) == true ? Duration.zero : duration;
  }
}
