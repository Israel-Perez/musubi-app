import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/reputation/data/http_reputation_repository.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';

import '../../helpers/fake_http_adapter.dart';

// HU-28 y HU-57: el repositorio habla las filas "M-13" de musubi-api
// (`docs/endpoints.md`) y traduce sus errores.
void main() {
  late FakeHttpAdapter adapter;
  late HttpReputationRepository repository;

  void serve(ResponseBody Function(RequestOptions options) response) {
    adapter = FakeHttpAdapter((options) async => response(options));
    repository = HttpReputationRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );
  }

  test(
    'reportar desde el chat manda la persona, la conversacion y el motivo',
    () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'id': '6716a0000000000000000020',
          'createdAt': '2026-11-08T12:00:00Z',
        }, status: 201),
      );

      await repository.report(
        const UserReport(userId: 'u2', conversationId: 'c1'),
        ReportReason.offPlatform,
        details: '  Me pidió depositarle antes.  ',
      );

      final request = adapter.requests.single;
      expect((request.method, request.path), ('POST', ApiPaths.reports));
      expect(request.data, {
        'targetType': 'user',
        'targetId': 'u2',
        'conversationId': 'c1',
        'reason': 'off_platform',
        'details': 'Me pidió depositarle antes.',
      });
    },
  );

  test(
    'reportar un problema general sin detalle no manda id ni detalle',
    () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'id': 'r1',
          'createdAt': '2026-11-08T12:00:00Z',
        }, status: 201),
      );

      await repository.report(
        const GeneralReport(),
        ReportReason.other,
        details: '   ',
      );

      expect(adapter.requests.single.data, {
        'targetType': 'general',
        'reason': 'other',
      });
    },
  );

  test('bloquear, desbloquear y la lista con su foto', () async {
    serve(
      (options) => options.method == 'GET'
          ? FakeHttpAdapter.json({
              'items': [
                {
                  'id': 'u2',
                  'name': 'Diego Hernández',
                  'photo': '/media/avatars/u2/a.webp',
                  'blockedAt': '2026-11-08T12:00:00Z',
                },
                {
                  'id': 'u3',
                  'name': 'Luis Pérez',
                  'photo': null,
                  'blockedAt': '2026-11-07T12:00:00Z',
                },
              ],
            })
          : ResponseBody.fromString('', 204),
    );

    await repository.block('u2');
    await repository.unblock('u3');
    final list = await repository.blocked();

    expect(adapter.requests[0].path, ApiPaths.blocks);
    expect(adapter.requests[0].data, {'userId': 'u2'});
    expect(
      (adapter.requests[1].method, adapter.requests[1].path),
      ('DELETE', ApiPaths.block('u3')),
    );
    expect(list.map((u) => u.name), ['Diego Hernández', 'Luis Pérez']);
    expect(
      list.first.photoUrl,
      'https://api.musubi.example/media/avatars/u2/a.webp',
    );
    expect(list.last.photoUrl, isNull);
    expect(list.first.firstName, 'Diego');
  });

  test('un error de la API llega como ApiFailure con su codigo', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'code': 'blocks.self',
        'title': 'No puedes bloquearte a ti mismo.',
        'status': 400,
      }, status: 400),
    );

    expect(
      () => repository.block('yo'),
      throwsA(isA<ApiFailure>().having((f) => f.code, 'code', 'blocks.self')),
    );
  });
}
