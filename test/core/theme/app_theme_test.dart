import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (light, dark) = la > lb ? (la, lb) : (lb, la);
  return (light + 0.05) / (dark + 0.05);
}

// 02-01 / RNF-20: el tema sale de la guia de estilo y todo texto cumple AA.
void main() {
  for (final (name, c) in [
    ('claro', MusubiColors.light),
    ('oscuro', MusubiColors.dark),
  ]) {
    group('contraste AA (>= 4.5:1) en modo $name', () {
      final pairs = <String, (Color, Color)>{
        'texto principal / fondo': (c.textPrimary, c.background),
        'texto secundario / fondo': (c.textSecondary, c.background),
        'texto secundario / superficie': (c.textSecondary, c.surface),
        'texto del boton / rojo Musubi': (c.onBrand, c.brand),
        'rojo de texto / fondo': (c.brandText, c.background),
        'error / fondo': (c.error, c.background),
        'error / fondo de error': (c.error, c.errorSoft),
        'exito / fondo de exito': (c.successText, c.successSoft),
        'advertencia / fondo de advertencia': (c.warningText, c.warningSoft),
      };
      for (final MapEntry(key: label, value: (fg, bg)) in pairs.entries) {
        test(label, () {
          expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: label);
        });
      }
    });
  }

  test('rojo Musubi y rojo oxido de error son distintos', () {
    expect(MusubiColors.light.brand, isNot(MusubiColors.light.error));
    expect(MusubiColors.light.brand, const Color(0xFFD7191F));
    expect(MusubiColors.light.error, const Color(0xFFC4320A));
  });

  test('tema: Plus Jakarta Sans, botones de 56 dp y campos con radio 14', () {
    final theme = AppTheme.light();

    expect(theme.textTheme.headlineLarge?.fontFamily, MusubiType.family);
    expect(theme.textTheme.headlineLarge?.fontSize, 28);
    expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w800);
    expect(
      theme.filledButtonTheme.style?.minimumSize?.resolve({})?.height,
      MusubiSizes.buttonHeight,
    );
    final border = theme.inputDecorationTheme.border! as OutlineInputBorder;
    expect(border.borderRadius, BorderRadius.circular(14));
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(theme.extension<MusubiColors>(), MusubiColors.light);
    expect(AppTheme.dark().extension<MusubiColors>(), MusubiColors.dark);
  });
}
