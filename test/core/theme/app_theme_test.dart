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

  test('tema: Plus Jakarta Sans, sin ripple y los tokens de la maqueta', () {
    final theme = AppTheme.light();

    expect(theme.textTheme.headlineLarge?.fontFamily, MusubiType.family);
    expect(theme.textTheme.headlineLarge?.fontSize, 28);
    expect(theme.textTheme.headlineLarge?.fontWeight, FontWeight.w800);
    // La maqueta cambia el fondo al presionar; no hay onda de Material.
    expect(theme.splashFactory, NoSplash.splashFactory);
    expect(theme.materialTapTargetSize, MaterialTapTargetSize.padded);
    expect(theme.extension<MusubiColors>(), MusubiColors.light);
    expect(AppTheme.dark().extension<MusubiColors>(), MusubiColors.dark);
  });

  test('texto como en CSS: interlineado y espaciado explicitos', () {
    // Sin `line-height`: el `normal` de la fuente (1.26), no el del tema.
    final normal = MusubiType.style(13);
    expect(normal.height, MusubiType.normalLineHeight);
    expect(normal.leadingDistribution, TextLeadingDistribution.even);
    // Sin `letter-spacing`: 0 (si no, se hereda el 0.25 de Material).
    expect(normal.letterSpacing, 0);

    final title = MusubiType.style(28, line: 34, em: -0.025);
    expect(title.height, 34 / 28);
    expect(title.letterSpacing, closeTo(-0.7, 1e-9));
  });

  test('modo noche: el mapa de la maqueta (dc-meta.dark)', () {
    const dark = MusubiColors.dark;
    expect(dark.background, const Color(0xFF17171A));
    expect(dark.surface, const Color(0xFF232327));
    expect(dark.brandText, const Color(0xFFFF5C61));
    // Los rellenos rojos y el tinta del banner no cambian.
    expect(dark.brand, MusubiColors.light.brand);
    expect(dark.inverse, MusubiColors.light.inverse);
  });
}
