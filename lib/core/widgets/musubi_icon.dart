import 'package:flutter/widgets.dart';
import 'package:musubi_app/core/widgets/svg_path.dart';

/// Figura de un icono en su cuadro de 24 x 24 (los elementos del SVG de
/// Lucide). Por defecto se dibuja con trazo; [fill] la rellena.
@immutable
sealed class IconShape {
  const new({this.fill = false});

  final bool fill;

  Path build();
}

/// `<path d="...">`.
final class IconPath extends IconShape {
  const new(this.data, {super.fill});

  final String data;

  @override
  Path build() => parseSvgPathData(data);
}

/// `<circle cx cy r>`.
final class IconCircle extends IconShape {
  const new(this.cx, this.cy, this.r, {super.fill});

  final double cx;
  final double cy;
  final double r;

  @override
  Path build() =>
      Path()..addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));
}

/// `<ellipse cx cy rx ry>`.
final class IconEllipse extends IconShape {
  const new(this.cx, this.cy, this.rx, this.ry, {super.fill});

  final double cx;
  final double cy;
  final double rx;
  final double ry;

  @override
  Path build() => Path()
    ..addOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2),
    );
}

/// `<rect x y width height rx>`.
final class IconRect extends IconShape {
  const new(
    this.x,
    this.y,
    this.width,
    this.height, {
    this.radius = 0,
    super.fill,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double radius;

  @override
  Path build() => Path()
    ..addRRect(
      RRect.fromRectXY(Rect.fromLTWH(x, y, width, height), radius, radius),
    );
}

/// Un icono de la maqueta (ver `MusubiIcons`).
@immutable
class MusubiIconData {
  const new(this.shapes);

  final List<IconShape> shapes;
}

/// Icono de linea de la maqueta: trazo redondeado de [strokeWidth] en el
/// cuadro de 24 (en la maqueta cada uso trae su grosor). El color sale del
/// [IconTheme] si no se indica, como `currentColor` en CSS.
class MusubiIcon extends StatelessWidget {
  const new(
    this.icon, {
    super.key,
    this.size = 24,
    this.color,
    this.fillColor,
    this.strokeWidth = 2,
    this.filled = false,
    this.semanticLabel,
  });

  final MusubiIconData icon;
  final double size;
  final Color? color;

  /// Color de las figuras rellenas (por defecto, [color]).
  final Color? fillColor;
  final double strokeWidth;

  /// Rellena tambien las figuras de trazo (corazon de "Guardado").
  final bool filled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final color =
        this.color ?? IconTheme.of(context).color ?? const Color(0xFF1C1C1E);
    final paint = SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: MusubiIconPainter(
          icon: icon,
          color: color,
          fillColor: fillColor ?? color,
          strokeWidth: strokeWidth,
          filled: filled,
        ),
      ),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: paint)
        : Semantics(
            label: semanticLabel,
            child: ExcludeSemantics(child: paint),
          );
  }
}

/// Pinta un [MusubiIconData] escalado al tamano disponible.
class MusubiIconPainter extends CustomPainter {
  const new({
    required this.icon,
    required this.color,
    required this.fillColor,
    required this.strokeWidth,
    this.filled = false,
  });

  final MusubiIconData icon;
  final Color color;
  final Color fillColor;
  final double strokeWidth;
  final bool filled;

  static final Expando<List<Path>> _paths = Expando('iconos');

  static List<Path> _built(MusubiIconData icon) =>
      _paths[icon] ??= [for (final shape in icon.shapes) shape.build()];

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas
      ..save()
      ..translate((size.width - 24 * scale) / 2, (size.height - 24 * scale) / 2)
      ..scale(scale);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final fill = Paint()..color = fillColor;
    final paths = _built(icon);
    for (var i = 0; i < paths.length; i++) {
      if (icon.shapes[i].fill) {
        canvas.drawPath(paths[i], fill);
      } else {
        if (filled) canvas.drawPath(paths[i], fill);
        canvas.drawPath(paths[i], stroke);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MusubiIconPainter oldDelegate) =>
      oldDelegate.icon != icon ||
      oldDelegate.color != color ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.filled != filled;
}
