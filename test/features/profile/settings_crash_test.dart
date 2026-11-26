import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/observability/crash_reporter.dart';

import '../../helpers/fake_admin.dart';
import 'profile_flow_test.dart' show ProfileHarness;

/// SCRUM-108: "Enviar un error de prueba" en `Ajustes` → "Administración"
/// comprueba que Crashlytics recibe los errores de un build de release.
void main() {
  testWidgets('sin el rol no aparece', (tester) async {
    await ProfileHarness(tester).open(AppRoutes.settings);

    expect(find.byKey(const Key('settings-admin-crash-test')), findsNothing);
  });

  testWidgets('con Crashlytics apagado lo dice y no manda nada', (
    tester,
  ) async {
    final h = ProfileHarness(tester, tokens: adminTokens());
    await h.open(AppRoutes.settings);

    await h.tapKey('settings-admin-crash-test');

    expect(
      find.text(
        'Crashlytics está apagado en este build (solo release con Firebase).',
      ),
      findsOneWidget,
    );
  });

  testWidgets('encendido manda un error de prueba no fatal', (tester) async {
    final reporter = _Recording();
    final h = ProfileHarness(
      tester,
      tokens: adminTokens(),
      overrides: [crashReporterProvider.overrideWithValue(reporter)],
    );
    await h.open(AppRoutes.settings);

    await h.tapKey('settings-admin-crash-test');

    expect(
      find.text('Enviamos un error de prueba a Crashlytics.'),
      findsOneWidget,
    );
    final (error, fatal) = reporter.sent.single;
    expect((error.type, fatal), ('PruebaCrashlytics', false));
  });
}

class _Recording implements CrashReporter {
  final List<(ScrubbedError, bool)> sent = [];

  @override
  bool get active => true;

  @override
  Future<void> start() async {}

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async => sent.add((error as ScrubbedError, fatal));
}
