import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/widgets/musubi_controls.dart';
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

  testWidgets('las categorias van en fila, no apiladas', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final first = tester.getTopLeft(find.text('Calculadoras'));
    final second = tester.getTopLeft(find.text('Libros'));

    expect(second.dy, first.dy);
    expect(second.dx, greaterThan(first.dx));
  });

  testWidgets('tiene el control deslizante de precio y el interruptor', (
    tester,
  ) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final slider = tester.widget<RangeSlider>(find.byType(RangeSlider));
    expect(slider.max, 2000);
    expect(find.text('Ocultar agotados'), findsOneWidget);
  });

  testWidgets('apagar Ocultar agotados se aplica al filtro', (tester) async {
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

    await tester.ensureVisible(find.byType(MusubiSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MusubiSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();

    expect(result?.hideSoldOut, isFalse);
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
        categories: ['calculadoras'],
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
                    initial: const SearchFilter(categories: ['libros']),
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
    await tester.pump(const Duration(seconds: 3));

    expect(result, const SearchFilter());
  });

  testWidgets('limpiar avisa con un toast', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Limpiar'));
    await tester.pump();

    expect(find.text('Filtros borrados'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('varias categorias se acumulan', (tester) async {
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
    await tester.tap(find.text('Libros'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();

    expect(result?.categories, ['calculadoras', 'libros']);
  });

  testWidgets('tocar la categoria elegida la quita', (tester) async {
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
    await tester.pumpAndSettle();
    await tester.tap(find.text('Calculadoras'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver resultados'));
    await tester.pumpAndSettle();

    expect(result?.categories, isEmpty);
  });

  testWidgets('el histograma recolorea las barras del rango', (tester) async {
    await tester.pumpWidget(
      app(initial: const SearchFilter(minCents: 40000, maxCents: 60000)),
    );
    await tester.pumpAndSettle();

    final colors = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('price-histogram')),
            matching: find.byType(Container),
          ),
        )
        .map((bar) => (bar.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .toList();
    final counts = <Color, int>{};
    for (final color in colors) {
      counts[color] = (counts[color] ?? 0) + 1;
    }

    expect(colors, hasLength(11));
    expect(counts.values.toList()..sort(), [2, 9]);
  });

  testWidgets('sin rango el histograma no resalta barras', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final colors = tester
        .widgetList<Container>(
          find.descendant(
            of: find.byKey(const Key('price-histogram')),
            matching: find.byType(Container),
          ),
        )
        .map((bar) => (bar.decoration as BoxDecoration?)?.color)
        .whereType<Color>()
        .toSet();

    expect(colors, hasLength(1));
  });
}
