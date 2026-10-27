import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/svg_path.dart';

Rect bounds(String data) => parseSvgPathData(data).getBounds();

void expectRect(Rect actual, Rect expected) {
  for (final (a, e) in [
    (actual.left, expected.left),
    (actual.top, expected.top),
    (actual.right, expected.right),
    (actual.bottom, expected.bottom),
  ]) {
    expect(a, closeTo(e, 0.05), reason: '$actual != $expected');
  }
}

// SCRUM-82: los iconos de la maqueta (Lucide) se pintan desde su `d` de SVG.
void main() {
  test('lineas absolutas y relativas (la palomita)', () {
    expectRect(bounds('M20 6 9 17l-5-5'), const Rect.fromLTRB(4, 6, 20, 17));
  });

  test('pares implicitos tras M y H/V', () {
    expectRect(bounds('m2 2 3 0'), const Rect.fromLTRB(2, 2, 5, 2));
    expectRect(bounds('M2 2H10V8Z'), const Rect.fromLTRB(2, 2, 10, 8));
  });

  test('numeros compactos de Lucide: "1.5.5" y "-2-2"', () {
    expectRect(bounds('M1.5.5h1'), const Rect.fromLTRB(1.5, 0.5, 2.5, 0.5));
    expectRect(bounds('M10 10l-2-2'), const Rect.fromLTRB(8, 8, 10, 10));
  });

  test('arcos: un circulo de radio 10 con dos medios arcos', () {
    expectRect(
      bounds('M2 12a10 10 0 1 1 20 0a10 10 0 1 1-20 0'),
      const Rect.fromLTRB(2, 2, 22, 22),
    );
  });

  test('curvas cubicas con reflejo (S)', () {
    final rect = bounds('M0 0C0 10 10 10 10 0S20-10 20 0');
    expect(rect.left, 0);
    expect(rect.right, 20);
    expect(rect.top, lessThan(0));
    expect(rect.bottom, greaterThan(0));
  });

  test('un comando que no existe es un error, no un icono roto', () {
    expect(() => parseSvgPathData('M0 0X1 1'), throwsFormatException);
    expect(() => parseSvgPathData('0 0'), throwsFormatException);
  });

  // getBounds incluye los puntos de control de las curvas: margen de 2.
  test('todos los iconos de la maqueta caben en su cuadro de 24', () {
    final icons = [
      MusubiIcons.arrowRight,
      MusubiIcons.badgeCheck,
      MusubiIcons.bell,
      MusubiIcons.check,
      MusubiIcons.chevronLeft,
      MusubiIcons.eye,
      MusubiIcons.eyeOff,
      MusubiIcons.graduationCap,
      MusubiIcons.hand,
      MusubiIcons.heart,
      MusubiIcons.house,
      MusubiIcons.megaphone,
      MusubiIcons.messageCircle,
      MusubiIcons.plus,
      MusubiIcons.settings,
      MusubiIcons.shoppingBag,
      MusubiIcons.spinner,
      MusubiIcons.user,
      MusubiIcons.wifiOff,
    ];
    for (final icon in icons) {
      for (final shape in icon.shapes) {
        final rect = shape.build().getBounds();
        expect(rect.left, greaterThanOrEqualTo(-2));
        expect(rect.top, greaterThanOrEqualTo(-2));
        expect(rect.right, lessThanOrEqualTo(26));
        expect(rect.bottom, lessThanOrEqualTo(26));
      }
    }
  });
}
