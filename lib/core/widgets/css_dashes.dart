import 'dart:ui';

/// Grosor con el que Chrome pinta `1.5px` en un telefono (3x): 4 px del
/// dispositivo.
const double cssDashThickness = 4 / 3;

/// Guion de `1.5px dashed` en Chrome a 3x: el doble del grosor (8 px).
const double cssDashLength = 8 / 3;

/// Hueco ideal entre guiones: igual al grosor (4 px).
const double cssDashGap = 4 / 3;

/// Inicio y fin de cada guion de una linea `1.5px dashed` entre [left] y
/// [right]. Como Chrome (`SelectBestDashGap`), ajusta el hueco para que la
/// linea empiece y termine con un guion completo; si no caben dos guiones,
/// es una linea continua.
List<(double, double)> cssDashSegments(double left, double right) {
  final length = right - left;
  if (length <= cssDashLength * 2) return [(left, right)];
  // El numero de guiones cuyo hueco queda mas cerca del ideal.
  final fewer = ((length + cssDashGap) / (cssDashLength + cssDashGap)).floor();
  final more = fewer + 1;
  final fewerGap = (length - fewer * cssDashLength) / (fewer - 1);
  final moreGap = (length - more * cssDashLength) / (more - 1);
  final useFewer =
      moreGap <= 0 ||
      (fewerGap - cssDashGap).abs() < (moreGap - cssDashGap).abs();
  final count = useFewer ? fewer : more;
  final step = cssDashLength + (useFewer ? fewerGap : moreGap);
  return [
    for (var i = 0; i < count; i++)
      (left + i * step, left + i * step + cssDashLength),
  ];
}

/// Pinta una linea `1.5px dashed` de la maqueta como la dibuja Chrome en un
/// telefono; [top] es su borde de arriba.
void paintCssDashedLine(
  Canvas canvas, {
  required double left,
  required double right,
  required double top,
  required Color color,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = cssDashThickness;
  const y = cssDashThickness / 2;
  for (final (start, end) in cssDashSegments(left, right)) {
    canvas.drawLine(Offset(start, top + y), Offset(end, top + y), paint);
  }
}
