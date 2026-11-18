import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

/// Thème Material 3 de GREEN.
///
/// Choix de conception (usage au champ, en plein soleil, sur des téléphones
/// modestes) :
/// - police système (Roboto sur Android) : rien à télécharger, lisible hors
///   ligne — l'ancienne police Google Fonts était chargée depuis Internet ;
/// - contrastes élevés et cibles tactiles de 48 dp minimum (boutons 52 dp) ;
/// - animations courtes et utiles : transitions de page natives Android avec
///   retour prédictif, retours visuels de 150 à 250 ms, aucune entrée
///   « en cascade » des éléments à l'ouverture d'un écran ;
/// - v2.1, interfaces plus aérées et épurées : cartes en aplat tonal sans
///   bordure (le contraste vient de la couleur, pas des traits), rayons de
///   18 dp, champs blancs à contour discret, lignes de liste plus hautes,
///   marges de 20 dp (voir Spacing), interligne plus généreux.
class AppTheme {
  AppTheme._();

  static ThemeData lightTheme() => _build(Brightness.light);
  static ThemeData darkTheme() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.lightPrimary,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
      onPrimary: Colors.white,
      error: isDark ? AppColors.darkError : AppColors.lightError,
      surface: isDark ? AppColors.darkSurface : AppColors.lightSurface,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
    );

    // base.textTheme ne porte que les couleurs : les tailles (géométrie) ne
    // sont ajoutées qu'au moment de l'affichage. Les styles réutilisés plus
    // bas (titre de la barre d'application, libellés de navigation…) doivent
    // donc partir de la géométrie Material 3, sinon ils tombent à 14 sp
    // (titres de page trop petits en v2.0).
    final geometry = Typography.material2021(platform: TargetPlatform.android).englishLike;
    final sized = geometry.merge(base.textTheme);
    final textTheme = sized.copyWith(
      headlineMedium: sized.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
      headlineSmall: sized.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2),
      titleLarge: sized.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      titleMedium: sized.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: sized.bodyLarge?.copyWith(height: 1.5),
      bodyMedium: sized.bodyMedium?.copyWith(height: 1.45),
      labelLarge: sized.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    final radius = BorderRadius.circular(18);
    // Fond légèrement teinté (vert-gris très clair) : les cartes blanches
    // s'en détachent sans bordure ni ombre.
    final background = isDark ? const Color(0xFF111412) : const Color(0xFFF2F5F1);
    final cardColor = isDark ? scheme.surfaceContainer : Colors.white;
    final fieldColor = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final fieldBorder = BorderSide(color: scheme.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.7));

    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        toolbarHeight: 64,
        titleSpacing: 20,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(color: scheme.onSurface),
        systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: OutlineInputBorder(borderRadius: radius, borderSide: fieldBorder),
        enabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: fieldBorder),
        disabledBorder: OutlineInputBorder(borderRadius: radius, borderSide: fieldBorder),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        errorMaxLines: 3,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: radius),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: radius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: isDark ? scheme.surfaceContainer : Colors.white,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: 14,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        horizontalTitleGap: 16,
        iconColor: scheme.primary,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: isDark ? 0.5 : 0.45),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
