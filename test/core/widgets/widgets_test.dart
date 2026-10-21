import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';

Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);

// 02-01: componentes base de la guia de estilo (RNF-18, RNF-20, RNF-27).
void main() {
  testWidgets('boton cargando: deshabilitado y anunciado', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(
        MusubiButton(
          label: 'Crear cuenta',
          onPressed: () => taps++,
          loading: true,
        ),
      ),
    );

    await tester.tap(find.byType(FilledButton));

    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel('Crear cuenta, cargando'), findsOneWidget);
  });

  testWidgets('boton primario: 56 dp de alto', (tester) async {
    await tester.pumpWidget(
      host(MusubiButton(label: 'Comprar', onPressed: () {})),
    );

    expect(tester.getSize(find.byType(FilledButton)).height, 56);
  });

  testWidgets('campo: etiqueta visible, error de la API y ver contraseña', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const MusubiTextField(
          label: 'Contraseña',
          obscure: true,
          errorText: 'La contraseña debe tener al menos 8 caracteres.',
        ),
      ),
    );

    expect(find.text('Contraseña'), findsOneWidget);
    expect(
      find.text('La contraseña debe tener al menos 8 caracteres.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );

    await tester.tap(find.byTooltip('Mostrar contraseña'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
  });

  testWidgets('aviso de error: icono y texto, no solo color', (tester) async {
    await tester.pumpWidget(
      host(const InlineMessage(message: 'No pudimos iniciar sesión.')),
    );

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('No pudimos iniciar sesión.'), findsOneWidget);
  });

  testWidgets('error con reintento', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      host(ErrorView(message: 'Sin conexión.', onRetry: () => retries++)),
    );

    await tester.tap(find.text('Reintentar'));

    expect(retries, 1);
  });

  for (final (mode, theme) in [
    ('claro', AppTheme.light()),
    ('oscuro', AppTheme.dark()),
  ]) {
    testWidgets('accesibilidad en modo $mode: contraste y area tactil', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(
          theme: theme,
          ListView(
            children: [
              const MusubiTextField(label: 'Correo institucional'),
              const SizedBox(height: 16),
              MusubiButton(label: 'Crear cuenta', onPressed: () {}),
              MusubiButton(
                label: 'Ya tengo cuenta',
                onPressed: () {},
                kind: MusubiButtonKind.text,
              ),
              const InlineMessage(message: 'Revisa tu correo.'),
            ],
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  }
}
