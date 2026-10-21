import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// Lineamiento 11: la version de pubspec.yaml coincide con la ultima fila de
// la matriz de compatibilidad (docs/versionado.md, seccion 3).
void main() {
  final pubspecVersion = RegExp(
    r'^version:\s*(\S+)\s*$',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync())?.group(1);

  test('pubspec declara una version SemVer con versionCode', () {
    expect(pubspecVersion, matches(r'^\d+\.\d+\.\d+(-[0-9A-Za-z.]+)?\+\d+$'));
  });

  test('la version coincide con la ultima fila de la matriz', () {
    final lines = File('docs/versionado.md').readAsLinesSync();
    final start = lines.indexWhere((l) => l.startsWith('## 3.'));
    final dataRow = RegExp(r'^\| \d{2}-[A-Z][a-z]{2}-\d{4} \|');
    final rows = lines
        .skip(start + 1)
        .takeWhile((l) => !l.startsWith('## '))
        .where(dataRow.hasMatch)
        .toList();

    expect(rows, isNotEmpty);
    final appColumn = rows.last.split('|')[5].trim();
    expect(appColumn, pubspecVersion);
  });
}
