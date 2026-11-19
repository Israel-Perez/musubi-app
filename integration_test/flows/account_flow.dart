import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/token_store.dart';

import '../../test/helpers/in_memory_token_store.dart';
import '../../test/integration/support/live_api.dart';
import '../support/device_app.dart';

/// `Crear-cuenta`, `Verificacion`, `Verificacion-lista`, `Intereses`,
/// `Iniciar-sesion`, `Ajustes` (cerrar sesion) y `Privacidad` (eliminar la
/// cuenta) en el telefono (HU-01, HU-02, HU-03, HU-46, HU-66).
void accountFlow() {
  testWidgets('crear cuenta y verificar el correo con el codigo', (
    tester,
  ) async {
    final email = liveEmail('telefono');
    final app = await DeviceApp.open(tester, at: AppRoutes.signUp);

    await app.type('signup-email', email);
    await app.waitFor(find.byKey(const Key('campus-found')));
    await app.type('signup-name', liveName);
    await app.type('signup-password', livePassword);
    await app.tapKey('signup-consent');
    await app.tapText('Crear cuenta');
    await app.see('Revisa tu correo institucional');
    // El sexto digito verifica solo (maqueta `Verificacion`).
    await app.type('verification-code', await liveCodeFor(email));
    await app.seeContaining('Ya eres parte de Musubi');

    expect(app.session, isA<SignedIn>());
    await app.tapText('Empezar a explorar');
    await app.see('¿Qué te interesa?');
    await app.tapText('Ahora no');
    await app.waitForHome();
  });

  testWidgets('iniciar sesion, reabrir la app con la sesion y cerrarla', (
    tester,
  ) async {
    final ana = await liveUser();
    ana.dispose();
    // En el telefono, el almacen seguro real (Keystore), como en Play. En la
    // VM (el ensayo de test/integration) no hay Keystore: uno en memoria.
    final store = Platform.isAndroid
        ? SecureTokenStore()
        : InMemoryTokenStore();
    await store.clear();
    var app = await DeviceApp.open(tester, store: store, at: AppRoutes.signIn);

    await app.type('signin-email', ana.email);
    await app.type('signin-password', livePassword);
    await app.tapText('Iniciar sesión');
    await app.waitUntil(
      () => app.session is SignedIn,
      reason: 'el inicio de sesion',
    );

    // Cerrar la app sin "Cerrar sesion" y volver a abrirla: sigue la sesion.
    final saved = await store.read();
    expect(saved, isNotNull);
    app = await DeviceApp.open(tester, store: store, tokens: saved);
    expect(app.session, isA<SignedIn>());

    app.go(AppRoutes.settings);
    await app.tapText('Cerrar sesión');
    await app.tapKey('signout-confirm');
    await app.waitUntil(
      () => app.session is Visitor,
      reason: 'el cierre de sesion',
    );
    expect(await store.read(), isNull);
  });

  testWidgets('eliminar mi cuenta desde Privacidad', (tester) async {
    final ana = await liveUser();
    final tokens = ana.signedIn.tokens;
    ana.dispose();
    final app = await DeviceApp.open(
      tester,
      tokens: tokens,
      at: AppRoutes.settings,
    );

    await app.tapKey('settings-privacy');
    await app.tapKey('delete-account');
    await app.tapKey('delete-account-confirm');
    await app.type('delete-account-password', livePassword);
    await app.tapKey('delete-account-submit');

    await app.waitUntil(
      () => app.session is Visitor,
      reason: 'la cuenta eliminada',
    );
    await app.seeContaining('Eliminamos tu cuenta');
  });
}
