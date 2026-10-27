import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/core/theme/musubi_tokens.dart';
import 'package:musubi_app/core/widgets/feedback_views.dart';
import 'package:musubi_app/core/widgets/musubi_button.dart';
import 'package:musubi_app/core/widgets/musubi_controls.dart';
import 'package:musubi_app/core/widgets/musubi_dialog.dart';
import 'package:musubi_app/core/widgets/musubi_icon.dart';
import 'package:musubi_app/core/widgets/musubi_icons.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/core/widgets/musubi_text_field.dart';
import 'package:musubi_app/core/widgets/otp_field.dart';
import 'package:musubi_app/core/widgets/shake.dart';
import 'package:musubi_app/core/widgets/skeleton.dart';

Widget host(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light(),
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(20), child: child),
  ),
);

/// Color de fondo de la caja animada mas cercana a [finder].
Color? boxColor(WidgetTester tester, Finder finder) {
  final box = tester.widget<AnimatedContainer>(
    find.descendant(of: finder, matching: find.byType(AnimatedContainer)).first,
  );
  return (box.decoration! as BoxDecoration).color;
}

Finder icon(MusubiIconData data) =>
    find.byWidgetPredicate((w) => w is MusubiIcon && w.icon == data);

// SCRUM-82 / 02-01: componentes de la maqueta (RNF-18, RNF-20, RNF-27).
void main() {
  const light = MusubiColors.light;

  group('boton', () {
    testWidgets('cargando: no acepta toques, gira y dice "Entrando…"', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          MusubiButton(
            label: 'Iniciar sesión',
            loadingLabel: 'Entrando…',
            onPressed: () => taps++,
            loading: true,
          ),
        ),
      );

      await tester.tap(find.byType(MusubiButton));

      expect(taps, 0);
      expect(find.byType(MusubiSpinner), findsOneWidget);
      expect(find.text('Entrando…'), findsOneWidget);
      expect(find.bySemanticsLabel('Iniciar sesión, cargando'), findsOneWidget);
    });

    testWidgets('alturas de la maqueta: 56 en pantalla, 54 en hoja, 44 chico', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          Column(
            children: [
              MusubiButton(label: 'Pantalla', onPressed: () {}),
              MusubiButton(
                label: 'Hoja',
                height: MusubiSizes.buttonHeightSheet,
                onPressed: () {},
              ),
              MusubiButton(
                label: 'Chico',
                height: MusubiSizes.buttonHeightSmall,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      double height(String label) => tester
          .getSize(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(AnimatedContainer),
                )
                .first,
          )
          .height;
      expect(height('Pantalla'), 56);
      expect(height('Hoja'), 54);
      expect(height('Chico'), 44);
    });

    testWidgets('presionado: el rojo se oscurece y no hay ripple', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(MusubiButton(label: 'Crear cuenta', onPressed: () {})),
      );
      final button = find.byType(MusubiButton);

      expect(boxColor(tester, button), light.brand);
      final gesture = await tester.startGesture(tester.getCenter(button));
      await tester.pump(const Duration(milliseconds: 200));

      expect(boxColor(tester, button), light.brandPressed);
      expect(find.byType(InkWell), findsNothing);
      await gesture.up();
      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      expect(boxColor(tester, button), light.brand);
    });

    testWidgets('deshabilitado: gris y sin respuesta', (tester) async {
      await tester.pumpWidget(
        host(const MusubiButton(label: 'Crear cuenta', onPressed: null)),
      );

      expect(boxColor(tester, find.byType(MusubiButton)), light.border);
    });

    testWidgets('atenuado: se ve gris pero responde (Registro-error)', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(
        host(
          MusubiButton(
            label: 'Crear cuenta',
            dimmed: true,
            onPressed: () => taps++,
          ),
        ),
      );
      final button = find.byType(MusubiButton);

      expect(boxColor(tester, button), light.border);
      await tester.tap(button);
      await tester.pump(const Duration(milliseconds: 200));

      expect(taps, 1);
      expect(boxColor(tester, button), light.border);
    });
  });

  group('campo de texto', () {
    testWidgets('etiqueta, error con triangulo y ojo para la contraseña', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MusubiTextField(
            label: 'Contraseña',
            obscure: true,
            errorText: 'Revisa mayúsculas, minúsculas y números.',
          ),
        ),
      );

      expect(find.text('Contraseña'), findsOneWidget);
      expect(find.text('Revisa mayúsculas, minúsculas y números.'), findsOne);
      expect(icon(MusubiIcons.triangleAlert), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        true,
      );

      await tester.tap(find.bySemanticsLabel('Mostrar contraseña'));
      await tester.pump();

      expect(
        tester.widget<TextField>(find.byType(TextField)).obscureText,
        isFalse,
      );
      expect(find.bySemanticsLabel('Ocultar contraseña'), findsOneWidget);
    });

    testWidgets('con foco: borde rojo y halo de 4', (tester) async {
      await tester.pumpWidget(
        host(const MusubiTextField(label: 'Correo institucional')),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final decoration = box.decoration! as BoxDecoration;
      expect((decoration.border! as Border).top.color, light.brandBorder);
      expect(decoration.boxShadow!.single.spreadRadius, 4);
    });

    testWidgets('error vacio: borde rojo sin linea de aviso', (tester) async {
      await tester.pumpWidget(
        host(const MusubiTextField(label: 'Correo', errorText: '')),
      );

      expect(find.byType(FieldMessage), findsNothing);
      final box = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).first,
      );
      final border = (box.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, light.error);
    });
  });

  testWidgets('aviso de error: icono y texto, no solo color', (tester) async {
    await tester.pumpWidget(
      host(
        const InlineMessage(
          title: 'No pudimos iniciar sesión',
          message: 'El correo o la contraseña no coinciden.',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(icon(MusubiIcons.circleAlert), findsOneWidget);
    expect(find.text('No pudimos iniciar sesión'), findsOneWidget);
  });

  testWidgets('error con reintento', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      host(ErrorView(message: 'Sin conexión.', onRetry: () => retries++)),
    );

    await tester.tap(find.text('Reintentar'));

    expect(retries, 1);
  });

  testWidgets('sacudida: se mueve al cambiar el disparador y regresa', (
    tester,
  ) async {
    Widget shake(Object? trigger) =>
        host(Shake(trigger: trigger, child: const Text('Caja')));
    double dx() => tester
        .widget<Transform>(
          find
              .ancestor(of: find.text('Caja'), matching: find.byType(Transform))
              .first,
        )
        .transform
        .getTranslation()
        .x;

    await tester.pumpWidget(shake(null));
    await tester.pumpWidget(shake(Object()));
    await tester.pump(const Duration(milliseconds: 60));

    expect(dx(), isNot(0));
    await tester.pumpAndSettle();
    expect(dx(), 0);
  });

  testWidgets('codigo: seis cajas que entregan el codigo una sola vez', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final completed = <String>[];
    await tester.pumpWidget(
      host(
        OtpField(
          controller: controller,
          fieldKey: const Key('codigo'),
          onCompleted: completed.add,
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('codigo')), '48a2719');
    await tester.pump();
    controller.selection = const TextSelection.collapsed(offset: 2);
    await tester.pump();

    expect(controller.text, '482719');
    expect(completed, ['482719']);
    for (final digit in ['4', '8', '2', '7', '1', '9']) {
      expect(find.text(digit), findsOneWidget);
    }
  });

  testWidgets('dialogo: confirmar devuelve true; cancelar, false', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showMusubiDialog(
              context,
              icon: MusubiIcons.logOut,
              title: '¿Cerrar sesión?',
              message: 'Tus publicaciones se quedan guardadas.',
              confirmLabel: 'Cerrar sesión',
              danger: true,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('¿Cerrar sesión?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('aviso breve: texto e icono en su circulo', (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showMusubiSnack(
              ScaffoldMessenger.of(context),
              'Cerraste sesión. ¡Vuelve pronto!',
              icon: MusubiIcons.logOut,
              tone: SnackTone.info,
            ),
            child: const Text('avisar'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('avisar'));
    await tester.pumpAndSettle();

    expect(find.text('Cerraste sesión. ¡Vuelve pronto!'), findsOneWidget);
    expect(icon(MusubiIcons.logOut), findsOneWidget);
  });

  testWidgets('casilla e interruptor: cambian y lo anuncian', (tester) async {
    var checked = false;
    var toggled = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              MusubiCheckbox(
                value: checked,
                semanticLabel: 'Acepto',
                onChanged: (value) => setState(() => checked = value),
              ),
              MusubiSwitch(
                value: toggled,
                semanticLabel: 'Ocultar agotados',
                onChanged: (value) => setState(() => toggled = value),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.bySemanticsLabel('Acepto'));
    await tester.tap(find.bySemanticsLabel('Ocultar agotados'));
    await tester.pumpAndSettle();

    expect(checked, isTrue);
    expect(toggled, isTrue);
    expect(icon(MusubiIcons.check), findsOneWidget);
  });

  testWidgets('esqueleto: con "quitar animaciones" no brilla', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(
          const SkeletonShimmer(child: SkeletonBox(width: 100, height: 20)),
        ),
      ),
    );

    // Sin animacion pendiente: se asienta de inmediato.
    await tester.pumpAndSettle();
    expect(find.byType(SkeletonBox), findsOneWidget);
  });

  group('flotar (__fly de Verificacion)', () {
    double dy(WidgetTester tester) => tester
        .widget<Transform>(
          find.descendant(
            of: find.byType(FloatY),
            matching: find.byType(Transform),
          ),
        )
        .transform
        .getTranslation()
        .y;

    testWidgets('sube 3 px a media vuelta y termina quieto', (tester) async {
      await tester.pumpWidget(host(const FloatY(child: Text('sobre'))));

      await tester.pump(const Duration(milliseconds: 1300));
      expect(dy(tester), closeTo(-3, 0.01));

      await tester.pumpAndSettle();
      expect(dy(tester), closeTo(0, 0.01));
    });

    testWidgets('con "quitar animaciones" no se mueve', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: host(const FloatY(child: Text('sobre'))),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1300));
      expect(dy(tester), closeTo(0, 0.01));
    });
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
                kind: MusubiButtonKind.secondary,
              ),
              MusubiButton(
                label: 'Seguir explorando',
                height: MusubiSizes.buttonHeightSmall,
                onPressed: () {},
                kind: MusubiButtonKind.quiet,
              ),
              const InlineMessage(message: 'Revisa tu correo.'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(textContrastGuideline));
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      handle.dispose();
    });
  }
}
