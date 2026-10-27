import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

/// Tema de MUSUBI construido desde la maqueta (02-01). Los componentes de
/// `core/widgets` leen los tokens con `context.musubi`; el tema de Material
/// queda para lo que la app no dibuja (licencias, selector de texto).
abstract final class AppTheme {
  static ThemeData light() => _build(MusubiColors.light, Brightness.light);

  static ThemeData dark() => _build(MusubiColors.dark, Brightness.dark);

  static ThemeData _build(MusubiColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      primaryContainer: c.brandSoft,
      onPrimaryContainer: c.textPrimary,
      secondary: c.textPrimary,
      onSecondary: c.background,
      error: c.error,
      onError: c.onBrand,
      errorContainer: c.errorSoft,
      onErrorContainer: c.error,
      surface: c.background,
      onSurface: c.textPrimary,
      onSurfaceVariant: c.textSecondary,
      surfaceContainerHighest: c.surface,
      outline: c.border,
      outlineVariant: c.border,
    );

    TextStyle colored(TextStyle style, Color color) =>
        style.copyWith(color: color);

    final textTheme = TextTheme(
      headlineLarge: colored(MusubiType.display, c.textPrimary),
      headlineMedium: colored(MusubiType.title1, c.textPrimary),
      titleLarge: colored(MusubiType.title2, c.textPrimary),
      titleMedium: colored(MusubiType.title3, c.textPrimary),
      bodyLarge: colored(MusubiType.body, c.textPrimary),
      bodyMedium: colored(MusubiType.bodySmall, c.textSecondary),
      labelLarge: colored(MusubiType.button, c.textPrimary),
      labelMedium: colored(MusubiType.label, c.textPrimary),
      labelSmall: colored(MusubiType.eyebrow, c.textSecondary),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: MusubiType.family,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      // La maqueta no tiene ripple: cada componente cambia su fondo al
      // presionar (`Pressable`).
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      // Area tactil minima de 44 dp aunque el elemento sea mas chico (RNF-27).
      materialTapTargetSize: MaterialTapTargetSize.padded,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: MusubiPageTransitionsBuilder(),
          TargetPlatform.iOS: MusubiPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: colored(MusubiType.title2, c.textPrimary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brandText,
          textStyle: MusubiType.button.copyWith(fontSize: 15),
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.brand,
        selectionColor: c.brandSoft,
        selectionHandleColor: c.brand,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(color: c.divider, thickness: 1),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.brand),
    );
  }
}

/// Transicion de pantallas de la maqueta (`aNavF`, 0.3 s): la nueva entra 40
/// px desde la derecha mientras pasa de 0.35 a opaca.
class MusubiPageTransitionsBuilder extends PageTransitionsBuilder {
  const new();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.2, 0.8, 0.2, 1),
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(curved),
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) => Transform.translate(
          offset: Offset(40 * (1 - curved.value), 0),
          child: child,
        ),
        child: child,
      ),
    );
  }
}

/// Acceso corto a los tokens: `context.musubi.brand`.
extension MusubiThemeContext on BuildContext {
  MusubiColors get musubi =>
      Theme.of(this).extension<MusubiColors>() ?? MusubiColors.light;
}
