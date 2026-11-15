import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/features/marketplace/data/http_saved_search_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/saved_search.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/saved_search_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/saved_searches_screen.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_saved_searches.dart';

// HU-12: "Mis alertas" (Ajustes) y el cliente de /saved-searches.
void main() {
  final ti84 = SavedSearch(
    id: 's1',
    query: 'Calculadora TI-84',
    categories: const ['calculadoras'],
    maxCents: 200000,
    condition: 'used',
    expiresAt: DateTime.utc(2026, 12, 14, 18),
  );
  final bata = SavedSearch(
    id: 's2',
    query: 'bata',
    expiresAt: DateTime.utc(2026, 12, 1, 18),
  );

  Future<void> open(WidgetTester tester, FakeSavedSearchRepository repo) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: AppRoutes.settingsAlerts,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          builder: (_, _) => const Text('Ajustes'),
        ),
        GoRoute(
          path: AppRoutes.settingsAlerts,
          builder: (_, _) => const SavedSearchesScreen(),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          savedSearchRepositoryProvider.overrideWithValue(repo),
          categoriesProvider.overrideWith(
            (ref) async => const [
              CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
            ],
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('lista mis alertas con sus filtros y cuando vencen', (
    tester,
  ) async {
    await open(tester, FakeSavedSearchRepository(stored: [ti84, bata]));

    expect(find.text('Mis alertas'), findsOneWidget);
    expect(find.text('Calculadora TI-84'), findsOneWidget);
    expect(find.text(r'Calculadoras · Hasta $2,000 · Usado'), findsOneWidget);
    expect(find.text('Vence el 14 dic'), findsOneWidget);
    expect(find.text('Cualquier categoría y precio'), findsOneWidget);
  });

  testWidgets('"Quitar" la borra y avisa', (tester) async {
    final repo = FakeSavedSearchRepository(stored: [ti84, bata]);
    await open(tester, repo);

    await tester.tap(find.byKey(const Key('alert-remove-s1')));
    await tester.pumpAndSettle();

    expect(repo.removed, ['s1']);
    expect(find.text('Calculadora TI-84'), findsNothing);
    expect(find.text('Quitamos la alerta de «Calculadora TI-84»'), findsOne);
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('sin alertas explica como crearlas', (tester) async {
    await open(tester, FakeSavedSearchRepository());

    expect(find.text('No tienes alertas'), findsOneWidget);
  });

  testWidgets('el resumen cubre cada combinacion de filtros', (tester) async {
    String summary(SavedSearch search) =>
        SavedSearchesScreen.summary(search, const {'libros': 'Libros'});
    SavedSearch with_({int? min, int? max}) => SavedSearch(
      id: 'x',
      query: 'x',
      categories: const ['libros', 'dibujo'],
      minCents: min,
      maxCents: max,
      expiresAt: DateTime.utc(2026, 12),
    );

    expect(summary(with_(min: 10000)), r'Libros · dibujo · Desde $100');
    expect(
      summary(with_(min: 10000, max: 50000)),
      r'Libros · dibujo · $100 a $500',
    );
  });

  group('HttpSavedSearchRepository', () {
    late FakeHttpAdapter adapter;
    late HttpSavedSearchRepository repository;

    Map<String, dynamic> json(String id) => {
      'id': id,
      'query': 'Calculadora TI-84',
      'categories': ['calculadoras'],
      'minPriceCents': null,
      'maxPriceCents': 200000,
      'condition': 'used',
      'createdAt': '2026-11-14T18:00:00Z',
      'expiresAt': '2026-12-14T18:00:00Z',
    };

    void serve(ResponseBody Function(RequestOptions options) response) {
      adapter = FakeHttpAdapter((options) async => response(options));
      repository = HttpSavedSearchRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
      );
    }

    test('guardar manda la busqueda y sus filtros; 201 es nueva', () async {
      serve((_) => FakeHttpAdapter.json(json('s1'), status: 201));

      final saved = await repository.save(
        query: ' Calculadora TI-84 ',
        filter: const SearchFilter(
          categories: ['calculadoras'],
          maxCents: 200000,
          condition: ProductConditionFilter.used,
        ),
      );

      final request = adapter.requests.single;
      expect(request.path, ApiPaths.savedSearches);
      expect(request.data, {
        'q': 'Calculadora TI-84',
        'category': ['calculadoras'],
        'maxPriceCents': 200000,
        'condition': 'used',
      });
      expect(saved.created, isTrue);
      expect(
        (saved.search.id, saved.search.maxCents, saved.search.condition),
        ('s1', 200000, 'used'),
      );
    });

    test('200 es que ya la tenia', () async {
      serve((_) => FakeHttpAdapter.json(json('s1')));

      final saved = await repository.save(query: 'Calculadora TI-84');

      expect(saved.created, isFalse);
      expect(adapter.requests.single.data, {'q': 'Calculadora TI-84'});
    });

    test('mis alertas y quitar', () async {
      serve(
        (options) => options.method == 'DELETE'
            ? FakeHttpAdapter.json(const <String, dynamic>{}, status: 204)
            : FakeHttpAdapter.json({
                'items': [json('s1'), json('s2')],
              }),
      );

      final mine = await repository.mine();
      await repository.remove('s2');

      expect(mine.map((s) => s.id), ['s1', 's2']);
      expect(mine.first.expiresAt, DateTime.utc(2026, 12, 14, 18));
      expect(adapter.requests.last.path, ApiPaths.savedSearch('s2'));
      expect(adapter.requests.last.method, 'DELETE');
    });
  });
}
