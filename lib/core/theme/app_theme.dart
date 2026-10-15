import 'package:flutter/material.dart';

/// Tema base de MUSUBI (Material 3). NOTE (02-01): paleta, tipografia y
/// componentes base definitivos; contraste AA verificado (RNF-20).
abstract final class AppTheme {
  static const _seed = Color(0xFF2E5AAC);

  static ThemeData light() => ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    useMaterial3: true,
  );

  static ThemeData dark() => ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
}
