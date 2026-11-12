import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Publicar productos (HU-06). Lanza `ApiFailure` (nunca `DioException`).
abstract interface class ListingsRepository {
  /// Categorias del campus del usuario (maqueta `Vender-3`).
  Future<List<CatalogCategory>> categories();

  /// Sube una foto ya reducida en el telefono; la API la deja en WebP sin
  /// metadatos.
  Future<UploadedPhoto> uploadPhoto(String filePath);

  /// Publica y devuelve la tarjeta tal como se vera en la vitrina.
  Future<ProductSummary> publish(NewListing listing);

  /// Las publicaciones del usuario ("Ver mis productos"), todas menos las
  /// quitadas.
  Future<List<OwnListing>> mine();

  /// Una pestana de `Mis-productos` con los conteos de las tres (HU-08).
  Future<MyListingsPage> minePage(MyProductsTab tab, {String? cursor});

  /// "Marcar como vendido" (HU-08): sale de la vitrina y pasa a "Vendidos".
  Future<OwnListing> markSold(String id);

  /// "Cambiar piezas" y "Reponer" (HU-50): fija las piezas disponibles (0 a
  /// 10). Con 0 queda agotada.
  Future<OwnListing> setStock(String id, int stock);

  /// Rango de precios de la categoria, o `null` si aun no hay suficientes
  /// publicaciones para que sea honesto.
  Future<PriceRange?> priceRange(String category);

  /// "Editar publicacion" (HU-07): manda todos los campos editables.
  Future<OwnListing> update(String id, ListingUpdate update);

  /// "Pausar publicacion" (HU-07): sale de la vitrina; idempotente.
  Future<OwnListing> pause(String id);

  /// "Reactivar" (HU-07): vuelve a la vitrina (sin piezas, agotada).
  Future<OwnListing> resume(String id);

  /// "Eliminar" (HU-07): borrado real. Con pedidos abiertos la API responde
  /// `409 listings.product_has_orders` (RN-07).
  Future<void> delete(String id);
}
