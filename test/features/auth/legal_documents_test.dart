import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// HU-47: el aviso (fuente unica para app y landing) conserva los elementos
// del aviso integral de la LFPDPPP y lo que piden RN-40 y RN-22.
void main() {
  final privacy = File('assets/legal/aviso-de-privacidad.md')
      .readAsStringSync();
  final terms = File('assets/legal/terminos-y-condiciones.md')
      .readAsStringSync();

  test('aviso: secciones del aviso integral (LFPDPPP)', () {
    for (final heading in [
      '## Quién es responsable de tus datos',
      '## Qué datos guardamos',
      '## Para qué los usamos',
      '## Con quién compartimos tus datos',
      '## Tus derechos (ARCO)',
      '## Cambios a este aviso',
    ]) {
      expect(privacy, contains(heading));
    }
    expect(privacy, contains('LFPDPPP'));
    expect(privacy, contains('Versión 2026-10'));
  });

  test('aviso: IA solo a petición (RN-40) y revisión de reportes (RN-22)', () {
    expect(privacy, contains('## Inteligencia artificial'));
    expect(privacy, contains('Solo cuando una de las personas'));
    expect(privacy, contains('## Moderación y reportes'));
    expect(privacy, contains('el equipo administrador puede revisar'));
  });

  test('aviso: coherente con D-01 (sin pagos ni tarjetas)', () {
    expect(privacy, contains('ni guardamos datos de tarjetas'));
    expect(terms, contains('no cobra comisión'));
  });

  test('el responsable es el equipo, no una persona', () {
    // Regla del repo publico: los nombres de las personas viven en Jira.
    expect(privacy, contains('Start-Up 10IDGS-G3'));
  });
}
