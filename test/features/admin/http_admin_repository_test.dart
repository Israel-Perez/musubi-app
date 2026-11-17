import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/admin/data/http_admin_repository.dart';
import 'package:musubi_app/features/admin/domain/admin_models.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';

import '../../helpers/fake_admin.dart';
import '../../helpers/fake_http_adapter.dart';

/// Las formas de `musubi-api/ContractTest/Fixtures/admin-*.json` (HU-39,
/// HU-40 y HU-41).
const Map<String, Object?> reportJson = {
  'id': '6716a0000000000000000031',
  'reason': 'not_as_described',
  'details': 'Las fotos son de otra tienda.',
  'status': 'upheld',
  'createdAt': '2026-11-16T15:00:00Z',
  'reporter': {'id': 'u-ana', 'fullName': 'Ana Sofía Ramírez'},
  'target': {
    'type': 'product',
    'id': 'p1',
    'name': 'Calculadora Casio fx-991',
    'photo': 'https://media.musubiapp.com.mx/products/p1/foto.webp',
    'status': 'removed',
  },
  'subject': {
    'id': 'u-luis',
    'fullName': 'Luis Martínez',
    'status': 'active',
    'upheldReports': 1,
    'suspensionSuggested': false,
  },
  'conversationId': null,
  'review': {
    'at': '2026-11-16T16:00:00Z',
    'reviewer': {'id': 'admin-1', 'fullName': 'Equipo Musubi'},
    'note': 'Fotos de internet.',
  },
};

const Map<String, Object?> accountJson = {
  'id': 'u-luis',
  'fullName': 'Luis Martínez',
  'status': 'suspended',
  'isAdmin': false,
  'memberSince': '2026-10-21T18:00:00Z',
  'upheldReports': 1,
  'suspensionSuggested': false,
  'history': [
    {
      'action': 'account_suspended',
      'at': '2026-11-16T16:05:00Z',
      'actor': {'id': 'admin-1', 'fullName': 'Equipo Musubi'},
      'reason': 'Pidió pagos fuera de Musubi.',
    },
  ],
};

