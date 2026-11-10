import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Estado de una publicacion guardada (fila 79 de
/// `musubi-api/docs/endpoints.md`, HU-53).
enum FavoriteStatus {
  available,
  soldOut,
  unavailable;

  /// `status` de la API; cualquier valor desconocido se trata como
  /// `unavailable` para no mostrar un producto que ya no se puede abrir.
  static FavoriteStatus fromApi(Object? value) => switch (value) {
    'available' => available,
    'soldOut' => soldOut,
    _ => unavailable,
  };
}

/// Un favorito de la persona del token. `product` es `null` cuando la API
/// responde `unavailable` (inexistente, quitada, oculta, otro campus o
/// bloqueo).
@immutable
class FavoriteItem {
  const new({
    required this.productId,
    required this.savedAt,
    required this.status,
    this.product,
  });

  final String productId;
  final DateTime savedAt;
  final FavoriteStatus status;
  final ProductSummary? product;

  bool get isAvailable => status == FavoriteStatus.available;
}

/// Lo que muestra `Favoritos`; `ids` alimenta el corazon de Inicio, Busqueda,
/// Producto y las tarjetas, y los conteos salen de [items].
@immutable
class Favorites {
  const new({this.items = const []});

  final List<FavoriteItem> items;

  Set<String> get ids => {for (final item in items) item.productId};

  /// Productos que se pueden abrir y comprar.
  int get availableCount => items.where((item) => item.isAvailable).length;

  /// "Agotados": `soldOut` + `unavailable`, como la tercera pestana de la
  /// maqueta.
  int get soldOutCount => items.length - availableCount;

  bool contains(String productId) =>
      items.any((item) => item.productId == productId);

  /// Agrega o reemplaza el favorito al frente (la API ordena por `savedAt`).
  Favorites withItem(FavoriteItem item) => Favorites(
    items: [item, ...items.where((old) => old.productId != item.productId)],
  );

  Favorites without(String productId) => Favorites(
    items: [
      for (final item in items)
        if (item.productId != productId) item,
    ],
  );
}
