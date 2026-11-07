import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

/// Lo que muestra la pantalla de busqueda (HU-09).
@immutable
class SearchState {
  const new({
    this.query = '',
    this.items = const [],
    this.total = 0,
    this.nextCursor,
    this.loadingMore = false,
  });

  /// Texto aplicado (no el que se esta escribiendo).
  final String query;
  final List<ProductSummary> items;
  final int total;
  final String? nextCursor;
  final bool loadingMore;

  bool get hasQuery => query.isNotEmpty;
  bool get empty => hasQuery && items.isEmpty;
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

  Future<void> search(String raw) async {
    final query = raw.trim();
    final request = ++_request;
    if (query.isEmpty) {
      state = const AsyncData(SearchState());
      return;
    }
    // Al escribir se conservan los resultados anteriores; solo la primera
    // busqueda muestra la pantalla de carga.
    if ((state.value?.query ?? '').isEmpty) {
      state = const AsyncLoading();
    }
    final result = await AsyncValue.guard(() async {
      final page = await _repository.search(query: query);
      return SearchState(
        query: query,
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
        items: current.items,
        total: current.total,
        nextCursor: cursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await _repository.search(
        query: current.query,
        cursor: cursor,
      );
      if (request != _request) return;
      state = AsyncData(
        SearchState(
          query: current.query,
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
