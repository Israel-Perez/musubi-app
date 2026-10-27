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

  void serve({int status = 200}) {
    adapter = FakeHttpAdapter(
      (options) async => switch (options.path) {
        ApiPaths.products when status != 200 => FakeHttpAdapter.json({
          'title': 'Sin conexión',
          'code': 'server.unavailable',
        }, status: status),
        ApiPaths.products => FakeHttpAdapter.json({
          'items': [productJson()],
          'nextCursor': null,
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
}
