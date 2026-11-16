import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';

import '../../helpers/fake_admin.dart';
import '../profile/profile_flow_test.dart' show ProfileHarness;

/// HU-39 y HU-40: "Administración" desde `Ajustes`, solo con el rol `admin`.
void main() {
  Future<(ProfileHarness, FakeAdminRepository)> openAdmin(
    WidgetTester tester, {
    FakeAdminRepository? admin,
    String location = AppRoutes.settingsAdmin,
  }) async {
    final repository = admin ?? FakeAdminRepository();
    final h = ProfileHarness(
      tester,
      tokens: adminTokens(),
      overrides: [adminRepositoryProvider.overrideWithValue(repository)],
    );
    await h.open(location);
    return (h, repository);
  }

  testWidgets('Ajustes: sin el rol no hay "Administración"', (tester) async {
    await ProfileHarness(tester).open(AppRoutes.settings);

    expect(find.byKey(const Key('settings-admin')), findsNothing);
    expect(find.text('Administración'), findsNothing);
  });

  testWidgets('Ajustes: con el rol abre la bandeja de reportes abiertos', (
    tester,
  ) async {
    final (h, _) = await openAdmin(tester, location: AppRoutes.settings);

    await h.tapKey('settings-admin');

    expect(find.text('Abiertos'), findsOneWidget);
    expect(find.text('El producto no es como se describió'), findsOneWidget);
    expect(find.text('Publicación · Calculadora Casio fx-991'), findsOneWidget);
    expect(find.text('Problema general'), findsOneWidget);
  });

  testWidgets('"Retirar publicación" confirma, cierra el reporte y avisa', (
    tester,
  ) async {
    final (h, admin) = await openAdmin(tester);

    await h.tapKey('admin-report-r1');
    expect(find.text('Las fotos son de otra tienda.'), findsWidgets);
    expect(find.text('3 reportes procedentes'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('admin-note')),
      'Fotos de internet.',
    );
    await h.tapKey('admin-uphold');
    expect(find.text('¿Retirar la publicación?'), findsOneWidget);
    await h.tapKey('admin-remove-confirm');

    expect(admin.resolved.single, (
      'r1',
      ReportAction.uphold,
      'Fotos de internet.',
    ));
    expect(find.text('Retiramos la publicación'), findsOneWidget);
    expect(find.byKey(const Key('admin-report-r1')), findsNothing);

    await h.tapKey('admin-tab-closed');

    expect(find.byKey(const Key('admin-report-r1')), findsOneWidget);
    expect(find.text('Procedente'), findsOneWidget);
  });

  testWidgets('"Descartar" no pide confirmación y deja el contenido', (
    tester,
  ) async {
    final (h, admin) = await openAdmin(tester);

    await h.tapKey('admin-report-r2');
    expect(find.text('Marcar como atendido'), findsOneWidget);
    await h.tapKey('admin-dismiss');

    expect(admin.resolved.single.$2, ReportAction.dismiss);
    expect(find.text('Descartamos el reporte'), findsOneWidget);
  });

  testWidgets('si otro administrador ya lo revisó, la hoja lo dice', (
    tester,
  ) async {
    final admin = FakeAdminRepository()
      ..failResolve = const ApiFailure(
        code: 'admin.report_closed',
        message: 'Este reporte ya se revisó.',
      );
    final (h, _) = await openAdmin(tester, admin: admin);

    await h.tapKey('admin-report-r2');
    await h.tapKey('admin-dismiss');

    expect(find.text('Este reporte ya se revisó.'), findsOneWidget);
    expect(find.byKey(const Key('admin-report')), findsOneWidget);
  });

  testWidgets('la cuenta sugiere suspender; el motivo es obligatorio', (
    tester,
  ) async {
    final (h, admin) = await openAdmin(tester);

    await h.tapKey('admin-report-r1');
    await h.tapKey('admin-report-subject');

    expect(find.text('Luis Martínez'), findsOneWidget);
    expect(find.byKey(const Key('admin-suggestion')), findsOneWidget);
    expect(find.text('Reporte procedente'), findsOneWidget);

    await h.tapKey('admin-suspend');
    await h.tapKey('admin-suspend-submit');
    expect(find.text('Escribe el motivo de la suspensión.'), findsOneWidget);
    expect(admin.suspensions, isEmpty);

    await tester.enterText(
      find.byKey(const Key('admin-suspend-reason')),
      'Pidió pagos fuera de Musubi.',
    );
    await h.tapKey('admin-suspend-submit');

    expect(admin.suspensions.single, (
      'u-luis',
      'Pidió pagos fuera de Musubi.',
    ));
    expect(find.text('Suspendimos la cuenta'), findsOneWidget);
    expect(find.text('Suspendida'), findsOneWidget);
    expect(find.byKey(const Key('admin-reactivate')), findsOneWidget);
  });

  testWidgets('"Suspendidas" abre la cuenta y "Reactivar" confirma', (
    tester,
  ) async {
    final admin = FakeAdminRepository(
      accounts: {'u-luis': luisAccount(status: AccountStatus.suspended)},
    );
    final (h, _) = await openAdmin(tester, admin: admin);

    await h.tapKey('admin-tab-suspended');
    expect(find.text('Luis Martínez'), findsOneWidget);
    await h.tapKey('admin-suspended-u-luis');
    await h.tapKey('admin-reactivate');
    await h.tapKey('admin-reactivate-confirm');

    expect(admin.reactivations, ['u-luis']);
    expect(find.text('Reactivamos la cuenta'), findsOneWidget);
    expect(find.text('Activa'), findsOneWidget);
    expect(find.byKey(const Key('admin-suspend')), findsOneWidget);
  });

  testWidgets('sin reportes y sin red: vacío y "Reintentar"', (tester) async {
    final admin = FakeAdminRepository(open: [])..failLoad = true;
    final (h, _) = await openAdmin(tester, admin: admin);

    expect(find.text('Reintentar'), findsOneWidget);
    admin.failLoad = false;
    await h.tapText('Reintentar');

    expect(find.text('Sin reportes abiertos'), findsOneWidget);
  });
}
