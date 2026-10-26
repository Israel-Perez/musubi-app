import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/widgets/musubi_logo.dart';

// SCRUM-81: logotipo de la guia de estilo (dos anillos, el rojo a la
// izquierda) en claro y oscuro.
void main() {
  Future<MusubiRingsPainter> painterIn(
    WidgetTester tester,
    ThemeData theme,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(body: Center(child: MusubiLogo())),
      ),
    );
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(MusubiRings),
        matching: find.byType(CustomPaint),
      ),
    );
    return paint.painter! as MusubiRingsPainter;
  }

  testWidgets('claro: anillo rojo y anillo tinta, hueco del fondo', (
    tester,
  ) async {
    final painter = await painterIn(tester, AppTheme.light());

    expect(painter.left, const Color(0xFFD7191F));
    expect(painter.right, const Color(0xFF1C1C1E));
    expect(painter.gap, const Color(0xFFFFFFFF));
    expect(find.text('Musubi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oscuro: el anillo derecho pasa a blanco', (tester) async {
    final painter = await painterIn(tester, AppTheme.dark());

    expect(painter.left, const Color(0xFFD7191F));
    expect(painter.right, const Color(0xFFFFFFFF));
    expect(painter.gap, const Color(0xFF17171A));
  });

  testWidgets('proporcion 64:40 del simbolo', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(body: Center(child: MusubiRings(height: 40))),
      ),
    );

    expect(tester.getSize(find.byType(MusubiRings)), const Size(64, 40));
  });

  test('repinta solo si cambia algo', () {
    const a = MusubiRingsPainter(
      left: Color(0xFFD7191F),
      right: Color(0xFF1C1C1E),
      gap: Color(0xFFFFFFFF),
    );
    const b = MusubiRingsPainter(
      left: Color(0xFFD7191F),
      right: Color(0xFF1C1C1E),
      gap: Color(0xFFFFFFFF),
      separation: 4,
    );

    expect(a.shouldRepaint(a), isFalse);
    expect(b.shouldRepaint(a), isTrue);
  });
}
