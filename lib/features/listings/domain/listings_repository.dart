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

  /// Las publicaciones del usuario ("Ver mis productos").
  Future<List<OwnListing>> mine();

  /// Rango de precios de la categoria, o `null` si aun no hay suficientes
  /// publicaciones para que sea honesto.
  Future<PriceRange?> priceRange(String category);
}
