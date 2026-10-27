import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/listings/data/http_listings_repository.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';

import '../../helpers/fake_http_adapter.dart';

/// `ProductResponse` (fixture `product.json` de musubi-api).
Map<String, Object?> productJson({String status = 'active', int stock = 1}) => {
  'id': '6716a0000000000000000099',
  'title': 'Calculadora científica Casio fx-991ES Plus',
  'description': 'La usé un semestre.',
  'category': 'calculadoras',
  'priceCents': 45000,
  'condition': 'used',
  'conditionDetail': 'likeNew',
  'stock': stock,
  'status': status,
  'photos': ['/media/products/u1/foto.webp'],
  'seller': {'name': 'Ana R.'},
  'publishedAt': '2026-10-27T12:00:00Z',
};

// HU-06: el repositorio habla el contrato de musubi-api (filas "M-03") y
// traduce los errores.
void main() {
  late FakeHttpAdapter adapter;
  late HttpListingsRepository repository;

  void serve(Object? body, {int status = 200}) {
    adapter = FakeHttpAdapter(
      (_) async => body == null
          ? ResponseBody.fromString('', status)
          : FakeHttpAdapter.json(body, status: status),
    );
    repository = HttpListingsRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );
  }

  test('subir foto: multipart "photo" y la ruta se vuelve URL', () async {
    final dir = Directory.systemTemp.createTempSync('musubi-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final file = File('${dir.path}/foto.jpg')..writeAsBytesSync([1, 2, 3]);
    serve({
      'key': 'media/products/u1/abc.webp',
      'path': '/media/products/u1/abc.webp',
    }, status: 201);

    final photo = await repository.uploadPhoto(file.path);

    final request = adapter.requests.single;
    expect(request.path, ApiPaths.productPhotos);
    expect(request.data, isA<FormData>());
    expect((request.data as FormData).files.single.key, 'photo');
    expect(photo.key, 'media/products/u1/abc.webp');
    expect(photo.url, 'https://api.musubi.example/media/products/u1/abc.webp');
  });

  test('publicar: manda el contrato y lee la tarjeta', () async {
    serve(productJson(), status: 201);

    final product = await repository.publish(
      const NewListing(
        title: '  Calculadora científica Casio fx-991ES Plus ',
        description: 'La usé un semestre.',
        category: 'calculadoras',
        priceCents: 45000,
        condition: ProductCondition.used,
        usedDetail: UsedDetail.likeNew,
        quantity: 1,
        photoKeys: ['media/products/u1/abc.webp'],
      ),
    );

    expect(adapter.requests.single.data, {
      'title': 'Calculadora científica Casio fx-991ES Plus',
      'description': 'La usé un semestre.',
      'category': 'calculadoras',
      'priceCents': 45000,
      'condition': 'used',
      'conditionDetail': 'likeNew',
      'stock': 1,
      'photos': ['media/products/u1/abc.webp'],
    });
    expect(product.condition, 'Usado');
    expect(product.sellerName, 'Ana R.');
    expect(
      product.photoUrl,
      'https://api.musubi.example/media/products/u1/foto.webp',
    );
  });

  test('mis productos: el estado sale de status', () async {
    serve({
      'items': [productJson(), productJson(status: 'soldOut', stock: 0)],
      'nextCursor': null,
      'total': 2,
    });

    final mine = await repository.mine();

    expect(mine.map((l) => l.status), [
      ListingStatus.active,
      ListingStatus.soldOut,
    ]);
    expect(mine.last.product.soldOut, isTrue);
  });

  test('rango de precios: 204 es "aun no hay datos"', () async {
    serve(null, status: 204);

    expect(await repository.priceRange('libros'), isNull);
    expect(adapter.requests.single.queryParameters, {'category': 'libros'});
  });

  test('rango de precios: percentiles en centavos', () async {
    serve({'lowCents': 38000, 'highCents': 52000, 'count': 7});

    final range = await repository.priceRange('calculadoras');

    expect(range?.lowCents, 38000);
    expect(range?.highCents, 52000);
  });

  test('un error de la API llega como ApiFailure con su code', () async {
    serve({
      'title': 'Agrega de 1 a 8 fotos tuyas para continuar.',
      'code': 'listings.invalid_photos',
      'status': 400,
    }, status: 400);

    expect(
      () => repository.publish(
        const NewListing(
          title: 'x',
          description: '',
          category: 'libros',
          priceCents: 100,
          condition: ProductCondition.brandNew,
          quantity: 1,
          photoKeys: [],
        ),
      ),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'listings.invalid_photos',
        ),
      ),
    );
  });
}
