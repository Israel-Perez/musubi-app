import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/widgets/musubi_controls.dart';
import 'package:musubi_app/core/widgets/pressable.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/search_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/search_screen.dart';

import '../../helpers/fake_catalog_repository.dart';

// HU-10: hoja `Busqueda-filtros` (categoria, precio, estado y agotados).
void main() {
  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!
        .reset(),
  );

  const categories = [
    CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
    CatalogCategory(slug: 'libros', name: 'Libros'),
    CatalogCategory(slug: 'laptops', name: 'Laptops'),
  ];

  FakeCatalogRepository repository({ApiFailure? categoriesFailure}) {
    final fake =
        FakeCatalogRepository(
            [const HomeFeed()],
            [const ProductPage(total: 12)],
          )
          ..categoriesResponse = categories
          ..categoriesFailure = categoriesFailure;
    return fake;
  }

  Future<ProviderContainer> open(
    WidgetTester tester,
    FakeCatalogRepository fake,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [catalogRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('search-filter')));
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(SearchScreen)));
  }

  /// Si la pastilla u opcion con ese texto esta marcada.
  bool selected(WidgetTester tester, String label) =>
      tester
          .widget<Pressable>(
            find
                .ancestor(
                  of: find.text(label),
                  matching: find.byType(Pressable),
                )
                .first,
          )
          .selected ??
      false;

  testWidgets('una categoria, el CTA con el total y el filtro aplicado', (
    tester,
  ) async {
    final fake = repository();
    final container = await open(tester, fake);

    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Ver 12 resultados'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Libros'));
    await tester.pumpAndSettle();

    expect(selected(tester, 'Libros'), isTrue);

    await tester.tap(find.text('Todo'));
    await tester.pumpAndSettle();
    expect(selected(tester, 'Todo'), isTrue);
    expect(selected(tester, 'Libros'), isFalse);

    await tester.tap(find.bySemanticsLabel('Libros'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ver 12 resultados'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-filter-sheet')), findsNothing);
    expect(
      container.read(searchControllerProvider).value!.filter.category,
      'libros',
    );
    expect(fake.searchFilters.last.category, 'libros');
  });

  testWidgets('el estado segmentado manda condition y marca una sola opcion', (
    tester,
  ) async {
    final fake = repository();
    final container = await open(tester, fake);

    await tester.ensureVisible(find.bySemanticsLabel('Usado'));
    await tester.tap(find.bySemanticsLabel('Usado'));
    await tester.pumpAndSettle();
    expect(selected(tester, 'Usado'), isTrue);
    expect(selected(tester, 'Todos'), isFalse);

    await tester.tap(find.textContaining('Ver'));
    await tester.pumpAndSettle();

    expect(
      container.read(searchControllerProvider).value!.filter.condition,
      'used',
    );
  });

  testWidgets('Ocultar agotados viaja al filtro', (tester) async {
    final fake = repository();
    final container = await open(tester, fake);

    await tester.ensureVisible(find.byType(MusubiSwitch));
    await tester.tap(find.byType(MusubiSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Ver'));
    await tester.pumpAndSettle();

    expect(
      container.read(searchControllerProvider).value!.filter.hideSoldOut,
      isTrue,
    );
  });

  testWidgets('un rango invalido muestra el error y no aplica', (tester) async {
    final fake = repository();
    final container = await open(tester, fake);

    await tester.enterText(find.byKey(const Key('filter-min')), '900');
    await tester.enterText(find.byKey(const Key('filter-max')), '100');
    await tester.pumpAndSettle();
    final calls = fake.queries.length;

    await tester.tap(find.textContaining('Ver'));
    await tester.pumpAndSettle();

    expect(
      find.text('El mínimo no puede ser mayor que el máximo.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('search-filter-sheet')), findsOneWidget);
    expect(container.read(searchControllerProvider).value!.filter.count, 0);
    expect(fake.queries.length, calls);
  });

  testWidgets(r'un precio mayor a $999,999 muestra el error', (tester) async {
    await open(tester, repository());

    await tester.enterText(find.byKey(const Key('filter-min')), '1000000');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Ver'));
    await tester.pumpAndSettle();

    expect(find.text(r'El precio no puede pasar de $999,999.'), findsOneWidget);
  });

  testWidgets('la X cierra sin cambiar el filtro aplicado', (tester) async {
    final fake = repository();
    final container = await open(tester, fake);

    await tester.tap(find.bySemanticsLabel('Libros'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('panel-close')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('search-filter-sheet')), findsNothing);
    expect(container.read(searchControllerProvider).value!.filter.count, 0);
  });

  testWidgets('Limpiar reinicia el borrador', (tester) async {
    await open(tester, repository());

    await tester.tap(find.bySemanticsLabel('Libros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();

    expect(selected(tester, 'Todo'), isTrue);
  });

  testWidgets('si fallan las categorias, avisa y Reintentar las carga', (
    tester,
  ) async {
    final fake = repository(categoriesFailure: offlineFailure);
    await open(tester, fake);

    expect(find.text('No pudimos cargar las categorías.'), findsOneWidget);

    fake.categoriesFailure = null;
    await tester.tap(find.bySemanticsLabel('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Libros'), findsOneWidget);
  });
}
