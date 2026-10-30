import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/domain/account_repository.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/profile/presentation/privacy_screen.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../../helpers/fake_status_repository.dart';
import '../../../helpers/in_memory_token_store.dart';

/// Borra la cuenta si la contrasena es la de la prueba.
class FakeAccountRepository implements AccountRepository {
  static const password = 'musubi2026';

  final attempts = <String>[];

  @override
  Future<void> deleteAccount(String password) async {
    attempts.add(password);
    if (password != FakeAccountRepository.password) {
      throw const ApiFailure(
        code: 'auth.wrong_password',
        message: 'La contraseña no es correcta.',
        status: 400,
      );
    }
  }
}

// HU-46: maqueta Ajustes → Privacidad → "Eliminar mi cuenta", su dialogo y,
// como agregado de seguridad, la contrasena actual.
void main() {
  late FakeAccountRepository account;
  late InMemoryTokenStore store;
  late ProviderContainer container;

  Future<void> open(WidgetTester tester) async {
    account = FakeAccountRepository();
    store = InMemoryTokenStore(testTokens());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountRepositoryProvider.overrideWithValue(account),
          statusRepositoryProvider.overrideWithValue(
            FakeStatusRepository([const ApiOnline(version: 'v1')]),
          ),
          tokenStoreProvider.overrideWithValue(store),
          initialSessionTokensProvider.overrideWithValue(testTokens()),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    container.read(routerProvider).go(AppRoutes.settings);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tapText(tester, 'Privacidad');
    expect(find.text('Tu perfil solo lo ve tu campus'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('delete-account')));
    await tester.tap(find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar tu cuenta?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('delete-account-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Confirma tu contraseña'), findsOneWidget);
  }

  Future<void> submit(WidgetTester tester, String password) async {
    await tester.enterText(
      find.byKey(const Key('delete-account-password')),
      password,
    );
    await tester.tap(find.byKey(const Key('delete-account-submit')));
    await tester.pumpAndSettle();
  }

  String location() => container
      .read(routerProvider)
      .routerDelegate
      .currentConfiguration
      .uri
      .toString();

  testWidgets(
    'Ajustes lleva a Privacidad con el aviso y "Eliminar mi cuenta"',
    (tester) async {
      await open(tester);

      await tapText(tester, 'Privacidad');

      expect(find.byType(PrivacyScreen), findsOneWidget);
      expect(find.text('No vendemos tus datos.'), findsOneWidget);
      expect(find.text('Aviso de privacidad'), findsOneWidget);
      expect(find.text('Eliminar mi cuenta'), findsOneWidget);
    },
  );

  testWidgets('sin contrasena no llama a la API', (tester) async {
    await open(tester);
    await openSheet(tester);

    await submit(tester, '');

    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
    expect(account.attempts, isEmpty);
  });

  testWidgets('contrasena equivocada: lo dice y la sesion sigue', (
    tester,
  ) async {
    await open(tester);
    await openSheet(tester);

    await submit(tester, 'otra-clave-1');

    expect(find.text('La contraseña no es correcta.'), findsOneWidget);
    expect(container.read(sessionControllerProvider), isA<SignedIn>());
    expect(store.saved, isNotNull);
  });

  testWidgets('elimina la cuenta, borra la sesion y vuelve a Inicio', (
    tester,
  ) async {
    await open(tester);
    await openSheet(tester);

    await submit(tester, FakeAccountRepository.password);

    expect(account.attempts, [FakeAccountRepository.password]);
    expect(container.read(sessionControllerProvider), isA<Visitor>());
    expect(store.saved, isNull);
    expect(location(), AppRoutes.home);
    expect(find.text('Eliminamos tu cuenta y tus datos.'), findsOneWidget);
  });

  testWidgets('cancelar el dialogo no pide la contrasena', (tester) async {
    await open(tester);
    await tapText(tester, 'Privacidad');
    await tester.ensureVisible(find.byKey(const Key('delete-account')));
    await tester.tap(find.byKey(const Key('delete-account')));
    await tester.pumpAndSettle();

    await tapText(tester, 'Cancelar');

    expect(find.text('Confirma tu contraseña'), findsNothing);
    expect(container.read(sessionControllerProvider), isA<SignedIn>());
  });
}
