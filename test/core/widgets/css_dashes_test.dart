import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/widgets/css_dashes.dart';

// SCRUM-82: la linea punteada del boleto "Se busca" con el patron que Chrome
// pinta en la maqueta (guion 8 px y hueco 4 px del dispositivo a 3x).
void main() {
  test('empieza y termina con un guion completo', () {
    final segments = cssDashSegments(-16, 286);

    expect(segments.first.$1, -16);
    expect(segments.last.$2, closeTo(286, 1e-9));
    for (final (start, end) in segments) {
      expect(end - start, closeTo(cssDashLength, 1e-9));
    }
  });

  test('el hueco se ajusta cerca del ideal (4/3)', () {
    final segments = cssDashSegments(0, 300);

    for (var i = 1; i < segments.length; i++) {
      final gap = segments[i].$1 - segments[i - 1].$2;
      expect(gap, closeTo(cssDashGap, cssDashGap / 2));
    }
  });

  test('si no caben dos guiones es una linea continua', () {
    expect(cssDashSegments(0, 5), [(0.0, 5.0)]);
  });
}
