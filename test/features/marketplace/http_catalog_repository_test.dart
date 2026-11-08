import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/http_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

import '../../helpers/fake_http_adapter.dart';
import '../listings/http_listings_repository_test.dart' show productJson;

// HU-48 fase 2: la vitrina lee `GET /api/v1/products` y las categorias.
void main() {
  late FakeHttpAdapter adapter;
  late HttpCatalogRepository repository;

  void serve({int status = 200, String? nextCursor}) {
    adapter = FakeHttpAdapter(
      (options) async => switch (options.path) {
        ApiPaths.products when status != 200 => FakeHttpAdapter.json({
          'title': 'Sin conexión',
          'code': 'server.unavailable',
        }, status: status),
        ApiPaths.products => FakeHttpAdapter.json({
          'items': [productJson()],
          'nextCursor': nextCursor,
          'total': 48,
        }),
        _ => FakeHttpAdapter.json([
          {'slug': 'calculadoras', 'name': 'Calculadoras'},
          {'slug': 'electronica', 'name': 'Electrónica'},
        ]),
      },
    );
    repository = HttpCatalogRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );
  }

  test('recien publicados, categorias con su foto y el total', () async {
    serve();

    final feed = await repository.homeFeed(period: PopularPeriod.today);

    expect(feed.recent.single.title, startsWith('Calculadora'));
    expect(feed.recent.single.sellerName, 'Ana R.');
    expect(feed.recentTotal, 48);
    expect(feed.categories.map((c) => c.slug), ['calculadoras', 'electronica']);
    expect(feed.categories.first.photoUrl, 'asset:assets/products/casio.webp');
    // "Populares" (HU-49) y "Se busca" (HU-15) llegan con sus HU.
    expect(feed.popular, isEmpty);
    expect(feed.wanted, isEmpty);
  });

  test('el filtro va en la consulta', () async {
    serve();

    await repository.homeFeed(
      period: PopularPeriod.today,
      filter: const CatalogFilter(category: 'libros', hideSoldOut: true),
    );

    final products = adapter.requests.firstWhere(
      (r) => r.path == ApiPaths.products,
    );
    expect(products.queryParameters, {
      'category': 'libros',
      'hideSoldOut': true,
      'limit': HttpCatalogRepository.pageSize,
    });
  });

  test('un error llega como ApiFailure', () async {
    serve(status: 503);

    expect(
      () => repository.homeFeed(period: PopularPeriod.today),
      throwsA(isA<ApiFailure>()),
    );
  });

  test('categorias de la hoja `Busqueda-filtros` (fila 72)', () async {
    serve();

    final categories = await repository.categories();

    expect(adapter.requests.single.path, ApiPaths.categories);
    expect(categories.map((c) => c.slug), ['calculadoras', 'electronica']);
    expect(categories.first.name, 'Calculadoras');
  });

  group('buscar (HU-09)', () {
    test('manda q recortado, limit y cursor; lee la pagina', () async {
      serve(nextCursor: 'next');

      final page = await repository.search(
        query: '  calculadora  ',
        cursor: 'abc',
      );

      final request = adapter.requests.single;
      expect(request.path, ApiPaths.products);
      expect(request.queryParameters, {
        'q': 'calculadora',
        'limit': HttpCatalogRepository.searchPageSize,
        'cursor': 'abc',
      });
      expect(page.items.single.title, startsWith('Calculadora'));
      expect(page.total, 48);
      expect(page.nextCursor, 'next');
      expect(page.hasMore, isTrue);
    });

    test('HU-10: filtros en la consulta y sin q cuando no hay texto', () async {
      serve();

      await repository.search(
        query: '   ',
        filter: const CatalogFilter(
          category: 'libros',
          minPriceCents: 30000,
          maxPriceCents: 70000,
          condition: 'used',
          hideSoldOut: true,
        ),
      );

      expect(adapter.requests.single.queryParameters, {
        'category': 'libros',
        'minPriceCents': 30000,
        'maxPriceCents': 70000,
        'condition': 'used',
        'hideSoldOut': true,
        'limit': HttpCatalogRepository.searchPageSize,
      });
    });

    test('HU-10: filtros y texto viajan juntos', () async {
      serve();

      await repository.search(
        query: 'calculadora',
        filter: const CatalogFilter(minPriceCents: 30000),
      );

      expect(adapter.requests.single.queryParameters, {
        'q': 'calculadora',
        'minPriceCents': 30000,
        'limit': HttpCatalogRepository.searchPageSize,
      });
    });

    test('400 listings.invalid_price_range llega con su code', () async {
      adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.json({
          'code': 'listings.invalid_price_range',
          'title': 'El precio mínimo no puede ser mayor que el máximo.',
        }, status: 400),
      );
      repository = HttpCatalogRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
        Uri.parse('https://api.musubi.example'),
      );

      expect(
        () => repository.search(
          query: '',
          filter: const CatalogFilter(
            minPriceCents: 70000,
            maxPriceCents: 30000,
          ),
        ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'listings.invalid_price_range',
          ),
        ),
      );
    });

    test('400 listings.invalid_condition llega con su code', () async {
      adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.json({
          'code': 'listings.invalid_condition',
          'title': 'El estado no es válido.',
        }, status: 400),
      );
      repository = HttpCatalogRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
        Uri.parse('https://api.musubi.example'),
      );

      expect(
        () => repository.search(
          query: '',
          filter: const CatalogFilter(condition: 'broken'),
        ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'listings.invalid_condition',
          ),
        ),
      );
    });

    test('400 listings.invalid_query llega con su code', () async {
      adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.json({
          'code': 'listings.invalid_query',
          'title': 'Escribe al menos una letra o un número.',
        }, status: 400),
      );
      repository = HttpCatalogRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
        Uri.parse('https://api.musubi.example'),
      );

      expect(
        () => repository.search(query: '...'),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', 'listings.invalid_query')
              .having((f) => f.status, 'status', 400),
        ),
      );
    });

    test('5xx en la busqueda llega como ApiFailure con su status', () async {
      serve(status: 503);

      expect(
        () => repository.search(query: 'calculadora'),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.status, 'status', 503)
              .having((f) => f.code, 'code', 'server.unavailable'),
        ),
      );
    });

    test('400 listings.invalid_cursor llega con su code', () async {
      adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.json({
          'code': 'listings.invalid_cursor',
          'title': 'El cursor ya no es válido.',
        }, status: 400),
      );
      repository = HttpCatalogRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
        Uri.parse('https://api.musubi.example'),
      );

      expect(
        () => repository.search(query: 'calc', cursor: 'bad'),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', 'listings.invalid_cursor')
              .having((f) => f.status, 'status', 400),
        ),
      );
    });

    test('sin red llega como network.offline', () async {
      adapter = FakeHttpAdapter(
        (options) async => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      repository = HttpCatalogRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
        Uri.parse('https://api.musubi.example'),
      );

      expect(
        () => repository.search(query: 'calculadora'),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            ApiFailure.networkOffline,
          ),
        ),
      );
    });
  });
}
