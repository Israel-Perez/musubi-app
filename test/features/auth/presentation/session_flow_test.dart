import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../../helpers/fake_auth_repository.dart';
import '../../../helpers/fake_session_api.dart';
import '../../../helpers/fake_status_repository.dart';
import '../../../helpers/in_memory_token_store.dart';

/// App completa (router real con la guardia) para HU-02 y HU-56.
class Harness {
  new(this.tester);

  final WidgetTester tester;
  final repository = FakeAuthRepository();
  final sessionApi = FakeSessionApi();
  late final store = InMemoryTokenStore(initial);
  SessionTokens? initial;
  late ProviderContainer container;

  Future<void> open(String location) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          sessionApiProvider.overrideWithValue(sessionApi),
          clockProvider.overrideWithValue(() => repository.now),
          statusRepositoryProvider.overrideWithValue(
            FakeStatusRepository([const ApiOnline(version: 'v1')]),
          ),
          tokenStoreProvider.overrideWithValue(store),
          initialSessionTokensProvider.overrideWithValue(initial),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  Future<void> type(String key, String text) async {
    await tester.enterText(find.byKey(Key(key)), text);
    await tester.pump();
  }

  Future<void> tapText(String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> signIn(String email, String password) async {
    await type('signin-email', email);
    await type('signin-password', password);
    await tapText('Iniciar sesión');
  }

  String get location => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  bool get signedIn => container.read(sessionControllerProvider) is SignedIn;
}

// HU-02 / HU-56: maqueta Iniciar-sesion, Iniciar-sesion-error, Ajustes
// (cerrar sesion) y el flujo de recuperar la contrasena.
void main() {
  group('iniciar sesion', () {
    testWidgets('entra y vuelve a la seccion que pidio la sesion', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open(AppRoutes.profile);
      expect(find.text('Hola de nuevo'), findsOneWidget);

      await h.signIn(
        FakeAuthRepository.activeEmail,
        FakeAuthRepository.activePassword,
      );

      expect(h.signedIn, isTrue);
      expect(h.store.saved?.refreshToken, 'refresh');
      expect(h.location, AppRoutes.profile);
    });

    testWidgets('credenciales incorrectas: aviso de la maqueta, sin sesion', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open(AppRoutes.signIn);

      await h.signIn(FakeAuthRepository.activeEmail, 'otra2026clave');

      expect(find.text('No pudimos iniciar sesión'), findsOneWidget);
      expect(
        find.text('Revisa mayúsculas, minúsculas y números.'),
        findsOneWidget,
      );
      expect(h.signedIn, isFalse);
    });

    testWidgets('cuenta sin verificar: pide otro codigo y va a verificar', (
      tester,
    ) async {
      final h = Harness(tester);
      h.repository.pending.add('luis@uttt.edu.mx');
      await h.open(AppRoutes.signIn);

      await h.signIn('Luis@UTTT.edu.mx', FakeAuthRepository.activePassword);

      expect(h.repository.calls, contains('resend:luis@uttt.edu.mx'));
      expect(find.text('Revisa tu correo institucional'), findsOneWidget);
      expect(find.text('luis@uttt.edu.mx'), findsOneWidget);
      expect(h.signedIn, isFalse);
    });

    testWidgets('sin red: aviso claro y el formulario se conserva', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open(AppRoutes.signIn);
      h.repository.nextFailure = const ApiFailure(
        code: ApiFailure.networkOffline,
        message: 'Sin conexión. Revisa tu internet e inténtalo de nuevo.',
      );

      await h.signIn(
        FakeAuthRepository.activeEmail,
        FakeAuthRepository.activePassword,
      );

      expect(
        find.text('Sin conexión. Revisa tu internet e inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.text(FakeAuthRepository.activeEmail), findsOneWidget);
    });

    testWidgets('el boton se habilita solo con correo y contrasena', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open(AppRoutes.signIn);
      FilledButton primary() =>
          tester.widget<FilledButton>(find.byType(FilledButton).last);

      expect(primary().onPressed, isNull);
      await h.type('signin-email', FakeAuthRepository.activeEmail);
      expect(primary().onPressed, isNull);
      await h.type('signin-password', 'x');
      expect(primary().onPressed, isNotNull);
    });

    testWidgets('sin a donde volver, la X lleva a Inicio', (tester) async {
      final h = Harness(tester);
      await h.open(AppRoutes.signIn);

      await tester.tap(find.byTooltip('Seguir explorando'));
      await tester.pumpAndSettle();

      expect(h.location, AppRoutes.home);
    });
  });

  group('recuperar la contrasena', () {
    testWidgets('correo → codigo + contrasena nueva → entra con la nueva', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open(AppRoutes.signIn);
      await h.type('signin-email', FakeAuthRepository.activeEmail);

      await h.tapText('¿Olvidaste tu contraseña?');
      expect(find.text('Recupera tu cuenta'), findsOneWidget);
      // El correo ya escrito pasa a la recuperacion.
      expect(find.text(FakeAuthRepository.activeEmail), findsOneWidget);

      await h.tapText('Enviar código');
      expect(find.byKey(const Key('forgot-sent')), findsOneWidget);
      expect(find.byKey(const Key('forgot-countdown')), findsOneWidget);

      await h.type('forgot-code', FakeAuthRepository.validCode);
      await h.type('forgot-password', 'nueva2026clave');
      await h.tapText('Guardar contraseña');

      expect(find.text('Listo, tu contraseña cambió'), findsOneWidget);
      expect(
        h.repository.passwords[FakeAuthRepository.activeEmail],
        'nueva2026clave',
      );

      await h.type('signin-password', 'nueva2026clave');
      await h.tapText('Iniciar sesión');
      expect(h.signedIn, isTrue);
    });

    testWidgets('codigo incorrecto: error en el campo, nada cambia', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open(AppRoutes.forgotPassword);
      await h.type('forgot-email', FakeAuthRepository.activeEmail);
      await h.tapText('Enviar código');

      await h.type('forgot-code', '000000');
      await h.type('forgot-password', 'nueva2026clave');
      await h.tapText('Guardar contraseña');

      expect(
        find.text('El código no es válido o ya venció. Pide uno nuevo.'),
        findsOneWidget,
      );
      expect(
        h.repository.passwords[FakeAuthRepository.activeEmail],
        FakeAuthRepository.activePassword,
      );
    });

    testWidgets('contrasena debil: no se puede guardar', (tester) async {
      final h = Harness(tester);
      await h.open(AppRoutes.forgotPassword);
      await h.type('forgot-email', FakeAuthRepository.activeEmail);
      await h.tapText('Enviar código');

      await h.type('forgot-code', FakeAuthRepository.validCode);
      await h.type('forgot-password', 'corta');

      final save = tester.widget<FilledButton>(find.byType(FilledButton).last);
      expect(save.onPressed, isNull);
    });

    testWidgets('reenviar: disponible al terminar la cuenta regresiva', (
      tester,
    ) async {
      final h = Harness(tester);
      await h.open(AppRoutes.forgotPassword);
      await h.type('forgot-email', FakeAuthRepository.activeEmail);
      await h.tapText('Enviar código');
      expect(find.text('Reenviar código en 1:00'), findsOneWidget);

      h.repository.now = h.repository.now.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 1));
      await h.tapText('Reenviar código');

      expect(find.text('Te enviamos un código nuevo.'), findsOneWidget);
      expect(
        h.repository.calls.where((c) => c.startsWith('forgot:')),
        hasLength(2),
      );
    });

    testWidgets('cambiar correo vuelve al primer paso', (tester) async {
      final h = Harness(tester);
      await h.open(AppRoutes.forgotPassword);
      await h.type('forgot-email', FakeAuthRepository.activeEmail);
      await h.tapText('Enviar código');

      await h.tapText('Cambiar correo');

      expect(find.text('Recupera tu cuenta'), findsOneWidget);
    });
  });

  group('cerrar sesion', () {
    testWidgets('confirma, revoca en la API y vuelve a Inicio', (tester) async {
      final h = Harness(tester)..initial = testTokens();
      await h.open(AppRoutes.profile);

      await h.tapText('Cerrar sesión');
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('signout-confirm')));
      await tester.pumpAndSettle();

      expect(h.sessionApi.revoked, ['refresh-1']);
      expect(h.signedIn, isFalse);
      expect(h.store.saved, isNull);
      expect(h.location, AppRoutes.home);
      expect(find.text('Cerraste sesión. ¡Vuelve pronto!'), findsOneWidget);
    });

    testWidgets('cancelar no cierra la sesion', (tester) async {
      final h = Harness(tester)..initial = testTokens();
      await h.open(AppRoutes.profile);

      await h.tapText('Cerrar sesión');
      await h.tapText('Cancelar');

      expect(h.signedIn, isTrue);
      expect(h.sessionApi.revoked, isEmpty);
    });
  });
}
