import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/data/http_comparison_repository.dart';
import 'package:musubi_app/features/marketplace/domain/comparison.dart';

import '../../helpers/fake_comparison.dart';
import '../../helpers/fake_http_adapter.dart';

// HU-51: "Compara antes de comprar" con las reglas de la maqueta
// (`compareVals` de docs/maqueta). Los ordenes esperados salen de correr esa
// funcion con la Casio de Valeria ($450).
void main() {
  final comparison = Comparison(45000, casioOptions());

  List<String> order(CompareOrder by) => [
    for (final o in comparison.ranked(by)) o.option.product.id,
  ];

  test('"Para ti" combina reputación, ventas y precio, como la maqueta', () {
    expect(order(CompareOrder.forYou), ['c2', 'c4', 'c3', 'c5', 'c1']);
    final ranked = comparison.ranked(CompareOrder.forYou);
    expect(ranked.first.best, isTrue);
    expect(ranked.skip(1).any((o) => o.best), isFalse);
    expect([for (final o in ranked) o.rank], [1, 2, 3, 4, 5]);
  });

  test('cada pestaña ordena por lo suyo y solo "Para ti" tiene la mejor', () {
    expect(order(CompareOrder.reputation), ['c2', 'c3', 'c4', 'c5', 'c1']);
    expect(order(CompareOrder.sales), ['c5', 'c2', 'c4', 'c3', 'c1']);
    expect(order(CompareOrder.price), ['c4', 'c2', 'c1', 'c3', 'c5']);
    for (final by in [
      CompareOrder.reputation,
      CompareOrder.sales,
      CompareOrder.price,
    ]) {
      expect(comparison.ranked(by).any((o) => o.best), isFalse);
    }
  });

  test('las insignias: mejor reputación, más ventas y precio más bajo', () {
    final badges = {
      for (final o in comparison.ranked(CompareOrder.forYou))
        o.option.product.id: o.badge,
    };

    expect(badges, {
      'c2': CompareBadge.bestReputation,
      'c4': CompareBadge.lowestPrice,
      'c3': null,
      'c5': CompareBadge.mostSales,
      'c1': null,
    });
  });

  test('con una sola opción no hay insignias', () {
    final alone = Comparison(45000, [casioOptions().first]);

    expect(alone.ranked(CompareOrder.forYou).single.badge, isNull);
  });

  test('la diferencia de precio es contra la publicación que se ve', () {
    final byId = {
      for (final o in comparison.ranked(CompareOrder.forYou))
        o.option.product.id: o.differenceCents,
    };

    expect(byId['c1'], 3000);
    expect(byId['c2'], -5000);
  });

  test(r'la barra usa el mismo modelo: precio justo con promedio de $443', () {
    final band = comparison.priceBand!;

    expect((band.minCents, band.maxCents), (40000, 48000));
    expect(band.averageCents, 44300);
    expect(band.currentPercent, 63);
    expect(band.otherPercents, [100, 0]);
    expect(band.verdict, PriceVerdict.fair);
    expect(band.sameModel, isTrue);
  });

  test('sin el mismo modelo, la barra es de la categoría', () {
    final others = [
      for (final o in casioOptions())
        ComparisonOption(product: o.product, seller: o.seller),
    ];
    final cheap = Comparison(30000, others).priceBand!;
    final pricey = Comparison(70000, others).priceBand!;

    expect(cheap.sameModel, isFalse);
    expect(cheap.verdict, PriceVerdict.good);
    expect(pricey.verdict, PriceVerdict.high);
  });

  test('sin calificaciones pesa como 4.5 con 10 opiniones', () {
    const nobody = ComparisonSeller(id: 'x', name: 'Ana R.');
    const many = ComparisonSeller(
      id: 'y',
      name: 'Diego H.',
      ratingAvg: 4.9,
      ratingCount: 32,
    );

    expect(Comparison.weightedReputation(nobody), 4.5);
    expect(Comparison.weightedReputation(many), closeTo(4.805, 0.001));
  });

  test('"Ver todas" según la categoría', () {
    expect(seeAllLabel('Calculadoras'), 'Ver todas las calculadoras');
    expect(seeAllLabel('Electrónica'), 'Ver toda la electrónica');
    expect(seeAllLabel('Otra'), 'Ver más como este');
  });

  group('HttpComparisonRepository', () {
    final base = Uri.parse('https://api.musubi.test');
    Dio dio(FakeHttpAdapter adapter) =>
        Dio(BaseOptions(baseUrl: base.toString()))..httpClientAdapter = adapter;

    test(
      'compare lee las opciones con quien vende y el mismo modelo',
      () async {
        final adapter = FakeHttpAdapter(
          (_) async => FakeHttpAdapter.json({
            'items': [
              {
                'product': {
                  'id': 'c1',
                  'title': 'Casio fx-991ES Plus con tapa',
                  'description': 'Incluye pilas.',
                  'category': 'calculadoras',
                  'priceCents': 42000,
                  'condition': 'used',
                  'conditionDetail': 'good',
                  'stock': 1,
                  'status': 'active',
                  'photos': ['/media/products/u1/a.webp'],
                  'seller': {'name': 'Luis M.'},
                  'publishedAt': '2026-11-14T12:00:00Z',
                  'soldAt': null,
                },
                'seller': {
                  'id': 'u1',
                  'name': 'Luis M.',
                  'ratingAvg': 4.8,
                  'ratingCount': 12,
                  'sales': null,
                },
                'sameModel': true,
              },
            ],
          }),
        );

        final options = await HttpComparisonRepository(
          dio(adapter),
          base,
        ).compare('p1');

        expect(adapter.requests.single.path, '/api/v1/products/p1/compare');
        final option = options.single;
        expect(option.product.title, 'Casio fx-991ES Plus con tapa');
        expect(
          option.product.photoUrl,
          'https://api.musubi.test/media/products/u1/a.webp',
        );
        expect(option.product.condition, 'Usado');
        expect((option.seller.name, option.seller.ratingAvg), ('Luis M.', 4.8));
        expect((option.seller.ratingCount, option.seller.sales), (12, null));
        expect(option.sameModel, isTrue);
      },
    );

    test(
      'el aviso: GET dice si lo tengo, PUT lo pide y DELETE lo quita',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => options.method == 'DELETE'
              ? ResponseBody.fromString('', 204)
              : FakeHttpAdapter.json({'active': true}),
        );
        final repository = HttpComparisonRepository(dio(adapter), base);

        expect(await repository.stockAlert('p1'), isTrue);
        await repository.watch('p1');
        await repository.unwatch('p1');

        expect(
          [for (final r in adapter.requests) '${r.method} ${r.path}'],
          [
            'GET /api/v1/products/p1/stock-alert',
            'PUT /api/v1/products/p1/stock-alert',
            'DELETE /api/v1/products/p1/stock-alert',
          ],
        );
      },
    );

    test(
      'la estimación del modelo (HU-58): rango y veredicto, o nada',
      () async {
        final adapter = FakeHttpAdapter(
          (options) async => options.path.contains('p1')
              ? FakeHttpAdapter.json({
                  'minCents': 40000,
                  'maxCents': 52000,
                  'samples': 31,
                  'verdict': 'high',
                })
              : FakeHttpAdapter.json({
                  'minCents': null,
                  'maxCents': null,
                  'samples': 3,
                  'verdict': null,
                }),
        );
        final repository = HttpComparisonRepository(dio(adapter), base);

        final estimate = await repository.estimate('p1');
        final none = await repository.estimate('p2');

        expect(
          (estimate?.minCents, estimate?.maxCents, estimate?.verdict),
          (40000, 52000, PriceVerdict.high),
        );
        expect(none, isNull);
        expect(
          adapter.requests.first.path,
          '/api/v1/products/p1/price-estimate',
        );
      },
    );

    test('un 409 llega como ApiFailure con su código', () async {
      final adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.json({
          'code': 'listings.product_available',
          'title': 'Esta publicación ya está disponible.',
        }, status: 409),
      );

      await expectLater(
        HttpComparisonRepository(dio(adapter), base).watch('p1'),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'listings.product_available',
          ),
        ),
      );
    });
  });
}
