import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/search_providers.dart';

import '../../helpers/fake_catalog_repository.dart';

// HU-09: primera pagina, "Cargar mas" y errores de la busqueda.
void main() {
  ProductSummary product(String id) =>
      ProductSummary(id: id, title: id, priceCents: 100, stock: 1);

  ProviderContainer containerFor(FakeCatalogRepository fake) =>
      ProviderContainer.test(
        overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
      )..listen(searchControllerProvider, (_, _) {});

  test('la primera pagina llena el estado y recorta el texto', () async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 1, nextCursor: 'next'),
      ],
    );
    final container = containerFor(fake);

    await container
        .read(searchControllerProvider.notifier)
        .search('  calculadora  ');

    final state = container.read(searchControllerProvider).value!;
    expect(state.query, 'calculadora');
    expect(state.items.single.id, 'p1');
    expect(state.total, 1);
    expect(state.hasMore, isTrue);
    expect(fake.queries, ['calculadora']);
    expect(fake.cursors, [null]);
  });

  test('texto vacio no llama a la API', () async {
    final fake = FakeCatalogRepository();
    final container = containerFor(fake);

    await container.read(searchControllerProvider.notifier).search('   ');

    expect(fake.queries, isEmpty);
    expect(container.read(searchControllerProvider).value!.query, isEmpty);
  });

  test('cargar mas acumula y conserva el total', () async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 2, nextCursor: 'c1'),
        ProductPage(items: [product('p2')], total: 2),
      ],
    );
    final container = containerFor(fake);

    await container.read(searchControllerProvider.notifier).search('casio');
    await container.read(searchControllerProvider.notifier).loadMore();

    final state = container.read(searchControllerProvider).value!;
    expect(state.items.map((p) => p.id), ['p1', 'p2']);
    expect(state.total, 2);
    expect(state.hasMore, isFalse);
    expect(fake.cursors, [null, 'c1']);
  });

  test('un error deja el estado en AsyncError', () async {
    final fake = FakeCatalogRepository([const HomeFeed()], [offlineFailure]);
    final container = containerFor(fake);

    await container.read(searchControllerProvider.notifier).search('casio');

    expect(
      container.read(searchControllerProvider),
      isA<AsyncError<SearchState>>(),
    );
  });

  test('si falla cargar mas, conserva las tarjetas', () async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 2, nextCursor: 'c1'),
        offlineFailure,
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('casio');
    await expectLater(notifier.loadMore(), throwsA(isA<ApiFailure>()));

    final state = container.read(searchControllerProvider).value!;
    expect(state.items.map((p) => p.id), ['p1']);
    expect(state.loadingMore, isFalse);
  });

  test('mientras llega la nueva busqueda conserva las tarjetas', () async {
    final pending = Completer<ProductPage>();
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 1),
        pending,
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('calc');
    final next = notifier.search('calcu');

    final state = container.read(searchControllerProvider).value!;
    expect(state.query, 'calc');
    expect(state.items.single.id, 'p1');

    pending.complete(const ProductPage());
    await next;
  });

  test('una respuesta vieja no pisa la busqueda nueva', () async {
    final first = Completer<ProductPage>();
    final second = Completer<ProductPage>();
    final fake = FakeCatalogRepository([const HomeFeed()], [first, second]);
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    final oldSearch = notifier.search('calc');
    final newSearch = notifier.search('calcu');
    second.complete(ProductPage(items: [product('p2')], total: 1));
    await newSearch;
    first.complete(ProductPage(items: [product('p1')], total: 1));
    await oldSearch;

    final state = container.read(searchControllerProvider).value!;
    expect(state.query, 'calcu');
    expect(state.items.single.id, 'p2');
  });

  test('aplicar filtro relanza con el texto actual y lo guarda', () async {
    const filter = SearchFilter(
      category: 'calculadoras',
      minCents: 30000,
      maxCents: 70000,
      condition: ProductConditionFilter.used,
    );
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 1),
        ProductPage(items: [product('p2')], total: 1),
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('casio');
    await notifier.applyFilter(filter);

    final state = container.read(searchControllerProvider).value!;
    expect(state.query, 'casio');
    expect(state.filter, filter);
    expect(state.items.single.id, 'p2');
    expect(fake.queries, ['casio', 'casio']);
    expect(fake.searchFilters, [const SearchFilter(), filter]);
  });

  test('cargar mas conserva el filtro', () async {
    const filter = SearchFilter(category: 'libros');
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 2, nextCursor: 'c1'),
        ProductPage(items: [product('p2')], total: 2),
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('casio', filter: filter);
    await notifier.loadMore();

    expect(fake.searchFilters, [filter, filter]);
    expect(container.read(searchControllerProvider).value!.filter, filter);
  });

  test('sin texto, los filtros exploran el catalogo', () async {
    const filter = SearchFilter(category: 'libros');
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 1),
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.applyFilter(filter);

    final state = container.read(searchControllerProvider).value!;
    expect(state.query, isEmpty);
    expect(state.filter, filter);
    expect(state.items.single.id, 'p1');
    expect(state.hasCriteria, isTrue);
    expect(fake.queries, ['']);
    expect(fake.searchFilters, [filter]);
  });

  test('limpiar conserva el filtro', () async {
    const filter = SearchFilter(condition: ProductConditionFilter.used);
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 1),
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('casio', filter: filter);
    await notifier.clear();

    final state = container.read(searchControllerProvider).value!;
    expect(state.query, isEmpty);
    expect(state.filter, filter);
  });

  test('limpiar vuelve al estado inicial', () async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 1),
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('casio');
    await notifier.clear();

    final state = container.read(searchControllerProvider).value!;
    expect(state.query, isEmpty);
    expect(state.items, isEmpty);
    expect(state.hasMore, isFalse);
  });
}
