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

  // HU-07: editar, pausar, reactivar y eliminar (filas "M-03" de
  // musubi-api:HU-07).

  test('editar: PUT con los campos editables y lee lo que se edita', () async {
    serve(productJson(status: 'hidden'));

    final edited = await repository.update(
      '6716a0000000000000000099',
      const ListingUpdate(
        title: '  Calculadora Casio fx-570  ',
        description: 'Como nueva.',
        category: 'libros',
        priceCents: 39900,
        condition: ProductCondition.brandNew,
        usedDetail: UsedDetail.good,
      ),
    );

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, ApiPaths.product('6716a0000000000000000099'));
    expect(request.data, {
      'title': 'Calculadora Casio fx-570',
      'description': 'Como nueva.',
      'category': 'libros',
      'priceCents': 39900,
      'condition': 'new',
      // Un nuevo no lleva detalle.
      'conditionDetail': null,
    });
    expect(edited.paused, isTrue);
    expect(edited.description, 'La usé un semestre.');
    expect(edited.condition, ProductCondition.used);
    expect(edited.usedDetail, UsedDetail.likeNew);
  });

  test('pausar y reactivar: POST a sus rutas', () async {
    serve(productJson(status: 'hidden'));
    final paused = await repository.pause('a1');
    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, ApiPaths.productPause('a1'));
    expect(paused.status, ListingStatus.hidden);

    serve(productJson(status: 'soldOut', stock: 0));
    final resumed = await repository.resume('a1');
    expect(adapter.requests.single.path, ApiPaths.productResume('a1'));
    expect(resumed.status, ListingStatus.soldOut);
  });

  test('eliminar: DELETE a la publicacion', () async {
    serve(null, status: 204);

    await repository.delete('a1');

    expect(adapter.requests.single.method, 'DELETE');
    expect(adapter.requests.single.path, ApiPaths.product('a1'));
  });

  test('eliminar con pedidos abiertos: 409 con el mensaje de la API', () async {
    serve({
      'title':
          'Tiene pedidos pendientes o confirmados. Termínalos o cancélalos '
          'antes de eliminarla.',
      'code': 'listings.product_has_orders',
      'status': 409,
    }, status: 409);

    expect(
      () => repository.delete('a1'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.code, 'code', 'listings.product_has_orders')
            .having((f) => f.message, 'message', contains('Termínalos')),
      ),
    );
  });

  // HU-08: pestanas de "Mis productos" y "Marcar como vendido" (filas "M-03"
  // de musubi-api:HU-08).

  test('mis productos por pestana: ?tab=, cursor y conteos', () async {
    serve({
      'items': [
        {...productJson(status: 'sold'), 'soldAt': '2026-11-09T18:00:00Z'},
      ],
      'nextCursor': '6716a0000000000000000001',
      'total': 3,
      'counts': {'active': 2, 'sold': 3, 'soldOut': 1},
    });

    final page = await repository.minePage(
      MyProductsTab.sold,
      cursor: '6716a0000000000000000099',
    );

    final request = adapter.requests.single;
    expect(request.path, ApiPaths.myProducts);
    expect(request.queryParameters, {
      'tab': 'sold',
      'cursor': '6716a0000000000000000099',
    });
    final sold = page.items.single;
    // Una vendida no se lee como activa (ofertas de HU-16 y el Perfil).
    expect(sold.status, ListingStatus.sold);
    expect(sold.soldAt, DateTime.utc(2026, 11, 9, 18));
    expect(page.nextCursor, '6716a0000000000000000001');
    expect(page.total, 3);
    expect(
      (page.counts.active, page.counts.sold, page.counts.soldOut),
      (2, 3, 1),
    );
  });

  test('primera pagina: sin cursor en la query', () async {
    serve({
      'items': <Object>[],
      'nextCursor': null,
      'total': 0,
      'counts': <String, Object>{},
    });

    final page = await repository.minePage(MyProductsTab.active);

    expect(adapter.requests.single.queryParameters, {'tab': 'active'});
    expect(page.items, isEmpty);
    expect(page.nextCursor, isNull);
    expect(page.counts.active, 0);
  });

  test('marcar como vendido: POST a /sold', () async {
    serve({...productJson(status: 'sold'), 'soldAt': '2026-11-10T12:00:00Z'});

    final sold = await repository.markSold('a1');

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, ApiPaths.productSold('a1'));
    expect(sold.sold, isTrue);
  });

  // HU-50: "Cambiar piezas" y "Reponer" (fila "M-03" de musubi-api:HU-50).
  test('cambiar piezas: PUT /stock con { stock }', () async {
    serve(productJson(status: 'soldOut', stock: 0));

    final changed = await repository.setStock('a1', 0);

    final request = adapter.requests.single;
    expect(request.method, 'PUT');
    expect(request.path, ApiPaths.productStock('a1'));
    expect(request.data, {'stock': 0});
    expect(changed.status, ListingStatus.soldOut);
    expect(changed.product.soldOut, isTrue);
  });
}
