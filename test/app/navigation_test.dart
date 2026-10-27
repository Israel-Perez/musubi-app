import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/shell/musubi_bottom_bar.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../helpers/fake_status_repository.dart';
import '../helpers/in_memory_token_store.dart';

// 02-01: barra de 5 pestanas de la maqueta y guardia de sesion.
void main() {
  group('sessionRedirect', () {
    test('el visitante va a iniciar sesion desde una seccion protegida', () {
      for (final path in AppRoutes.requiresSession) {
        expect(
          sessionRedirect(signedIn: false, location: Uri.parse(path)),
          '/iniciar-sesion?desde=${Uri.encodeQueryComponent(path)}',
        );
      }
    });

    test('el visitante explora Inicio y Se busca sin cuenta', () {
      expect(
        sessionRedirect(signedIn: false, location: Uri.parse('/')),
        isNull,
      );
      expect(
        sessionRedirect(signedIn: false, location: Uri.parse('/se-busca')),
        isNull,
      );
    });

    test('con sesion no vuelve a las pantallas de visitante', () {
      expect(
        sessionRedirect(
          signedIn: true,
          location: Uri.parse('/iniciar-sesion?desde=/perfil'),
        ),
        '/perfil',
      );
    });

    test('el regreso solo acepta rutas internas conocidas', () {
      expect(AppRoutes.safeReturn('https://evil.example'), '/');
      expect(AppRoutes.safeReturn('//evil.example'), '/');
      expect(AppRoutes.safeReturn('/mensajes'), '/mensajes');
      expect(AppRoutes.safeReturn(null), '/');
    });
  });

  group('barra inferior', () {
    Future<void> pumpApp(WidgetTester tester, {SessionTokens? tokens}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            statusRepositoryProvider.overrideWithValue(
              FakeStatusRepository([const ApiOnline(version: 'v1')]),
            ),
            tokenStoreProvider.overrideWithValue(InMemoryTokenStore(tokens)),
            initialSessionTokensProvider.overrideWithValue(tokens),
          ],
          child: const MusubiApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    // La pestana de la barra (Inicio tambien tiene una seccion "Se busca").
    Finder tab(String label) => find.descendant(
      of: find.byType(MusubiBottomBar),
      matching: find.bySemanticsLabel(label),
    );

    testWidgets('muestra las 5 opciones de la maqueta', (tester) async {
      await pumpApp(tester);

      for (final label in ['Inicio', 'Se busca', 'Mensajes', 'Perfil']) {
        expect(tab(label), findsOneWidget);
      }
      expect(tab('Publicar'), findsOneWidget);
      // Maqueta: el boton central lleva su etiqueta debajo.
      expect(find.text('Publicar'), findsOneWidget);
    });

    testWidgets('el visitante explora Se busca', (tester) async {
      await pumpApp(tester);

      await tester.tap(tab('Se busca'));
      await tester.pumpAndSettle();

      expect(
        find.text('Aquí verás lo que buscan en tu campus.'),
        findsOneWidget,
      );
      expect(find.text('Muy pronto'), findsOneWidget);
    });

    testWidgets('el visitante que toca Perfil ve "Crea tu perfil" (HU-48)', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(tab('Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Crea tu perfil'), findsOneWidget);
      expect(find.text('Entra con tu correo institucional.'), findsNothing);
    });

    testWidgets('un enlace directo a Perfil sin sesion va a iniciar sesion', (
      tester,
    ) async {
      await pumpApp(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MusubiApp)),
      );

      container.read(routerProvider).go(AppRoutes.profile);
      await tester.pumpAndSettle();

      expect(find.text('Entra con tu correo institucional.'), findsOneWidget);
    });

    testWidgets('con sesion entra a Perfil', (tester) async {
      await pumpApp(tester, tokens: testTokens());

      await tester.tap(tab('Perfil'));
      await tester.pumpAndSettle();

      expect(find.text('Perfil'), findsWidgets);
      expect(find.text('Verificada'), findsOneWidget);
      expect(find.byKey(const Key('profile-settings')), findsOneWidget);
    });

    testWidgets('al cerrar sesion la guardia saca de Perfil', (tester) async {
      await pumpApp(tester, tokens: testTokens());
      await tester.tap(tab('Perfil'));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(Scaffold).first),
      );
      await container.read(sessionControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();

      expect(find.text('Entra con tu correo institucional.'), findsOneWidget);
    });
  });
}
