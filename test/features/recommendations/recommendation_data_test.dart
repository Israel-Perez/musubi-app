import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/recommendations/data/http_recommendation_repository.dart';
import 'package:musubi_app/features/recommendations/domain/recommendation_models.dart';

import '../../helpers/fake_http_adapter.dart';

Map<String, Object?> _product(String id) => {
  'id': id,
  'title': 'Calculadora Casio fx-82',
  'description': 'Para Cálculo.',
  'category': 'calculadoras',
  'priceCents': 28000,
  'condition': 'used',
  'conditionDetail': 'good',
  'stock': 1,
  'status': 'active',
  'photos': ['/media/products/a/b.webp'],
  'seller': {'name': 'Diego H.'},
  'publishedAt': '2026-11-14T12:00:00Z',
  'soldAt': null,
};

// HU-35: el repositorio habla las filas "M-11" de musubi-api.
void main() {
  late FakeHttpAdapter adapter;
  late HttpRecommendationRepository repository;

  void serve(ResponseBody Function(RequestOptions options) response) {
    adapter = FakeHttpAdapter((options) async => response(options));
    repository = HttpRecommendationRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );
  }

  test('"Recomendado para ti" lee las tarjetas y la base', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'items': [_product('p1'), _product('p2')],
        'basis': 'personal',
      }),
    );

    final page = await repository.forYou(limit: 5);

    expect(adapter.requests.single.path, ApiPaths.recommendations);
    expect(adapter.requests.single.queryParameters, {'limit': 5});
    expect(page.basis, RecommendationBasis.personal);
    expect(page.items.map((p) => p.id), ['p1', 'p2']);
    expect(
      page.items.first.photoUrl,
      'https://api.musubi.example/media/products/a/b.webp',
    );
    expect(page.items.first.sellerName, 'Diego H.');
  });

  test(
    '"Ver parecidos" pide la publicacion y sin limite no lo manda',
    () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'items': [_product('p2')],
          'basis': 'similar',
        }),
      );

      final page = await repository.similar('p1');

      expect(adapter.requests.single.path, ApiPaths.productSimilar('p1'));
      expect(adapter.requests.single.path, '/api/v1/products/p1/similar');
      expect(adapter.requests.single.queryParameters, isEmpty);
      expect(page.basis, RecommendationBasis.similar);
    },
  );

  test('una base que no conoce es general', () {
    expect(RecommendationBasis.parse('otra'), RecommendationBasis.general);
    expect(RecommendationBasis.parse(null), RecommendationBasis.general);
  });

  test('si la publicacion ya no existe llega como ApiFailure', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'code': 'listings.product_not_found',
        'title': 'Esta publicación ya no está disponible.',
        'status': 404,
      }, status: 404),
    );

    await expectLater(
      repository.similar('p9'),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'listings.product_not_found',
        ),
      ),
    );
  });
}
