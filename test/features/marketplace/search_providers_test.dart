import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    expect(state.page, 1);
    expect(state.pageCount, 1);
    expect(fake.queries, ['calculadora']);
    expect(fake.pages, [1]);
  });

  test('sin texto lista todo el catalogo', () async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 1),
      ],
    );
    final container = containerFor(fake);

    await container.read(searchControllerProvider.notifier).search('   ');

    expect(fake.queries, ['']);
    expect(container.read(searchControllerProvider).value!.items, hasLength(1));
  });

  test('cambiar de pagina pide esa pagina', () async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 25),
        ProductPage(items: [product('p2')], total: 25),
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('casio');
    expect(container.read(searchControllerProvider).value!.pageCount, 2);

    await notifier.goToPage(2);

    final state = container.read(searchControllerProvider).value!;
    expect(state.page, 2);
    expect(state.items.single.id, 'p2');
    expect(fake.pages, [1, 2]);
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

  test('si falla el cambio de pagina, el estado queda en error', () async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 25),
        offlineFailure,
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('casio');
    await notifier.goToPage(2);

    expect(
      container.read(searchControllerProvider),
      isA<AsyncError<SearchState>>(),
    );
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
      categories: ['calculadoras'],
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
    const filter = SearchFilter(categories: ['libros']);
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1')], total: 25),
        ProductPage(items: [product('p2')], total: 25),
      ],
    );
    final container = containerFor(fake);
    final notifier = container.read(searchControllerProvider.notifier);

    await notifier.search('casio', filter: filter);
    await notifier.goToPage(2);

    expect(fake.searchFilters, [filter, filter]);
    expect(container.read(searchControllerProvider).value!.filter, filter);
  });

  test('sin texto, los filtros exploran el catalogo', () async {
    const filter = SearchFilter(categories: ['libros']);
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

  test('limpiar lista el catalogo sin texto', () async {
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
    expect(state.items, hasLength(1));
    expect(fake.queries, ['casio', '']);
  });
}
