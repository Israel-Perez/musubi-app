import 'dart:ui';

/// Convierte el atributo `d` de un `<path>` de SVG en un [Path]: comandos
/// M L H V C S Q T A Z, absolutos y relativos, con la sintaxis compacta de
/// Lucide (`1.5.5`, `-2-2`, banderas pegadas). Solo lee los iconos fijos del
/// codigo (`MusubiIcons`), nunca datos de la persona.
Path parseSvgPathData(String data) {
  final path = Path();
  final reader = _PathReader(data);
  var command = '';
  var previous = '';
  // Punto actual, inicio del subtrazo y ultimo punto de control (S y T).
  var x = 0.0;
  var y = 0.0;
  var startX = 0.0;
  var startY = 0.0;
  var controlX = 0.0;
  var controlY = 0.0;

  while (reader.skipSeparators()) {
    if (reader.atCommand) {
      command = reader.readCommand();
    } else if (command.isEmpty || command.toUpperCase() == 'Z') {
      throw FormatException('Falta el comando del trazo', data, reader.index);
    }
    final relative = command == command.toLowerCase();
    final dx = relative ? x : 0.0;
    final dy = relative ? y : 0.0;
    switch (command.toUpperCase()) {
      case 'M':
        x = reader.number() + dx;
        y = reader.number() + dy;
        path.moveTo(x, y);
        startX = x;
        startY = y;
        // Los pares que siguen a un M son lineas.
        command = relative ? 'l' : 'L';
      case 'L':
        x = reader.number() + dx;
        y = reader.number() + dy;
        path.lineTo(x, y);
      case 'H':
        x = reader.number() + dx;
        path.lineTo(x, y);
      case 'V':
        y = reader.number() + dy;
        path.lineTo(x, y);
      case 'C':
        final x1 = reader.number() + dx;
        final y1 = reader.number() + dy;
        controlX = reader.number() + dx;
        controlY = reader.number() + dy;
        x = reader.number() + dx;
        y = reader.number() + dy;
        path.cubicTo(x1, y1, controlX, controlY, x, y);
      case 'S':
        final reflect = previous == 'C' || previous == 'S';
        final x1 = reflect ? 2 * x - controlX : x;
        final y1 = reflect ? 2 * y - controlY : y;
        controlX = reader.number() + dx;
        controlY = reader.number() + dy;
        x = reader.number() + dx;
        y = reader.number() + dy;
        path.cubicTo(x1, y1, controlX, controlY, x, y);
      case 'Q':
        controlX = reader.number() + dx;
        controlY = reader.number() + dy;
        x = reader.number() + dx;
        y = reader.number() + dy;
        path.quadraticBezierTo(controlX, controlY, x, y);
      case 'T':
        final reflect = previous == 'Q' || previous == 'T';
        controlX = reflect ? 2 * x - controlX : x;
        controlY = reflect ? 2 * y - controlY : y;
        x = reader.number() + dx;
        y = reader.number() + dy;
        path.quadraticBezierTo(controlX, controlY, x, y);
      case 'A':
        final radiusX = reader.number();
        final radiusY = reader.number();
        final rotation = reader.number();
        final largeArc = reader.flag();
        final sweep = reader.flag();
        x = reader.number() + dx;
        y = reader.number() + dy;
        // En SVG la bandera de barrido 1 es el sentido de las manecillas.
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(radiusX, radiusY),
          rotation: rotation,
          largeArc: largeArc,
          clockwise: sweep,
        );
      case 'Z':
        path.close();
        x = startX;
        y = startY;
      default:
        throw FormatException('Comando no soportado: $command', data);
    }
    previous = command.toUpperCase();
  }
  return path;
}

class _PathReader {
  new(this.data);

  final String data;
  int index = 0;

  static const _commands = 'MmLlHhVvCcSsQqTtAaZz';
  static final _number = RegExp(r'[+-]?(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?');

  /// Salta espacios y comas; devuelve si queda algo por leer.
  bool skipSeparators() {
    while (index < data.length) {
      final char = data[index];
      if (char != ' ' && char != ',' && char != '\n' && char != '\t') {
        return true;
      }
      index++;
    }
    return false;
  }

  bool get atCommand => _commands.contains(data[index]);

  String readCommand() => data[index++];

  double number() {
    skipSeparators();
    final match = _number.matchAsPrefix(data, index);
    if (match == null) {
      throw FormatException('Se esperaba un numero', data, index);
    }
    index = match.end;
    return double.parse(match[0]!);
  }

  /// Bandera de un arco: un solo caracter `0` o `1` (puede venir pegada).
  bool flag() {
    skipSeparators();
    final char = index < data.length ? data[index] : '';
    if (char != '0' && char != '1') {
      throw FormatException('Se esperaba 0 o 1', data, index);
    }
    index++;
    return char == '1';
  }
}
