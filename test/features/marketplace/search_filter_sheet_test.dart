import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/search_filter_sheet.dart';

// HU-10: la hoja `Busqueda-filtros` sin red (categorias del fake).
void main() {
  final categories = [
    const CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
    const CatalogCategory(slug: 'libros', name: 'Libros'),
  ];

  Widget app({SearchFilter initial = const SearchFilter()}) => ProviderScope(
    overrides: [categoriesProvider.overrideWith((ref) async => categories)],
    child: MaterialApp(
      home: Scaffold(body: SearchFilterSheet(initial: initial)),
    ),
  );

  testWidgets('muestra categorias, precio y estado', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Filtros'), findsOneWidget);
    expect(find.text('Calculadoras'), findsOneWidget);
    expect(find.text('Libros'), findsOneWidget);
    expect(find.text('Mínimo'), findsOneWidget);
    expect(find.text('Máximo'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Nuevo'), findsOneWidget);
    expect(find.text('Usado'), findsOneWidget);
  });

  testWidgets('un minimo mayor que el maximo muestra el error', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('filter-min')), '800');
    await tester.enterText(find.byKey(const Key('filter-max')), '300');
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();

    expect(
      find.text('El máximo debe ser mayor o igual que el mínimo.'),
      findsOneWidget,
    );
    expect(find.byType(SearchFilterSheet), findsOneWidget);
  });

  testWidgets('devuelve categoria, precio y estado', (tester) async {
    SearchFilter? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoriesProvider.overrideWith((ref) async => categories)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showSearchFilterSheet(
                    context,
                    initial: const SearchFilter(),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Calculadoras'));
    await tester.enterText(find.byKey(const Key('filter-min')), '300');
    await tester.enterText(find.byKey(const Key('filter-max')), '700');
    await tester.tap(find.text('Usado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();

    expect(
      result,
      const SearchFilter(
        category: 'calculadoras',
        minCents: 30000,
        maxCents: 70000,
        condition: ProductConditionFilter.used,
      ),
    );
  });

  testWidgets('limpiar deja la hoja vacia', (tester) async {
    SearchFilter? result;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [categoriesProvider.overrideWith((ref) async => categories)],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await showSearchFilterSheet(
                    context,
                    initial: const SearchFilter(category: 'libros'),
                  );
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpiar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();

    expect(result, const SearchFilter());
  });
}
