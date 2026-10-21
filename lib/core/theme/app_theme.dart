import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

/// Tema de MUSUBI construido desde la guia de estilo de la maqueta (02-01).
/// Los componentes leen los tokens con `context.musubi`.
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
      labelSmall: colored(MusubiType.overline, c.textSecondary),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MusubiSizes.radiusButton),
    );
    const buttonSize = Size(MusubiSizes.minTouch, MusubiSizes.buttonHeight);

    OutlineInputBorder fieldBorder(Color color, {double width = 1}) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(MusubiSizes.radiusField),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: MusubiType.family,
      textTheme: textTheme,
      scaffoldBackgroundColor: c.background,
      extensions: [c],
      // Area tactil minima de 44 dp aunque el elemento sea mas chico (RNF-27).
      materialTapTargetSize: MaterialTapTargetSize.padded,
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: colored(MusubiType.title2, c.textPrimary),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          disabledBackgroundColor: c.border,
          disabledForegroundColor: c.textSecondary,
          minimumSize: buttonSize,
          shape: buttonShape,
          textStyle: MusubiType.button,
        ).copyWith(overlayColor: WidgetStatePropertyAll(c.brandPressed)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          minimumSize: buttonSize,
          shape: buttonShape,
          side: BorderSide(color: c.border, width: 1.5),
          textStyle: MusubiType.button,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.brandText,
          minimumSize: const Size(MusubiSizes.minTouch, MusubiSizes.minTouch),
          textStyle: MusubiType.button.copyWith(fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.background,
        hintStyle: colored(MusubiType.field, c.textSecondary),
        helperStyle: colored(MusubiType.bodySmall, c.textSecondary),
        errorStyle: colored(MusubiType.bodySmall, c.error),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MusubiSizes.space4,
          vertical: MusubiSizes.space4,
        ),
        border: fieldBorder(c.border),
        enabledBorder: fieldBorder(c.border),
        focusedBorder: fieldBorder(c.brand, width: 2),
        errorBorder: fieldBorder(c.error),
        focusedErrorBorder: fieldBorder(c.error, width: 2),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.brand,
        selectionHandleColor: c.brand,
      ),
      dividerTheme: DividerThemeData(color: c.border, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: c.textPrimary,
        contentTextStyle: colored(MusubiType.bodySmall, c.background),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MusubiSizes.radiusThumb),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: c.brand),
    );
  }
}

/// Acceso corto a los tokens: `context.musubi.brand`.
extension MusubiThemeContext on BuildContext {
  MusubiColors get musubi =>
      Theme.of(this).extension<MusubiColors>() ?? MusubiColors.light;
}