void main() {
  HttpAdminRepository repositoryWith(FakeHttpAdapter adapter) =>
      HttpAdminRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
      );

  test('la bandeja lee lo reportado, el responsable y la revisión', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({
        'items': [reportJson],
      }),
    );

    final reports = await repositoryWith(adapter).reports(open: false);

    final request = adapter.requests.single;
    expect(request.path, ApiPaths.adminReports);
    expect(request.queryParameters, {'status': 'closed'});
    final report = reports.single;
    expect(report.reason, ReportReason.notAsDescribed);
    expect(report.status, ReportStatus.upheld);
    expect(report.target.kind, ReportedKind.product);
    expect(report.target.removed, isTrue);
    expect(report.reporter!.fullName, 'Ana Sofía Ramírez');
    expect(report.subject!.upheldReports, 1);
    expect(report.subject!.status, AccountStatus.active);
    expect(report.review!.reviewer!.fullName, 'Equipo Musubi');
    expect(report.review!.note, 'Fotos de internet.');
    expect(report.upholdLabel, 'Retirar publicación');
  });

  test('"Procedente" manda la acción y la nota sin espacios', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json(reportJson),
    );

    await repositoryWith(adapter)
        .resolve('r1', ReportAction.uphold, note: '  Fotos de internet.  ');
    await repositoryWith(adapter)
        .resolve('r1', ReportAction.dismiss, note: ' ');

    expect(adapter.requests.first.method, 'POST');
    expect(adapter.requests.first.path, ApiPaths.adminReportResolution('r1'));
    expect(adapter.requests.first.data, {
      'action': 'uphold',
      'note': 'Fotos de internet.',
    });
    // Sin nota no se manda el campo.
    expect(adapter.requests.last.data, {'action': 'dismiss'});
  });

  test('suspender y reactivar leen la cuenta con su historial', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json(accountJson),
    );

    final suspended = await repositoryWith(adapter)
        .suspend('u-luis', ' Pidió pagos fuera de Musubi. ');
    await repositoryWith(adapter).reactivate('u-luis');

    expect(adapter.requests.first.path, ApiPaths.adminSuspension('u-luis'));
    expect(adapter.requests.first.data, {
      'reason': 'Pidió pagos fuera de Musubi.',
    });
    expect(adapter.requests.last.method, 'DELETE');
    expect(suspended.status, AccountStatus.suspended);
    expect(suspended.history.single.label, 'Cuenta suspendida');
    expect(suspended.history.single.actor!.fullName, 'Equipo Musubi');
    expect(suspended.history.single.reason, 'Pidió pagos fuera de Musubi.');
  });

  test('las suspendidas y un error llegan con su código', () async {
    final adapter = FakeHttpAdapter(
      (request) async => request.path == ApiPaths.adminSuspendedAccounts
          ? FakeHttpAdapter.json({
              'items': [
                {
                  'id': 'u-luis',
                  'fullName': 'Luis Martínez',
                  'status': 'suspended',
                  'updatedAt': '2026-11-16T16:05:00Z',
                },
              ],
            })
          : FakeHttpAdapter.json({
              'code': 'admin.report_closed',
              'title': 'Este reporte ya se revisó.',
              'status': 409,
            }, status: 409),
    );

    final suspended = await repositoryWith(adapter).suspended();

    expect(suspended.single.fullName, 'Luis Martínez');
    await expectLater(
      repositoryWith(adapter).resolve('r1', ReportAction.dismiss),
      throwsA(
        isA<ApiFailure>().having((f) => f.code, 'code', 'admin.report_closed'),
      ),
    );
  });

  test('el rol sale del token: uno, una lista o ninguno', () {
    expect(SessionTokens.rolesOf(jwtWithRoles('a', ['student', 'admin'])), [
      'student',
      'admin',
    ]);
    expect(adminTokens().isAdmin, isTrue);
    expect(
      SessionTokens(
        accessToken: jwtWithRoles('a', ['student']),
        accessExpiresAt: DateTime.utc(2026, 11, 16),
        refreshToken: 'r',
      ).isAdmin,
      isFalse,
    );
    expect(SessionTokens.rolesOf('no-es-un-jwt'), isEmpty);
  });

  test('las categorías: la lista con las desactivadas, agregar y cambiar '
      '(HU-41)', () async {
    final adapter = FakeHttpAdapter(
      (request) async => switch (request.method) {
        'GET' => FakeHttpAdapter.json({
          'items': [
            {
              'slug': 'calculadoras',
              'name': 'Calculadoras',
              'active': true,
              'order': 1,
            },
            {
              'slug': 'ropa-y-batas',
              'name': 'Ropa y batas',
              'active': false,
              'order': 7,
            },
          ],
        }),
        _ => FakeHttpAdapter.json({
          'slug': 'ropa-y-batas',
          'name': 'Ropa y batas',
          'active': true,
          'order': 7,
        }, status: request.method == 'POST' ? 201 : 200),
      },
    );
    final repository = repositoryWith(adapter);

    final list = await repository.categories();
    final created = await repository.createCategory('  Ropa y batas ');
    await repository.updateCategory('ropa-y-batas', name: ' Batas ');
    await repository.updateCategory('ropa-y-batas', active: false);

    expect(list.map((c) => (c.slug, c.active)), [
      ('calculadoras', true),
      ('ropa-y-batas', false),
    ]);
    expect(created.order, 7);
    final requests = adapter.requests;
    expect(requests[0].path, ApiPaths.adminCategories);
    expect(requests[1].method, 'POST');
    expect(requests[1].data, {'name': 'Ropa y batas'});
    // En un cambio solo va lo que cambia.
    expect(requests[2].path, ApiPaths.adminCategory('ropa-y-batas'));
    expect(requests[2].method, 'PATCH');
    expect(requests[2].data, {'name': 'Batas'});
    expect(requests[3].data, {'active': false});
  });
}
