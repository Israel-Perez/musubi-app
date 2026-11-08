import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/domain/search_sort.dart';
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
    this.sort = SearchSort.relevant,
    this.items = const [],
    this.total = 0,
    this.page = 1,
  });

  /// Texto aplicado (no el que se esta escribiendo).
  final String query;
  final SearchFilter filter;
  final SearchSort sort;
  final List<ProductSummary> items;
  final int total;

  /// Pagina visible (base 1).
  final int page;

  bool get empty => items.isEmpty;

  /// Paginas que caben en el total ("12 resultados" / 20 por pagina).
  int get pageCount => total <= searchPageSize
      ? 1
      : (total + searchPageSize - 1) ~/ searchPageSize;
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

  /// Busca con texto, filtros y orden; sin texto lista todo el catalogo.
  Future<void> search(
    String raw, {
    SearchFilter? filter,
    SearchSort? sort,
    int page = 1,
  }) async {
    final query = raw.trim();
    final nextFilter = filter ?? state.value?.filter ?? const SearchFilter();
    final nextSort = sort ?? state.value?.sort ?? SearchSort.relevant;
    final request = ++_request;
    // Al escribir (o cambiar de pagina) se conservan los resultados viejos
    // solo si ya hay algo que mostrar.
    if ((state.value?.items.isEmpty ?? true) || state.value?.page != page) {
      state = const AsyncLoading();
    }
    final result = await AsyncValue.guard(() async {
      final result = await _repository.search(
        query: query,
        filter: nextFilter,
        sort: nextSort,
        page: page,
      );
      return SearchState(
        query: query,
        filter: nextFilter,
        sort: nextSort,
        items: result.items,
        total: result.total,
        page: page,
      );
    });
    if (request != _request) return;
    state = result;
    if (query.isNotEmpty) {
      ref.read(searchHistoryProvider.notifier).add(query);
    }
  }

  /// Aplica los filtros y relanza la busqueda con el texto actual. Sin texto,
  /// explora el catalogo con esos filtros.
  Future<void> applyFilter(SearchFilter filter) async {
    await search(state.value?.query ?? '', filter: filter);
  }

  /// Cambia el orden y relanza la busqueda con el texto y los filtros actuales.
  Future<void> setSort(SearchSort sort) async {
    final current = state.value;
    if (current?.sort == sort) return;
    await search(current?.query ?? '', filter: current?.filter, sort: sort);
  }

  /// Salta a otra pagina de resultados (la 1 si no hay nada).
  Future<void> goToPage(int page) async {
    final current = state.value;
    if (current == null || page < 1 || page > current.pageCount) return;
    if (page == current.page) return;
    await search(
      current.query,
      filter: current.filter,
      sort: current.sort,
      page: page,
    );
  }

  /// Borra el texto y conserva los filtros y el orden; lista el catalogo.
  Future<void> clear() => search('', filter: state.value?.filter);
}

/// Busquedas de esta sesion, la mas reciente primero (maximo 5). No se
/// persiste: RNF-07 prohibe guardar el texto de busqueda.
final NotifierProvider<SearchHistory, List<String>> searchHistoryProvider =
    NotifierProvider<SearchHistory, List<String>>(SearchHistory.new);

class SearchHistory extends Notifier<List<String>> {
  static const max = 5;

  @override
  List<String> build() => const [];

  void add(String query) {
    final text = query.trim();
    if (text.isEmpty) return;
    state = [text, ...state.where((item) => item != text)].take(max).toList();
  }

  void clear() => state = const [];
}

/// Cuantos resultados darian el texto y el filtro borrador
/// ("Ver 12 resultados"). Sin texto ni filtros no consulta.
final FutureProviderFamily<int, SearchPreview> searchPreviewProvider =
    FutureProvider.autoDispose.family<int, SearchPreview>((ref, args) async {
      if (args.query.isEmpty && args.filter.isEmpty) return 0;
      final page = await ref
          .watch(catalogRepositoryProvider)
          .search(query: args.query, filter: args.filter);
      return page.total;
    }, retry: (_, _) => null);
