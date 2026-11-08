import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

/// Lo que muestra la pantalla de busqueda (HU-09) con sus filtros (HU-10).
@immutable
class SearchState {
  const new({
    this.query = '',
    this.filter = const CatalogFilter(),
    this.items = const [],
    this.total = 0,
    this.nextCursor,
    this.loadingMore = false,
  });

  /// Texto aplicado (no el que se esta escribiendo).
  final String query;

  /// Filtros aplicados desde `Busqueda-filtros`.
  final CatalogFilter filter;
  final List<ProductSummary> items;
  final int total;
  final String? nextCursor;
  final bool loadingMore;

  bool get hasQuery => query.isNotEmpty;
  bool get hasFilters => filter.count > 0;

  /// Hay texto o filtros: la pantalla deja de ser la invitacion inicial.
  bool get hasCriteria => hasQuery || hasFilters;
  bool get empty => hasCriteria && items.isEmpty;
  bool get hasMore => nextCursor != null;
}

/// Busqueda de productos: primera pagina y "Cargar mas" (HU-09).
///
/// Sin reintento automatico de Riverpod 3: la pantalla trae "Reintentar".
final AsyncNotifierProvider<SearchController, SearchState>
searchControllerProvider = AsyncNotifierProvider<SearchController, SearchState>(
  SearchController.new,
  retry: (_, _) => null,
  isAutoDispose: true,
);

class SearchController extends AsyncNotifier<SearchState> {
  CatalogRepository get _repository => ref.read(catalogRepositoryProvider);

  /// Identifica la ultima busqueda; una respuesta atrasada se descarta.
  int _request = 0;

  @override
  SearchState build() => const SearchState();

  Future<void> search(String raw) => _search(
    query: raw.trim(),
    filter: state.value?.filter ?? const CatalogFilter(),
  );

  /// Aplica el filtro de la hoja y busca con el texto vigente.
  Future<void> applyFilter(CatalogFilter filter) =>
      _search(query: state.value?.query ?? '', filter: filter);

  Future<void> _search({
    required String query,
    required CatalogFilter filter,
  }) async {
    final request = ++_request;
    if (query.isEmpty && filter.count == 0) {
      state = const AsyncData(SearchState());
      return;
    }
    // Al escribir se conservan los resultados anteriores; solo la primera
    // busqueda muestra la pantalla de carga.
    if (state.value?.hasCriteria != true) {
      state = const AsyncLoading();
    }
    final result = await AsyncValue.guard(() async {
      final page = await _repository.search(query: query, filter: filter);
      return SearchState(
        query: query,
        filter: filter,
        items: page.items,
        total: page.total,
        nextCursor: page.nextCursor,
      );
    });
    if (request != _request) return;
    state = result;
  }

  Future<void> loadMore() async {
    final current = state.value;
    final cursor = current?.nextCursor;
    if (current == null || cursor == null || current.loadingMore) return;
    final request = _request;
    state = AsyncData(
      SearchState(
        query: current.query,
        filter: current.filter,
        items: current.items,
        total: current.total,
        nextCursor: cursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await _repository.search(
        query: current.query,
        filter: current.filter,
        cursor: cursor,
      );
      if (request != _request) return;
      state = AsyncData(
        SearchState(
          query: current.query,
          filter: current.filter,
          items: [...current.items, ...page.items],
          total: page.total,
          nextCursor: page.nextCursor,
        ),
      );
    } on Object {
      if (request == _request) state = AsyncData(current);
      rethrow;
    }
  }

  void clear() {
    _request++;
    state = const AsyncData(SearchState());
  }
}

/// Categorias de la hoja `Busqueda-filtros` (fila 72).
final FutureProvider<List<CatalogCategory>> searchCategoriesProvider =
    FutureProvider.autoDispose<List<CatalogCategory>>(
      (ref) => ref.watch(catalogRepositoryProvider).categories(),
      retry: (_, _) => null,
    );

typedef SearchPreview = ({String query, CatalogFilter filter});

/// Cuantos resultados daria el borrador de la hoja ("Ver 12 resultados").
final FutureProviderFamily<int, SearchPreview> searchFilterPreviewProvider =
    FutureProvider.autoDispose.family<int, SearchPreview>(
      (ref, criteria) async =>
          (await ref
                  .watch(catalogRepositoryProvider)
                  .search(query: criteria.query, filter: criteria.filter))
              .total,
      retry: (_, _) => null,
    );
