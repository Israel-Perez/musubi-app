import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/session/session_controller.dart';

import '../support/device_app.dart';

/// `Inicio` como visitante y "Entrar" (HU-48).
void startFlow() {
  testWidgets('la app abre como visitante y carga Inicio desde la API', (
    tester,
  ) async {
    final app = await DeviceApp.open(tester);

    expect(app.session, isA<Visitor>());
    await app.waitForHome();

    // "Entrar" lleva a `Iniciar-sesion`.
    await app.tapKey('home-enter');
    await app.waitFor(find.byKey(const Key('signin-email')));
  });
}
