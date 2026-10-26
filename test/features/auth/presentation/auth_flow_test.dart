import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_status_repository.dart';
import '../../../helpers/in_memory_token_store.dart';

/// App completa (router real con la guardia) abierta en "Crea tu cuenta".
class Harness {
  new(this.tester);

  final WidgetTester tester;
  final repository = FakeAuthRepository();
  final store = InMemoryTokenStore();
  late DateTime now = repository.now;
  late ProviderContainer container;

  Future<void> open() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          clockProvider.overrideWithValue(() => now),
          statusRepositoryProvider.overrideWithValue(
            FakeStatusRepository([const ApiOnline(version: 'v1')]),
          ),
          tokenStoreProvider.overrideWithValue(store),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    container.read(routerProvider).go(AppRoutes.signUp);
    await tester.pumpAndSettle();
  }

  Future<void> type(String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> fillSignUp({
    String email = 'ana.ramirez@uttt.edu.mx',
    bool consent = true,
  }) async {
    await type('signup-email', email);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await type('signup-name', 'Ana Sofía Ramírez');
    await type('signup-password', 'musubi2026');
    if (consent) {
      await tester.ensureVisible(find.byKey(const Key('signup-consent')));
      await tester.tap(find.byKey(const Key('signup-consent')));
      await tester.pump();
    }
  }

  Future<void> tapText(String text) async {
    await tester.ensureVisible(find.text(text));
    await tester.tap(find.text(text));
    await tester.pumpAndSettle();
  }

  FilledButton get primary =>
      tester.widget<FilledButton>(find.byType(FilledButton).last);
}

// HU-01 / HU-03 / HU-47: flujo de la maqueta Registro → Verificacion →
// Verificacion-lista.
void main() {
  testWidgets('el campus se detecta mientras se escribe el correo', (
    tester,
  ) async {
    final h = Harness(tester);
    await h.open();

    await h.type('signup-email', 'ana.ramirez@uttt.edu.mx');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campus-found')), findsOneWidget);
    expect(find.text('Campus detectado: UTTT'), findsOneWidget);
  });

  testWidgets('un correo personal muestra el error de la maqueta', (
    tester,
  ) async {
    final h = Harness(tester);
    await h.open();

    await h.type('signup-email', 'ana.ramirez@gmail.com');
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('campus-rejected')), findsOneWidget);
    expect(find.text('Este correo no es de tu universidad'), findsWidgets);
  });

  testWidgets('las reglas de la contraseña se marcan al escribir', (
    tester,
  ) async {
    final h = Harness(tester);
    await h.open();

    await h.type('signup-password', 'abcdefgh');
    expect(find.byIcon(Icons.check_circle), findsOneWidget);

    await h.type('signup-password', 'abcdefg1');
    expect(find.byIcon(Icons.check_circle), findsNWidgets(2));
  });

  testWidgets('sin aceptar el aviso y los términos no se puede crear', (
    tester,
  ) async {
    final h = Harness(tester);
    await h.open();

    await h.fillSignUp(consent: false);

    expect(h.primary.onPressed, isNull);
    expect(h.repository.calls.where((c) => c.startsWith('register')), isEmpty);
  });

  testWidgets('los enlaces abren el aviso de privacidad', (tester) async {
    final h = Harness(tester);
    await h.open();

    await tester.ensureVisible(find.byKey(const Key('signup-consent')));
    await tester.tapOnText(find.textRange.ofSubstring('Aviso de privacidad'));
    await tester.pumpAndSettle();

    expect(find.text('Qué no hacemos'), findsOneWidget);
    expect(find.byKey(const Key('privacy-campus-only')), findsOneWidget);
  });

  testWidgets('registro → verificación → bienvenida con sesión', (
    tester,
  ) async {
    final h = Harness(tester);
    await h.open();

    await h.fillSignUp();
    await h.tapText('Crear cuenta');

    expect(
      h.repository.calls,
      contains('register:ana.ramirez@uttt.edu.mx:true:true'),
    );
    expect(find.text('Revisa tu correo institucional'), findsOneWidget);
    expect(find.text('ana.ramirez@uttt.edu.mx'), findsOneWidget);
    expect(find.text('Reenviar código en 1:00'), findsOneWidget);

    await h.type('verification-code', FakeAuthRepository.validCode);
    await h.tapText('Verificar correo');

    expect(find.text('¡Listo, Ana! Ya eres parte de Musubi'), findsOneWidget);
    expect(find.text('Campus UTTT'), findsOneWidget);
    expect(h.container.read(sessionControllerProvider), isA<SignedIn>());
    expect(h.store.saved?.refreshToken, 'refresh');

    await h.tapText('Empezar a explorar');
    expect(find.text('Musubi'), findsOneWidget);
  });

  testWidgets('código incorrecto: error en el campo y sin sesión', (
    tester,
  ) async {
    final h = Harness(tester);
    await h.open();
    await h.fillSignUp();
    await h.tapText('Crear cuenta');

    await h.type('verification-code', '000000');
    await h.tapText('Verificar correo');

    expect(
      find.text('El código no es válido o ya venció. Pide uno nuevo.'),
      findsOneWidget,
    );
    expect(h.container.read(sessionControllerProvider), isA<Visitor>());
  });

  testWidgets('reenviar: disponible al terminar la cuenta regresiva', (
    tester,
  ) async {
    final h = Harness(tester);
    await h.open();
    await h.fillSignUp();
    await h.tapText('Crear cuenta');

    h.now = h.now.add(const Duration(seconds: 61));
    await tester.pump(const Duration(seconds: 1));
    await h.tapText('Reenviar código');

    expect(h.repository.calls, contains('resend:ana.ramirez@uttt.edu.mx'));
    expect(find.text('Te enviamos un código nuevo.'), findsOneWidget);
  });

  testWidgets('correo ya registrado: aviso con "Iniciar sesión"', (
    tester,
  ) async {
    final h = Harness(tester);
    h.repository.registered.add('ana.ramirez@uttt.edu.mx');
    await h.open();

    await h.fillSignUp();
    await h.tapText('Crear cuenta');

    expect(
      find.text('Ese correo ya tiene una cuenta. Inicia sesión.'),
      findsOneWidget,
    );
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });

  testWidgets('sin red: aviso claro y el formulario se conserva', (
    tester,
  ) async {
    final h = Harness(tester);
    await h.open();
    await h.fillSignUp();
    h.repository.nextFailure = const ApiFailure(
      code: ApiFailure.networkOffline,
      message: 'No hay conexión con el servidor.',
    );

    await h.tapText('Crear cuenta');

    expect(find.text('No hay conexión con el servidor.'), findsOneWidget);
    expect(find.text('ana.ramirez@uttt.edu.mx'), findsOneWidget);
  });

  testWidgets('con sesión, registro redirige a Inicio', (tester) async {
    final h = Harness(tester);
    await h.open();

    await h.container
        .read(sessionControllerProvider.notifier)
        .signIn(testTokens());
    await tester.pumpAndSettle();

    expect(find.text('Crea tu cuenta'), findsNothing);
  });
}
