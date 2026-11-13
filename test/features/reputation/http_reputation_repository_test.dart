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

  group('calificaciones (HU-27, HU-45)', () {
    test(
      'calificar manda estrellas, chips por codigo y el comentario',
      () async {
        serve(
          (_) => FakeHttpAdapter.json({
            'stars': 4,
            'tags': ['on_time'],
            'comment': 'Muy puntual.',
            'createdAt': '2026-11-12T18:00:00Z',
          }, status: 201),
        );

        await repository.rate(
          'o1',
          const NewRating(
            stars: 4,
            tags: [RatingTag.onTime, RatingTag.paidAsAgreed],
            comment: 'Muy puntual.',
          ),
        );

        final request = adapter.requests.single;
        expect(request.path, ApiPaths.orderRating('o1'));
        expect(request.data, {
          'stars': 4,
          'tags': ['on_time', 'paid_as_agreed'],
          'comment': 'Muy puntual.',
        });
      },
    );

    test('sin comentario no lo manda', () async {
      serve((_) => FakeHttpAdapter.json(<String, Object?>{}, status: 201));

      await repository.rate('o1', const NewRating(stars: 5));

      expect(adapter.requests.single.data, {'stars': 5, 'tags': <String>[]});
    });

    test('las opiniones se leen con cursor y chips conocidos', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'items': [
            {
              'id': 'r1',
              'stars': 5,
              'tags': ['on_time', 'algo_nuevo'],
              'comment': 'Súper puntual.',
              'raterName': 'Luis M.',
              'role': 'seller',
              'createdAt': '2026-09-28T18:00:00Z',
            },
          ],
          'nextCursor': 'r1',
        }),
      );

      final page = await repository.opinions('u2', cursor: 'r0');

      expect(adapter.requests.single.path, ApiPaths.profileRatings('u2'));
      expect(adapter.requests.single.queryParameters, {'cursor': 'r0'});
      final opinion = page.items.single;
      expect((opinion.stars, opinion.raterName), (5, 'Luis M.'));
      expect(opinion.tags, [RatingTag.onTime]);
      expect(opinion.createdAt, DateTime.utc(2026, 9, 28, 18));
      expect(page.nextCursor, 'r1');
    });

    test('ya calificado llega como ApiFailure', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'code': 'ratings.already_rated',
          'title': 'Ya calificaste este pedido.',
          'status': 409,
        }, status: 409),
      );

      await expectLater(
        repository.rate('o1', const NewRating(stars: 5)),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'ratings.already_rated',
          ),
        ),
      );
    });

    test('las palabras de las estrellas son las de la maqueta', () {
      expect(
        [for (var n = 1; n <= 5; n++) ratingWords(n)],
        ['Muy mala', 'Mala', 'Regular', 'Muy buena', '¡Excelente!'],
      );
      expect(RatingTag.forBuyer, isNot(contains(RatingTag.asDescribed)));
      expect(RatingTag.forBuyer, contains(RatingTag.paidAsAgreed));
    });
  });
}
