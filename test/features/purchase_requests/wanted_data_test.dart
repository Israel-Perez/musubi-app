import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/purchase_requests/data/http_wanted_repository.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

import '../../helpers/fake_http_adapter.dart';

/// `WantedResponse` como el fixture `wanted.json` de musubi-api.
Map<String, Object?> wantedJson({String status = 'active'}) => {
  'id': '6716a0000000000000000030',
  'title': 'Calculadora Casio fx-991ES Plus',
  'category': {'slug': 'calculadoras', 'name': 'Calculadoras'},
  'description': 'La necesito para Cálculo Integral y Física.',
  'features': ['Modelo fx-991ES Plus', 'Con tapa'],
  'budgetCents': 60000,
  'quantity': 1,
  'neededBy': '2026-11-13',
  'expiresAt': '2026-11-14T06:00:00Z',
  'status': status,
  'offersCount': 3,
  'requester': {
    'id': '6716a0000000000000000001',
    'name': 'Ana R.',
    'photo': null,
    'career': null,
  },
  'createdAt': '2026-11-09T12:00:00Z',
};

// HU-13: el repositorio habla las filas "M-05" de musubi-api y el borrador
// arma lo que se publica.
void main() {
  late FakeHttpAdapter adapter;
  late HttpWantedRepository repository;

  void serve(ResponseBody Function(RequestOptions options) response) {
    adapter = FakeHttpAdapter((options) async => response(options));
    repository = HttpWantedRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );
  }

  test('publicar manda el contrato y mapea la respuesta', () async {
    serve((_) => FakeHttpAdapter.json(wantedJson(), status: 201));

    final created = await repository.publish(
      NewWanted(
        title: '  Calculadora Casio fx-991ES Plus ',
        category: 'calculadoras',
        description: '   ',
        features: const ['Con tapa'],
        budgetCents: 60000,
        quantity: 2,
        neededBy: DateTime(2026, 11, 13),
      ),
    );

    final request = adapter.requests.single;
    expect((request.method, request.path), ('POST', ApiPaths.wanted));
    expect(request.data, {
      'title': 'Calculadora Casio fx-991ES Plus',
      'category': 'calculadoras',
      'description': null,
      'features': ['Con tapa'],
      'budgetCents': 60000,
      'quantity': 2,
      'neededBy': '2026-11-13',
    });
    expect(created.status, WantedStatus.active);
    expect(created.neededBy, DateTime(2026, 11, 13));
    expect((created.offersCount, created.requesterName), (3, 'Ana R.'));
  });

  test('mis solicitudes con el estado de cada una', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'items': [wantedJson(), wantedJson(status: 'expired')],
      }),
    );

    final mine = await repository.mine();

    expect(adapter.requests.single.path, ApiPaths.myWanted);
    expect(mine.map((r) => r.status), [
      WantedStatus.active,
      WantedStatus.expired,
    ]);
    expect(mine.last.isActive, isFalse);
  });

  test('un error llega como ApiFailure con su codigo', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'code': 'wanted.too_many_active',
        'title': 'Ya tienes 5 solicitudes activas.',
        'status': 409,
      }, status: 409),
    );

    expect(
      () => repository.publish(
        const NewWanted(
          title: 'Bata',
          category: 'otro',
          budgetCents: 100,
          quantity: 1,
        ),
      ),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'wanted.too_many_active',
        ),
      ),
    );
  });

  group('tablero Se busca (HU-15)', () {
    test(
      'manda los filtros de la hoja y la lupa como la fila de la API',
      () async {
        serve(
          (_) =>
              FakeHttpAdapter.json({'items': <Object>[], 'nextCursor': null}),
        );

        await repository.board(
          filter: const WantedBoardFilter(
            categories: [
              CatalogCategory(slug: 'laboratorio', name: 'Laboratorio'),
              CatalogCategory(slug: 'libros', name: 'Libros'),
            ],
            budget: WantedBudget.from300To1000,
            deadline: WantedDeadline.thisWeek,
            query: '  bata ',
          ),
          cursor: 'r-laptop',
          limit: 20,
        );

        final request = adapter.requests.single;
        expect((request.method, request.path), ('GET', ApiPaths.wanted));
        expect(request.queryParameters, {
          'category': ['laboratorio', 'libros'],
          'minBudgetCents': 30000,
          'maxBudgetCents': 100000,
          'neededWithinDays': 7,
          'q': 'bata',
          'cursor': 'r-laptop',
          'limit': 20,
        });
      },
    );

    test('sin filtros no manda nada de mas', () async {
      serve(
        (_) => FakeHttpAdapter.json({'items': <Object>[], 'nextCursor': null}),
      );

      await repository.board();

      expect(adapter.requests.single.queryParameters, isEmpty);
      expect(const WantedBoardFilter().count, 0);
      expect(
        const WantedBoardFilter(
          budget: WantedBudget.over1000,
          deadline: WantedDeadline.within3,
        ).count,
        2,
      );
      expect(const WantedBoardFilter(query: 'bata').narrowed, isTrue);
    });

    test('con sesion trae nombre, foto y carrera; el visitante no', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'items': [
            {
              ...wantedJson(),
              'requester': {
                'id': 'u1',
                'name': 'Fernanda Ortiz',
                'photo': '/media/avatars/u1.webp',
                'career': 'QFB',
              },
            },
            {
              ...wantedJson(),
              'neededBy': null,
              'requester': {
                'id': null,
                'name': 'Fernanda O.',
                'photo': null,
                'career': null,
              },
            },
          ],
          'nextCursor': 'abc',
        }),
      );

      final page = await repository.board();

      final member = page.items.first;
      expect(
        (member.requesterId, member.requesterName, member.requesterCareer),
        ('u1', 'Fernanda Ortiz', 'QFB'),
      );
      expect(
        member.requesterPhotoUrl,
        'https://api.musubi.example/media/avatars/u1.webp',
      );
      final visitor = page.items.last;
      expect(visitor.requesterId, isNull);
      expect(visitor.requesterPhotoUrl, isNull);
      expect(visitor.neededBy, isNull);
      expect(page.nextCursor, 'abc');
    });
  });

  group('fechas rapidas de Necesidad-3', () {
    // Martes 10 de noviembre de 2026.
    final tuesday = DateTime(2026, 11, 10, 18, 30);

    test('esta semana es el domingo y el viernes el proximo', () {
      expect(endOfWeek(tuesday), DateTime(2026, 11, 15));
      expect(nextFriday(tuesday), DateTime(2026, 11, 13));
      expect(nextFriday(DateTime(2026, 11, 13, 9)), DateTime(2026, 11, 13));
      expect(endOfWeek(DateTime(2026, 11, 15, 9)), DateTime(2026, 11, 15));
    });

    test(
      'Elegir fecha: lunes, miercoles y viernes que entran y otro lunes',
      () {
        expect(otherDates(tuesday), [
          DateTime(2026, 11, 16),
          DateTime(2026, 11, 18),
          DateTime(2026, 11, 20),
          DateTime(2026, 11, 23),
        ]);
        // El lunes de la maqueta (5 de octubre) da sus `NEED_DATES`.
        expect(
          otherDates(DateTime(2026, 10, 5, 14)).first,
          DateTime(2026, 10, 12),
        );
        expect(
          otherDates(DateTime(2026, 10, 11, 9)).first,
          DateTime(2026, 10, 12),
        );
      },
    );

    test('el borrador elige el dia y sin eleccion no manda fecha', () {
      const base = NeedDraft(
        title: 'Calculadora',
        category: CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
        budgetCents: 60000,
      );

      expect(base.toRequest(tuesday).neededBy, isNull);
      expect(
        base.copyWith(when: NeedWhen.friday).toRequest(tuesday).neededBy,
        DateTime(2026, 11, 13),
      );
      expect(
        base
            .copyWith(when: NeedWhen.custom, customDate: DateTime(2026, 12, 2))
            .toRequest(tuesday)
            .neededBy,
        DateTime(2026, 12, 2),
      );
    });
  });
}
