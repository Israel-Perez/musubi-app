import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/http_favorites_repository.dart';
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';

import '../../../helpers/fake_http_adapter.dart';

/// `FavoriteItemResponse` + `ProductResponse` del fixture
/// `musubi-api/ContractTest/Fixtures/favorites.json`.
Map<String, Object?> favoriteJson({
  String productId = '6716a0000000000000000099',
  String status = 'available',
  bool withProduct = true,
}) => {
  'productId': productId,
  'savedAt': '2026-11-09T12:00:00Z',
  'status': status,
  'product': withProduct
      ? {
          'id': productId,
          'title': 'Calculadora científica Casio fx-991ES Plus',
          'description': 'La usé un semestre.',
          'category': 'calculadoras',
          'priceCents': 45000,
          'condition': 'used',
          'conditionDetail': 'likeNew',
          'stock': status == 'soldOut' ? 0 : 1,
          'status': status == 'soldOut' ? 'soldOut' : 'active',
          'photos': ['/media/products/u1/foto.webp'],
          'seller': {'name': 'Ana R.'},
          'publishedAt': '2026-10-27T12:00:00Z',
        }
      : null,
};

// HU-53: el repositorio habla las filas 79–81 de musubi-api y traduce los
// errores; el corazon se arma con GET /favorites (enfoque B).
void main() {
  late FakeHttpAdapter adapter;
  late HttpFavoritesRepository repository;

  void serve(Future<ResponseBody> Function(RequestOptions) handler) {
    adapter = FakeHttpAdapter(handler);
    repository = HttpFavoritesRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );
  }

  test('GET /favorites lista los tres estados y el producto nulo', () async {
    serve((options) async {
      expect(options.method, 'GET');
      expect(options.path, ApiPaths.favorites);
      return FakeHttpAdapter.json({
        'items': [
          favoriteJson(),
          favoriteJson(
            productId: '6716a0000000000000000098',
            status: 'soldOut',
          ),
          favoriteJson(
            productId: '6716a0000000000000000097',
            status: 'unavailable',
            withProduct: false,
          ),
        ],
      });
    });

    final favorites = await repository.list();

    expect(favorites.items.map((item) => item.status), [
      FavoriteStatus.available,
      FavoriteStatus.soldOut,
      FavoriteStatus.unavailable,
    ]);
    expect(favorites.ids, {
      '6716a0000000000000000099',
      '6716a0000000000000000098',
      '6716a0000000000000000097',
    });
    expect(favorites.availableCount, 1);
    expect(favorites.soldOutCount, 2);
    expect(favorites.items.first.savedAt, DateTime.utc(2026, 11, 9, 12));
    expect(
      favorites.items.first.product!.photoUrl,
      'https://api.musubi.example/media/products/u1/foto.webp',
    );
    expect(favorites.items.last.product, isNull);
  });

  test('un elemento inválido no tumba la lista', () async {
    serve(
      (_) async => FakeHttpAdapter.json({
        'items': [
          favoriteJson(status: 'desconocido'),
          favoriteJson(
            productId: '6716a0000000000000000096',
            withProduct: false,
          ),
          favoriteJson(productId: '6716a0000000000000000095')
            ..remove('savedAt'),
          {
            'productId': '6716a0000000000000000094',
            'savedAt': '2026-11-09T12:00:00Z',
            'status': 'available',
            'product': <String, Object?>{},
          },
        ],
      }),
    );

    final favorites = await repository.list();

    expect(favorites.items, hasLength(3));
    expect(
      favorites.items.map((item) => item.status),
      everyElement(FavoriteStatus.unavailable),
    );
    expect(favorites.items.every((item) => item.product == null), isTrue);
  });

  test('PUT guarda el producto en la fila 80', () async {
    serve((_) async => ResponseBody.fromString('', 204));

    await repository.add('6716a0000000000000000099');

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, '/api/v1/favorites/6716a0000000000000000099');
  });

  test('DELETE quita el producto en la fila 81', () async {
    serve((_) async => ResponseBody.fromString('', 204));

    await repository.remove('6716a0000000000000000099');

    final request = adapter.requests.single;
    expect(request.method, 'DELETE');
    expect(request.path, '/api/v1/favorites/6716a0000000000000000099');
  });

  test('un 403 de PUT conserva el code de la API', () async {
    serve(
      (_) async => FakeHttpAdapter.json({
        'code': 'auth.forbidden',
        'title': 'No puedes guardar este producto.',
      }, status: 403),
    );

    await expectLater(
      repository.add('p1'),
      throwsA(
        isA<ApiFailure>()
            .having((failure) => failure.code, 'code', 'auth.forbidden')
            .having((failure) => failure.status, 'status', 403),
      ),
    );
  });

  test('un 404 de PUT conserva el code de la publicación', () async {
    serve(
      (_) async => FakeHttpAdapter.json({
        'code': 'listings.product_not_found',
        'title': 'Esta publicación ya no está disponible.',
      }, status: 404),
    );

    await expectLater(
      repository.add('p1'),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.code,
          'code',
          'listings.product_not_found',
        ),
      ),
    );
  });

  test('un 401 o 5xx llegan como ApiFailure', () async {
    serve(
      (_) async => FakeHttpAdapter.json({
        'code': 'auth.unauthorized',
        'title': 'Inicia sesión.',
      }, status: 401),
    );
    await expectLater(
      repository.list(),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.code,
          'code',
          'auth.unauthorized',
        ),
      ),
    );

    serve(
      (_) async => FakeHttpAdapter.json({
        'code': 'server.error',
        'title': 'No se pudo completar la operación.',
      }, status: 503),
    );
    await expectLater(
      repository.list(),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.code,
          'code',
          'server.error',
        ),
      ),
    );
  });

  test('sin red llega como ApiFailure de red', () async {
    serve(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );

    await expectLater(
      repository.list(),
      throwsA(
        isA<ApiFailure>().having(
          (failure) => failure.isNetwork,
          'isNetwork',
          isTrue,
        ),
      ),
    );
  });
}
