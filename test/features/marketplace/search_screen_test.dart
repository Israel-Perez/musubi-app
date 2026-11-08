import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/domain/search_sort.dart';
import 'package:musubi_app/features/marketplace/presentation/home_cards.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/search_screen.dart';

import '../../helpers/fake_catalog_repository.dart';

// HU-09: `Busqueda` y `Busqueda-vacia` con el fake del catalogo.
void main() {
  ProductSummary product(String id, String title) =>
      ProductSummary(id: id, title: title, priceCents: 45000, stock: 2);

  Future<void> open(WidgetTester tester, FakeCatalogRepository fake) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Con go_router: el detalle y el boton de regreso necesitan ruta.
  Future<GoRouter> openRouted(
    WidgetTester tester,
    FakeCatalogRepository fake,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutes.search,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('Inicio')),
        GoRoute(
          path: AppRoutes.search,
          builder: (_, _) => const SearchScreen(),
        ),
        GoRoute(
          path: '/producto/:id',
          builder: (_, state) => Text('Detalle ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> submit(WidgetTester tester, String text) async {
    await tester.enterText(find.byKey(const Key('search-input')), text);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
  }

  testWidgets('abre con el campo enfocado y la invitacion a buscar', (
    tester,
  ) async {
    await open(tester, FakeCatalogRepository());

    final field = tester.widget<TextField>(
      find.byKey(const Key('search-input')),
    );
    expect(field.focusNode!.hasFocus, isTrue);
    expect(find.text('Busca en tu campus'), findsOneWidget);
    expect(find.text('Busca lo que necesitas'), findsOneWidget);
  });

  testWidgets('el boton de regreso vuelve a Inicio', (tester) async {
    await openRouted(tester, FakeCatalogRepository());

    await tester.tap(find.bySemanticsLabel('Regresar'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
  });

  testWidgets('tocar una tarjeta abre el detalle', (tester) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
      ],
    );
    await openRouted(tester, fake);

    await submit(tester, 'calculadora');
    await tester.tap(find.text('Calculadora Casio'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle p1'), findsOneWidget);
  });

  testWidgets('escribir busca tras una pausa y reinicia el retardo', (
    tester,
  ) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
      ],
    );
    await open(tester, fake);
    final field = find.byKey(const Key('search-input'));

    await tester.enterText(field, 'c');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(field, 'calc');
    await tester.pump(const Duration(milliseconds: 200));

    expect(fake.queries, isEmpty);

    await tester.pump(const Duration(milliseconds: 150));
    await tester.pumpAndSettle();

    expect(fake.queries, ['calc']);
    expect(find.text('Calculadora Casio'), findsOneWidget);
  });

  testWidgets('borrar el texto vuelve al inicio sin consultar', (tester) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
      ],
    );
    await open(tester, fake);

    await submit(tester, 'calculadora');
    await tester.enterText(find.byKey(const Key('search-input')), '');
    await tester.pump();

    expect(find.text('Busca lo que necesitas'), findsOneWidget);
    expect(fake.queries, ['calculadora']);
  });

  testWidgets('un 400 invalid_query muestra su mensaje y Reintentar', (
    tester,
  ) async {
    const failure = ApiFailure(
      code: 'listings.invalid_query',
      message: 'Escribe al menos una letra o un número.',
      status: 400,
    );
    await open(tester, FakeCatalogRepository([const HomeFeed()], [failure]));

    await submit(tester, '...');

    expect(
      find.text('Escribe al menos una letra o un número.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('un 5xx muestra su mensaje y Reintentar', (tester) async {
    const failure = ApiFailure(
      code: 'server.unavailable',
      message: 'El servicio no está disponible.',
      status: 503,
    );
    await open(tester, FakeCatalogRepository([const HomeFeed()], [failure]));

    await submit(tester, 'calculadora');

    expect(find.text('El servicio no está disponible.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('al volver y reabrir no conserva la busqueda', (tester) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
      ],
    );
    final router = await openRouted(tester, fake);

    await submit(tester, 'calculadora');
    expect(find.text('Calculadora Casio'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Regresar'));
    await tester.pumpAndSettle();
    expect(find.text('Inicio'), findsOneWidget);

    unawaited(router.push(AppRoutes.search));
    await tester.pumpAndSettle();

    expect(find.text('Busca lo que necesitas'), findsOneWidget);
    expect(find.text('Calculadora Casio'), findsNothing);
  });

  testWidgets('un visitante que guarda ve la hoja de cuenta', (tester) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
      ],
    );
    await open(tester, fake);

    await submit(tester, 'calculadora');
    await tester.tap(find.byType(SaveButton));
    await tester.pumpAndSettle();

    expect(find.text('Guarda lo que te gusta'), findsOneWidget);
  });

  testWidgets('enviar muestra el contador y las tarjetas', (tester) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(
          items: [product('p1', 'Calculadora Casio fx-991ES')],
          total: 1,
        ),
      ],
    );
    await open(tester, fake);

    await submit(tester, '  calculadora  ');

    expect(fake.queries, ['calculadora']);
    expect(find.text('1 resultado en'), findsOneWidget);
    expect(find.text('UTTT'), findsOneWidget);
    expect(find.text('Calculadora Casio fx-991ES'), findsOneWidget);
  });

  testWidgets('sin coincidencias muestra el vacio con el texto buscado', (
    tester,
  ) async {
    await open(
      tester,
      FakeCatalogRepository([const HomeFeed()], [const ProductPage()]),
    );

    await submit(tester, 'zzz');

    expect(find.text('Sin resultados para «zzz»'), findsOneWidget);
    expect(
      find.text('Prueba con otras palabras o publica lo que necesitas.'),
      findsOneWidget,
    );
  });

  testWidgets('un error muestra el mensaje y Reintentar vuelve a buscar', (
    tester,
  ) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        offlineFailure,
        ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
      ],
    );
    await open(tester, fake);

    await submit(tester, 'calculadora');

    expect(find.text('Sin conexión.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);

    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Calculadora Casio'), findsOneWidget);
    expect(fake.queries, ['calculadora', 'calculadora']);
  });

  testWidgets('mientras busca muestra el indicador de carga', (tester) async {
    final pending = Completer<ProductPage>();
    await open(tester, FakeCatalogRepository([const HomeFeed()], [pending]));

    await tester.enterText(find.byKey(const Key('search-input')), 'casio');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    pending.complete(const ProductPage());
    await tester.pumpAndSettle();
  });

  testWidgets('Cargar mas agrega la siguiente pagina', (tester) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(
          items: [product('p1', 'Producto uno')],
          total: 2,
          nextCursor: 'c1',
        ),
        ProductPage(items: [product('p2', 'Producto dos')], total: 2),
      ],
    );
    await open(tester, fake);

    await submit(tester, 'producto');
    expect(find.text('2 resultados en'), findsOneWidget);
    expect(find.text('Producto uno'), findsOneWidget);

    await tester.tap(find.text('Cargar más'));
    await tester.pumpAndSettle();

    expect(find.text('Producto uno'), findsOneWidget);
    expect(find.text('Producto dos'), findsOneWidget);
    expect(fake.cursors, [null, 'c1']);
  });

  testWidgets('si falla cargar mas, conserva las tarjetas y avisa', (
    tester,
  ) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(
          items: [product('p1', 'Producto uno')],
          total: 2,
          nextCursor: 'c1',
        ),
        Object(),
      ],
    );
    await open(tester, fake);

    await submit(tester, 'producto');
    await tester.tap(find.text('Cargar más'));
    await tester.pumpAndSettle();

    expect(find.text('Producto uno'), findsOneWidget);
    expect(
      find.text('No pudimos cargar más resultados. Inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('borrar la busqueda vuelve al estado inicial', (tester) async {
    await open(
      tester,
      FakeCatalogRepository(
        [const HomeFeed()],
        [
          ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
        ],
      ),
    );

    await submit(tester, 'calculadora');
    await tester.tap(find.bySemanticsLabel('Borrar búsqueda'));
    await tester.pumpAndSettle();

    expect(find.text('Busca lo que necesitas'), findsOneWidget);
    expect(find.text('Calculadora Casio'), findsNothing);
  });

  testWidgets('el boton de filtros abre la hoja con las categorias', (
    tester,
  ) async {
    final fake = FakeCatalogRepository()
      ..categoriesResponse = const [
        CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
      ];
    await open(tester, fake);

    await tester.tap(find.byKey(const Key('search-filter')));
    await tester.pumpAndSettle();

    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Calculadoras'), findsOneWidget);
  });

  testWidgets('aplicar categoria, precio y estado relanza la busqueda', (
    tester,
  ) async {
    final fake =
        FakeCatalogRepository(
            [const HomeFeed()],
            [
              ProductPage(
                items: [product('p1', 'Calculadora Casio')],
                total: 1,
              ),
              ProductPage(
                items: [product('p2', 'Calculadora Casio')],
                total: 1,
              ),
            ],
          )
          ..categoriesResponse = const [
            CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
          ];
    await open(tester, fake);
    await submit(tester, 'calculadora');

    await tester.tap(find.byKey(const Key('search-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculadoras'));
    await tester.enterText(find.byKey(const Key('filter-min')), '300');
    await tester.enterText(find.byKey(const Key('filter-max')), '700');
    await tester.tap(find.text('Usado'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver 1 resultado'));
    await tester.pumpAndSettle();

    expect(
      fake.searchFilters,
      contains(
        const SearchFilter(
          category: 'calculadoras',
          minCents: 30000,
          maxCents: 70000,
          condition: ProductConditionFilter.used,
        ),
      ),
    );
    expect(fake.queries.last, 'calculadora');
    expect(
      find.descendant(
        of: find.byKey(const Key('search-filter')),
        matching: find.text('3'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('filtrar sin texto muestra las publicaciones', (tester) async {
    final fake =
        FakeCatalogRepository(
            [const HomeFeed()],
            [
              ProductPage(
                items: [product('p1', 'Calculadora Casio')],
                total: 1,
              ),
            ],
          )
          ..categoriesResponse = const [
            CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
          ];
    await open(tester, fake);

    await tester.tap(find.byKey(const Key('search-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculadoras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver 1 resultado'));
    await tester.pumpAndSettle();

    expect(find.text('Calculadora Casio'), findsOneWidget);
    expect(fake.queries.last, isEmpty);
    expect(
      fake.searchFilters.last,
      const SearchFilter(category: 'calculadoras'),
    );
  });

  testWidgets('un precio minimo mayor que el maximo no se aplica', (
    tester,
  ) async {
    final fake =
        FakeCatalogRepository(
            [const HomeFeed()],
            [
              ProductPage(
                items: [product('p1', 'Calculadora Casio')],
                total: 1,
              ),
            ],
          )
          ..categoriesResponse = const [
            CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
          ];
    await open(tester, fake);
    await submit(tester, 'calculadora');

    await tester.tap(find.byKey(const Key('search-filter')));
    await tester.pumpAndSettle();
    final callsBefore = fake.searchFilters.length;
    await tester.enterText(find.byKey(const Key('filter-min')), '800');
    await tester.enterText(find.byKey(const Key('filter-max')), '300');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();

    expect(
      find.text('El máximo debe ser mayor o igual que el mínimo.'),
      findsOneWidget,
    );
    expect(fake.searchFilters.length, callsBefore);
  });

  testWidgets('el orden cambia y se manda a la API', (tester) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
      ],
    );
    await open(tester, fake);
    await submit(tester, 'calculadora');

    expect(find.text('Más relevantes'), findsOneWidget);
    await tester.tap(find.byKey(const Key('search-sort')));
    await tester.pumpAndSettle();
    expect(find.text('Ordenar por'), findsOneWidget);

    await tester.tap(find.text('Menor precio'));
    await tester.pumpAndSettle();

    expect(fake.sorts.last, SearchSort.priceAsc);
    expect(find.text('Menor precio'), findsOneWidget);
  });

  testWidgets('guarda y limpia el historial de busquedas', (tester) async {
    final fake = FakeCatalogRepository(
      [const HomeFeed()],
      [
        ProductPage(items: [product('p1', 'Calculadora Casio')], total: 1),
      ],
    );
    await open(tester, fake);

    await submit(tester, 'casio');
    expect(find.byKey(const Key('clear-history')), findsOneWidget);

    await tester.tap(find.byKey(const Key('clear-history')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('clear-history')), findsNothing);
  });
}
