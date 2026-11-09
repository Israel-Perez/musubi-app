import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

/// Filtros del tablero "Se busca" (HU-15). Viven mientras la pestana existe:
/// al volver a ella se conservan, como en la maqueta (`sbState`).
final wantedBoardFilterProvider =
    NotifierProvider<WantedBoardFilterNotifier, WantedBoardFilter>(
      WantedBoardFilterNotifier.new,
    );

class WantedBoardFilterNotifier extends Notifier<WantedBoardFilter> {
  @override
  WantedBoardFilter build() {
    // Al entrar o salir de la cuenta, el tablero empieza sin filtros.
    ref.watch(sessionControllerProvider.select((s) => s is SignedIn));
    return const WantedBoardFilter();
  }

  // ignore: use_setters_to_change_properties, se lee como accion de la UI.
  void apply(WantedBoardFilter filter) => state = filter;

  void search(String query) => state = state.copyWith(query: query);

  /// "Limpiar": quita los filtros de la hoja y la busqueda.
  void clear() => state = const WantedBoardFilter();
}

/// Lo que muestra el tablero: las solicitudes cargadas y si hay mas.
@immutable
class WantedBoardState {
  const new({this.items = const [], this.nextCursor, this.loadingMore = false});

  final List<WantedRequest> items;
  final String? nextCursor;
  final bool loadingMore;

  bool get hasMore => nextCursor != null;
}

/// Tablero "Se busca" (HU-15): se vuelve a pedir al cambiar los filtros o la
/// sesion. Para reintentar: `ref.invalidate(wantedBoardProvider)`.
final wantedBoardProvider =
    AsyncNotifierProvider<WantedBoardController, WantedBoardState>(
      WantedBoardController.new,
      retry: (_, _) => null,
    );

class WantedBoardController extends AsyncNotifier<WantedBoardState> {
  /// Solicitudes por pagina (la API da 20 por defecto).
  static const pageSize = 20;

  @override
  Future<WantedBoardState> build() async {
    ref.watch(sessionControllerProvider.select((s) => s is SignedIn));
    final filter = ref.watch(wantedBoardFilterProvider);
    final page = await ref
        .watch(wantedRepositoryProvider)
        .board(filter: filter, limit: pageSize);
    return WantedBoardState(items: page.items, nextCursor: page.nextCursor);
  }

  /// La pagina siguiente al llegar al final de la lista. Si falla, la lista
  /// se queda como estaba y el siguiente desplazamiento lo vuelve a intentar.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    final filter = ref.read(wantedBoardFilterProvider);
    state = AsyncData(
      WantedBoardState(
        items: current.items,
        nextCursor: current.nextCursor,
        loadingMore: true,
      ),
    );
    try {
      final page = await ref
          .read(wantedRepositoryProvider)
          .board(filter: filter, cursor: current.nextCursor, limit: pageSize);
      // Si cambiaron los filtros mientras cargaba, esa pagina ya no sirve.
      if (ref.read(wantedBoardFilterProvider) != filter) return;
      state = AsyncData(
        WantedBoardState(
          items: [...current.items, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } on Exception {
      state = AsyncData(current);
    }
  }
}
