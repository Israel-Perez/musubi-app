import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/http_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/domain/search_sort.dart';

import '../../helpers/fake_http_adapter.dart';
import '../listings/http_listings_repository_test.dart' show productJson;

// HU-48 fase 2: la vitrina lee `GET /api/v1/products` y las categorias.
void main() {
  late FakeHttpAdapter adapter;
  late HttpCatalogRepository repository;

  void serve({int status = 200, String? nextCursor, int wantedStatus = 200}) {
    adapter = FakeHttpAdapter(
      (options) async => switch (options.path) {
        ApiPaths.wanted when wantedStatus != 200 => FakeHttpAdapter.json({
          'title': 'Sin conexión',
          'code': 'server.unavailable',
        }, status: wantedStatus),
        ApiPaths.wanted => FakeHttpAdapter.json({
          'items': [
            {
              'id': 'r1',
              'title': 'Bata de laboratorio talla M',
              'category': {'slug': 'laboratorio', 'name': 'Laboratorio'},
              'budgetCents': 30000,
              'neededBy': '2026-11-13',
              'createdAt': '2026-11-09T12:00:00Z',
            },
            {
              'id': 'r2',
              'title': 'Física Universitaria',
              'category': {'slug': 'libros', 'name': 'Libros'},
              'budgetCents': 40000,
              'neededBy': null,
              'createdAt': '2026-11-09T11:00:00Z',
            },
          ],
          'nextCursor': null,
        }),
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
    // "Populares" llega con HU-49.
    expect(feed.popular, isEmpty);
    // "Se busca" sale del tablero (HU-15).
    expect(feed.wanted.map((w) => (w.id, w.category)), [
      ('r1', 'laboratorio'),
      ('r2', 'libros'),
    ]);
    expect(feed.wanted.first.neededBy, DateTime(2026, 11, 13));
    expect(feed.wanted.last.neededBy, isNull);
    final wanted = adapter.requests.firstWhere(
      (r) => r.path == ApiPaths.wanted,
    );
    expect(wanted.queryParameters, {
      'limit': HttpCatalogRepository.wantedCount,
    });

    final products = adapter.requests.firstWhere(
      (r) => r.path == ApiPaths.products,
    );
    expect(products.queryParameters, {'limit': HttpCatalogRepository.pageSize});
  });

  test('el filtro de Inicio va en la consulta', () async {
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

  test('si el tablero falla, Inicio sale sin "Se busca"', () async {
    serve(wantedStatus: 503);

    final feed = await repository.homeFeed(period: PopularPeriod.today);

    expect(feed.wanted, isEmpty);
    expect(feed.recent, hasLength(1));
  });

  test('un error llega como ApiFailure', () async {
    serve(status: 503);

    expect(
      () => repository.homeFeed(period: PopularPeriod.today),
      throwsA(isA<ApiFailure>()),
    );
  });

  test('categories lee la fila 72', () async {
    serve();

    final categories = await repository.categories();

    expect(categories.map((c) => c.slug), ['calculadoras', 'electronica']);
    expect(categories.first.name, 'Calculadoras');
    expect(categories.first.photoUrl, 'asset:assets/products/casio.webp');
  });

  group('buscar (HU-09)', () {
    test('manda q recortado, limit y pagina; lee la pagina', () async {
      serve(nextCursor: 'next');

      final page = await repository.search(query: '  calculadora  ', page: 2);

      final request = adapter.requests.single;
      expect(request.path, ApiPaths.products);
      expect(request.queryParameters, {
        'q': 'calculadora',
        'hideSoldOut': true,
        'sort': 'relevance',
        'limit': searchPageSize,
        'page': 2,
      });
      expect(page.items.single.title, startsWith('Calculadora'));
      expect(page.total, 48);
      expect(page.nextCursor, 'next');
    });

    test('los filtros de HU-10 van en la consulta', () async {
      serve();

      await repository.search(
        query: 'calculadora',
        filter: const SearchFilter(
          categories: ['calculadoras', 'libros'],
          minCents: 30000,
          maxCents: 70000,
          condition: ProductConditionFilter.used,
        ),
      );

      expect(adapter.requests.single.queryParameters, {
        'q': 'calculadora',
        'category': ['calculadoras', 'libros'],
        'minPriceCents': 30000,
        'maxPriceCents': 70000,
        'condition': 'used',
        'hideSoldOut': true,
        'sort': 'relevance',
        'limit': searchPageSize,
        'page': 1,
      });
    });

    test('el orden elegido va como sort', () async {
      serve();

      await repository.search(query: 'calculadora', sort: SearchSort.priceAsc);

      expect(adapter.requests.single.queryParameters['sort'], 'priceAsc');
    });

    test('apagar Ocultar agotados manda hideSoldOut=false', () async {
      serve();

      await repository.search(
        query: 'calculadora',
        filter: const SearchFilter(hideSoldOut: false),
      );

      expect(adapter.requests.single.queryParameters['hideSoldOut'], isFalse);
    });

    test('400 listings.invalid_price_range llega con su code', () async {
      adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.json({
          'code': 'listings.invalid_price_range',
          'title': 'Elige un rango de precio válido.',
        }, status: 400),
      );
      repository = HttpCatalogRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
        Uri.parse('https://api.musubi.example'),
      );

      expect(
        () => repository.search(
          query: 'calculadora',
          filter: const SearchFilter(minCents: 80000, maxCents: 30000),
        ),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', 'listings.invalid_price_range')
              .having((f) => f.status, 'status', 400),
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
        () => repository.search(query: 'calc', page: 0),
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
