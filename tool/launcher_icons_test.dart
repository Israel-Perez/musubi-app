// Genera los PNG del icono para Android 7 (mipmap-*dpi/ic_launcher.png) con
// el mismo pintor del logotipo que usa la app (SCRUM-81). Android 8+ usa el
// icono adaptable vectorial (mipmap-anydpi-v26).
//
// No corre con `flutter test` (vive en tool/). Para regenerarlos:
//   flutter test tool/launcher_icons_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/widgets/musubi_logo.dart';

/// Densidad -> lado del icono en pixeles (48 dp).
const _sizes = {
  'mdpi': 48,
  'hdpi': 72,
  'xhdpi': 96,
  'xxhdpi': 144,
  'xxxhdpi': 192,
};

Future<List<int>> _render(int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = size.toDouble();

  // Cuadro blanco con esquinas redondeadas (forma clasica de Android 7).
  final radius = Radius.circular(side * 0.22);
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, side, side), radius),
    Paint()..color = const Color(0xFFFFFFFF),
  );

  // Anillos al 70 % del ancho, centrados (proporcion 64:40).
  final width = side * 0.7;
  final height = width * 40 / 64;
  canvas
    ..save()
    ..translate((side - width) / 2, (side - height) / 2);
  const MusubiRingsPainter(
    left: Color(0xFFD7191F),
    right: Color(0xFF1C1C1E),
    gap: Color(0xFFFFFFFF),
  ).paint(canvas, Size(width, height));
  canvas.restore();

  final image = await recorder.endRecording().toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  testWidgets('genera ic_launcher.png por densidad', (tester) async {
    await tester.runAsync(() async {
      for (final MapEntry(key: density, value: size) in _sizes.entries) {
        final file = File(
          'android/app/src/main/res/mipmap-$density/ic_launcher.png',
        );
        await file.writeAsBytes(await _render(size));
      }
    });
  });
}
