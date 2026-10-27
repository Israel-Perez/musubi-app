import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

/// Proporcion del simbolo (viewBox 64 x 40 de la guia de estilo).
const double _ringsAspect = 64 / 40;

/// Dos anillos entrelazados: quien busca y quien tiene. El rojo siempre va a
/// la izquierda (guia de estilo, "Logotipo"). Mismo trazo que el SVG de la
/// maqueta: anillos de radio 14 y trazo 6; dos arcos con un "hueco" de 11 del
/// color del fondo hacen el entrelazado.
class MusubiRings extends StatelessWidget {
  const new({
    this.height = 24,
    this.separation = 0,
    this.interlaced = true,
    this.onBrand = false,
    super.key,
  });

  /// Alto del simbolo; el ancho sale de la proporcion 64:40.
  final double height;

  /// Distancia extra entre los anillos (en unidades del viewBox); la usa el
  /// splash para "anudarlos".
  final double separation;

  /// Sin entrelazar, el anillo derecho queda encima (inicio del splash).
  final bool interlaced;

  /// Variante sobre rojo: los dos anillos en blanco.
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final c = context.musubi;
    final dark = c.background == MusubiColors.dark.background;
    final (left, right, gap) = onBrand
        ? (c.onBrand, c.onBrand, c.brand)
        : (
            c.brand,
            dark ? const Color(0xFFFFFFFF) : c.textPrimary,
            c.background,
          );
    return Semantics(
      label: 'Musubi',
      image: true,
      child: CustomPaint(
        size: Size(height * _ringsAspect, height),
        painter: MusubiRingsPainter(
          left: left,
          right: right,
          gap: gap,
          separation: separation,
          interlaced: interlaced,
        ),
      ),
    );
  }
}

/// Pinta el simbolo en cualquier tamano (lo usan el widget y las pruebas).
class MusubiRingsPainter extends CustomPainter {
  const new({
    required this.left,
    required this.right,
    required this.gap,
    this.separation = 0,
    this.interlaced = true,
  });

  final Color left;
  final Color right;
  final Color gap;
  final double separation;
  final bool interlaced;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / 40;
    canvas
      ..save()
      ..scale(scale);

    final half = separation / 2;
    final leftCenter = Offset(24 - half, 20);
    final rightCenter = Offset(40 + half, 20);

    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..isAntiAlias = true;

    canvas
      ..drawCircle(leftCenter, 14, stroke(left, 6))
      ..drawCircle(rightCenter, 14, stroke(right, 6));

    if (interlaced) {
      // Arco superior del anillo rojo por encima del oscuro (de -90 a -20
      // grados) e inferior del oscuro por encima del rojo (de 90 a 160): el
      // SVG de la guia (M24 6 A14 14 0 0 1 37.16 15.21). El arco de color se
      // alarga 4 grados por lado para tapar el borde del hueco: si terminan
      // juntos, el suavizado deja una costura clara.
      const sweep = 70 * math.pi / 180;
      const extra = 4 * math.pi / 180;
      Rect ring(Offset center) => Rect.fromCircle(center: center, radius: 14);
      void over(Offset center, double start, Color color) => canvas
        ..drawArc(ring(center), start, sweep, false, stroke(gap, 11))
        ..drawArc(
          ring(center),
          start - extra,
          sweep + 2 * extra,
          false,
          stroke(color, 6),
        );
      over(leftCenter, -math.pi / 2, left);
      over(rightCenter, math.pi / 2, right);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MusubiRingsPainter oldDelegate) =>
      oldDelegate.left != left ||
      oldDelegate.right != right ||
      oldDelegate.gap != gap ||
      oldDelegate.separation != separation ||
      oldDelegate.interlaced != interlaced;
}

/// Logotipo completo: simbolo + "Musubi" (encabezado de Inicio, splash).
class MusubiLogo extends StatelessWidget {
  const new({this.ringsHeight = 22, this.fontSize = 21, super.key});

  final double ringsHeight;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: fontSize * 8 / 21,
    children: [
      ExcludeSemantics(child: MusubiRings(height: ringsHeight)),
      Text(
        'Musubi',
        style: MusubiType.style(
          fontSize,
          weight: FontWeight.w800,
          em: -0.03,
          color: context.musubi.textPrimary,
        ),
      ),
    ],
  );
}
