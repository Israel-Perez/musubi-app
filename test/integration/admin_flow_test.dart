@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/admin/presentation/admin_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

import 'support/live_api.dart';

/// Pantallas `Administracion`, la hoja del reporte, `Cuenta-admin` y
/// `Categorias` contra la API real (HU-39, HU-40, HU-41), con lo que la
/// suspension le hace a la sesion abierta de esa persona (02-10).
///
/// Es el unico archivo que usa la cuenta `admin` (las pruebas corren en
/// paralelo y la cuenta se crea una sola vez).
void main() {
  group('Administracion contra la API real', skip: liveSkip, () {
    late LiveSession admin;

    setUpAll(() async => admin = await liveAdmin());
    tearDownAll(() => admin.dispose());

    test('revisar un reporte y descartarlo', () async {
      final ana = await liveUser();
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(ana.dispose);
      addTearDown(valeria.dispose);
      await ana
          .read(reputationRepositoryProvider)
          .report(
            UserReport(userId: valeria.user.id),
            ReportReason.noShow,
            details: 'No llegó a la entrega.',
          );
      final reports = admin.read(adminRepositoryProvider);

      final open = await reports.reports(open: true);
      final mine = open.firstWhere((r) => r.reporter?.id == ana.user.id);
      final resolved = await reports.resolve(
        mine.id,
        ReportAction.dismiss,
        note: 'Sin pruebas.',
      );
      final closed = await reports.reports(open: false);

      expect(resolved.status, isNot(ReportStatus.open));
      expect(closed.map((r) => r.id), contains(mine.id));
    });

    test('suspender corta la sesion abierta; reactivar la devuelve', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      addTearDown(valeria.dispose);
      final accounts = admin.read(adminRepositoryProvider);
      expect(
        (await valeria.read(profileRepositoryProvider).me()).id,
        valeria.user.id,
      );

      final suspended = await accounts.suspend(
        valeria.user.id,
        'Pidió pagos fuera de Musubi.',
      );
      final listed = await accounts.suspended();
      // Sin esperar a que venza su access token: la API lo revoca y la app
      // cierra la sesion al no poder renovarla.
      await expectLater(
        valeria.read(profileRepositoryProvider).me(),
        throwsA(isA<ApiFailure>().having((f) => f.status, 'status', 401)),
      );
      final account = await accounts.account(valeria.user.id);
      final reactivated = await accounts.reactivate(valeria.user.id);

      expect(suspended.status, AccountStatus.suspended);
      expect(listed.map((a) => a.id), contains(valeria.user.id));
      expect(valeria.read(sessionControllerProvider), isA<Visitor>());
      expect(valeria.store.saved, isNull);
      expect(account.history, isNotEmpty);
      expect(reactivated.status, AccountStatus.active);
    });

    test('categorias: agregar, renombrar y desactivar', () async {
      final categories = admin.read(adminRepositoryProvider);
      final name = 'Robótica ${DateTime.now().millisecondsSinceEpoch}';

      final created = await categories.createCategory(name);
      final renamed = await categories.updateCategory(
        created.slug,
        name: '$name y drones',
      );
      final inactive = await categories.updateCategory(
        created.slug,
        active: false,
      );
      final all = await categories.categories();

      expect(renamed.name, '$name y drones');
      expect(inactive.active, isFalse);
      expect(all.map((c) => c.slug), contains(created.slug));
    });

    test('una cuenta sin el rol no entra a Administracion', () async {
      final ana = await liveUser();
      addTearDown(ana.dispose);

      await expectLater(
        ana.read(adminRepositoryProvider).reports(open: true),
        throwsA(isA<ApiFailure>().having((f) => f.status, 'status', 403)),
      );
    });
  });
}
