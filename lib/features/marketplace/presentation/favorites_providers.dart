import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/data/http_favorites_repository.dart';
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';
import 'package:musubi_app/features/marketplace/domain/favorites_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Favoritos del token; en pruebas se reemplaza por un fake.
final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return HttpFavoritesRepository(ref.watch(dioProvider), config.apiBaseUrl);
});

/// Pestañas de `Favoritos`: la maqueta conserva la elegida al salir.
enum FavoriteTab {
  all('Todos'),
  available('Disponibles'),
  soldOut('Agotados');

  new(this.label);

  final String label;
}

final favoriteTabProvider = NotifierProvider<FavoriteTabNotifier, FavoriteTab>(
  FavoriteTabNotifier.new,
);

class FavoriteTabNotifier extends Notifier<FavoriteTab> {
  @override
  FavoriteTab build() => FavoriteTab.all;

  // ignore: use_setters_to_change_properties, se lee como accion de la UI.
  void select(FavoriteTab tab) => state = tab;
}

/// Estado global de favoritos: se arma con `GET /favorites` al entrar con
/// sesion y alimenta el corazon de todas las pantallas.
///
/// NOTE (HU-53): la API devuelve hasta 200 sin paginar; si se supera, se
/// pagina en una HU posterior.
///
/// Sin el reintento automatico de Riverpod 3: la pantalla ofrece "Reintentar".
final favoritesProvider = AsyncNotifierProvider<FavoritesController, Favorites>(
  FavoritesController.new,
  retry: (_, _) => null,
);

class FavoritesController extends AsyncNotifier<Favorites> {
  /// Ids con una peticion en vuelo: dos toques seguidos no duplican.
  final Set<String> _busy = {};

  FavoritesRepository get _repository => ref.read(favoritesRepositoryProvider);

  String? get _sessionUserId => switch (ref.read(sessionControllerProvider)) {
    SignedIn(:final tokens) => tokens.userId,
    Visitor() => null,
  };

  @override
  Future<Favorites> build() async {
    final userId = ref.watch(
      sessionControllerProvider.select(
        (session) => switch (session) {
          SignedIn(:final tokens) => tokens.userId,
          Visitor() => null,
        },
      ),
    );
    if (userId == null) return const Favorites();
    return await ref.watch(favoritesRepositoryProvider).list();
  }

  /// Guarda o quita [product] y devuelve si quedo guardado (`true`/`false`).
  /// Devuelve `null` si aun no hay lista o si otra peticion del mismo producto
  /// esta en vuelo; la UI no muestra aviso en ese caso. El estado cambia solo
  /// cuando la API confirma; un fallo conserva el anterior y se relanza para
  /// que la UI muestre su mensaje.
  Future<bool?> toggle(ProductSummary product) async {
    final current = state.value;
    if (current == null) return null;
    final saved = current.contains(product.id);
    if (!_busy.add(product.id)) return null;
    final userId = _sessionUserId;
    try {
      if (saved) {
        await _repository.remove(product.id);
        if (_sessionUserId != userId) return null;
        _replace((favorites) => favorites.without(product.id));
        return false;
      }
      await _repository.add(product.id);
      if (_sessionUserId != userId) return null;
      _replace(
        (favorites) => favorites.withItem(
          FavoriteItem(
            productId: product.id,
            savedAt: ref.read(clockProvider)().toUtc(),
            status: product.soldOut
                ? FavoriteStatus.soldOut
                : FavoriteStatus.available,
            product: product,
          ),
        ),
      );
      return true;
    } finally {
      _busy.remove(product.id);
    }
  }

  /// Vuelve a guardar un favorito que se acaba de quitar ("Deshacer").
  Future<void> add(FavoriteItem item) async {
    if (state.value == null || !_busy.add(item.productId)) return;
    final userId = _sessionUserId;
    try {
      await _repository.add(item.productId);
      if (_sessionUserId != userId) return;
      _replace((favorites) => favorites.withItem(item));
    } finally {
      _busy.remove(item.productId);
    }
  }

  /// Quita un favorito sin pasar por [toggle] (tarjeta de `Favoritos`).
  Future<void> remove(String productId) async {
    if (state.value == null || !_busy.add(productId)) return;
    final userId = _sessionUserId;
    try {
      await _repository.remove(productId);
      if (_sessionUserId != userId) return;
      _replace((favorites) => favorites.without(productId));
    } finally {
      _busy.remove(productId);
    }
  }

  /// Aplica el cambio sobre el estado vigente, no sobre el leido antes de la
  /// peticion: otra tarjeta pudo cambiar mientras esta estaba en vuelo.
  void _replace(Favorites Function(Favorites current) change) {
    final current = state.value;
    if (current != null) state = AsyncData(change(current));
  }
}
