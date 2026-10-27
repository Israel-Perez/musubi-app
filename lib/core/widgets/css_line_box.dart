import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';

/// Texto con `line-height: normal` de [fontSize] px: mide lo que le da
/// Chrome a cada linea ([MusubiType.normalLineBox]) y no el entero al que
/// Flutter redondea la linea (a 13 px, 16.333 y no 16; a 14 px, 17.667 y no
/// 18). Asi, en una columna (etiqueta → campo), lo que sigue queda donde en la
/// maqueta. [child] es el texto; se pinta igual, desde arriba.
class CssLineBox extends SingleChildRenderObjectWidget {
  const new({required this.fontSize, required Widget super.child, super.key});

  final double fontSize;

  (double, double) _lines(BuildContext context) {
    final size = MediaQuery.textScalerOf(context).scale(fontSize);
    return (
      (size * MusubiType.normalLineHeight).roundToDouble(),
      MusubiType.normalLineBox(size),
    );
  }

  @override
  RenderCssLineBox createRenderObject(BuildContext context) {
    final (flutterLine, cssLine) = _lines(context);
    return RenderCssLineBox(flutterLine: flutterLine, cssLine: cssLine);
  }

  @override
  void updateRenderObject(BuildContext context, RenderCssLineBox renderObject) {
    final (flutterLine, cssLine) = _lines(context);
    renderObject
      ..flutterLine = flutterLine
      ..cssLine = cssLine;
  }
}

/// Caja de [CssLineBox]: n lineas de Flutter → n lineas de Chrome.
class RenderCssLineBox extends RenderProxyBox {
  new({required this._flutterLine, required this._cssLine});

  /// Alto de una linea en Flutter (entero).
  double get flutterLine => _flutterLine;
  double _flutterLine;
  set flutterLine(double value) {
    if (value == _flutterLine) return;
    _flutterLine = value;
    markNeedsLayout();
  }

  /// Alto de una linea en Chrome.
  double get cssLine => _cssLine;
  double _cssLine;
  set cssLine(double value) {
    if (value == _cssLine) return;
    _cssLine = value;
    markNeedsLayout();
  }

  /// El alto de Chrome para las lineas que ocupa el texto.
  double _cssHeight(double flutterHeight) =>
      math.max(1, (flutterHeight / _flutterLine).round()) * _cssLine;

  @override
  void performLayout() {
    final child = this.child!
      ..layout(constraints.loosen(), parentUsesSize: true);
    size = constraints.constrain(
      Size(child.size.width, _cssHeight(child.size.height)),
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child!.getDryLayout(constraints.loosen());
    return constraints.constrain(Size(child.width, _cssHeight(child.height)));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _cssHeight(super.computeMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _cssHeight(super.computeMaxIntrinsicHeight(width));
}
