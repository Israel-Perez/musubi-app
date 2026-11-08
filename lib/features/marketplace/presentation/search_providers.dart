import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

/// Llave de la vista previa del CTA de `Busqueda-filtros`: texto y filtro
/// borrador (HU-10).
typedef SearchPreview = ({String query, SearchFilter filter});

/// Lo que muestra la pantalla de busqueda (HU-09) y su filtro aplicado
/// (HU-10).
@immutable
class SearchState {
  const new({
    this.query = '',
    this.filter = const SearchFilter(),
    this.items = const [],
    this.total = 0,
    this.nextCursor,
    this.loadingMore = false,
  });

  /// Texto aplicado (no el que se esta escribiendo).
  final String query;
  final SearchFilter filter;
  final List<ProductSummary> items;
  final int total;
  final String? nextCursor;
  final bool loadingMore;

  bool get hasQuery => query.isNotEmpty;
  bool get empty => hasQuery && items.isEmpty;
  bool get hasMore => nextCursor != null;
}

/// Busqueda de productos: primera pagina y "Cargar mas" (HU-09), con los
/// filtros de `Busqueda-filtros` (HU-10).
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

  Future<void> search(String raw, {SearchFilter? filter}) async {
    final query = raw.trim();
    final nextFilter = filter ?? state.value?.filter ?? const SearchFilter();
    final request = ++_request;
    if (query.isEmpty) {
      state = AsyncData(SearchState(filter: nextFilter));
      return;
    }
    // Al escribir se conservan los resultados anteriores; solo la primera
    // busqueda muestra la pantalla de carga.
    if ((state.value?.query ?? '').isEmpty) {
      state = const AsyncLoading();
    }
    final result = await AsyncValue.guard(() async {
      final page = await _repository.search(query: query, filter: nextFilter);
      return SearchState(
        query: query,
        filter: nextFilter,
        items: page.items,
        total: page.total,
        nextCursor: page.nextCursor,
      );
    });
    if (request != _request) return;
    state = result;
  }

  /// Aplica los filtros y relanza la busqueda con el texto actual. Sin texto
  /// solo guarda el filtro para que el globo lo muestre.
  Future<void> applyFilter(SearchFilter filter) async {
    final query = state.value?.query ?? '';
    if (query.isEmpty) {
      state = AsyncData(SearchState(filter: filter));
      return;
    }
    await search(query, filter: filter);
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

  /// Borra el texto y conserva los filtros (el globo sigue visible).
  void clear() {
    _request++;
    state = AsyncData(
      SearchState(filter: state.value?.filter ?? const SearchFilter()),
    );
  }
}

/// Cuantos resultados daria el filtro borrador con el texto actual
/// ("Ver 12 resultados"). Sin texto no consulta.
final FutureProviderFamily<int, SearchPreview> searchPreviewProvider =
    FutureProvider.autoDispose.family<int, SearchPreview>((ref, args) async {
      if (args.query.isEmpty) return 0;
      final page = await ref
          .watch(catalogRepositoryProvider)
          .search(query: args.query, filter: args.filter);
      return page.total;
    }, retry: (_, _) => null);
