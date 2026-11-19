// Guard de las pruebas de integracion de la app (02-10, SCRUM-120).
//
// Uso: dart run tool/check_integration_coverage.dart <musubi-api/docs/endpoints.md> <carpeta-de-cobertura>
//
// Cada fila del catalogo canonico cuyo consumidor es `musubi-app` tiene que
// haberse llamado en alguna prueba de test/integration (el arnes anota cada
// `VERBO /ruta` en un archivo por proceso dentro de la carpeta). Una ruta concreta cuenta para la plantilla
// mas especifica que la acepta (`/products/mine` no cubre `/products/{id}`).
// Las excepciones van en [waivers] con su motivo.
import 'dart:io';

/// Filas que la app consume pero que una prueba de integracion no puede
/// llamar, con su motivo. Agregar una es una decision de revision.
const waivers = <String, String>{
  'POST /api/v1/notifications/devices/remove':
      'Al cerrar sesion la app da de baja el telefono en FCM (ya sin sesion '
      'para llamar a la API); la API borra el token en el siguiente envio '
      '(HU-31).',
};

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'uso: dart run tool/check_integration_coverage.dart '
      '<endpoints.md> <carpeta-de-cobertura>',
    );
    exit(2);
  }
  final catalog = File(args[0]);
  final coverage = Directory(args[1]);
  if (!catalog.existsSync() || !coverage.existsSync()) {
    final absent = catalog.existsSync() ? args[1] : args[0];
    stdout.writeln('integration-coverage: FAIL (falta $absent)');
    exit(1);
  }

  final row = RegExp(
    r'^\|\s*(GET|POST|PUT|PATCH|DELETE|WS)\s*\|\s*(/[^\s|]*)\s*\|',
  );
  final consumed = <_Template>[];
  for (final line in catalog.readAsLinesSync()) {
    final match = row.firstMatch(line);
    if (match == null || !line.contains('musubi-app')) continue;
    consumed.add(_Template(match.group(1)!, match.group(2)!));
  }

  final hit = <String>{};
  final lines = [
    for (final file in coverage.listSync().whereType<File>())
      ...file.readAsLinesSync(),
  ];
  for (final line in lines) {
    final parts = line.trim().split(' ');
    if (parts.length != 2) continue;
    final candidates = consumed
        .where((t) => t.method == parts[0] && t.matches(parts[1]))
        .toList();
    if (candidates.isEmpty) continue;
    candidates.sort((a, b) => b.literals.compareTo(a.literals));
    hit.add(candidates.first.key);
  }

  final missing = [
    for (final t in consumed)
      if (!hit.contains(t.key) && !waivers.containsKey(t.key)) t.key,
  ];
  if (missing.isNotEmpty) {
    stdout.writeln(
      'integration-coverage: FAIL (${missing.length} de ${consumed.length} '
      'filas de musubi-app sin prueba de integracion)',
    );
    for (final key in missing) {
      stdout.writeln('  sin prueba: $key');
    }
    exit(1);
  }
  stdout.writeln(
    'integration-coverage: OK (${consumed.length - waivers.length} filas '
    'llamadas por test/integration, ${waivers.length} con excepcion documentada)',
  );
}

class _Template {
  new(this.method, String route)
    : path = route.split('?').first,
      key = '$method ${route.split('?').first}' {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    literals = segments.where((s) => !s.startsWith('{')).length;
    final pattern = segments
        .map((s) => s.startsWith('{') ? '[^/]+' : RegExp.escape(s))
        .join('/');
    _regex = RegExp('^/$pattern\$', caseSensitive: false);
  }

  final String method;
  final String path;
  final String key;
  late final int literals;
  late final RegExp _regex;

  bool matches(String concrete) => _regex.hasMatch(concrete.split('?').first);
}
