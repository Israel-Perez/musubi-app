import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';

/// Catalogo publico de la vitrina: se puede leer sin cuenta (HU-48).
///
/// Lanza `ApiFailure` (nunca `DioException`) si no se puede cargar.
abstract interface class CatalogRepository {
  /// Populares del periodo, recien publicados (con [filter]) y "Se busca"
  /// del campus.
  Future<HomeFeed> homeFeed({
    required PopularPeriod period,
    CatalogFilter filter = const CatalogFilter(),
  });

  /// Busca por palabra clave (HU-09). Con `q`, la API devuelve solo
  /// disponibles, de la mas nueva a la mas vieja.
  Future<ProductPage> search({required String query, String? cursor});

  /// Detalle de una publicacion (HU-11). Sin sesion, sin el vendedor.
  Future<ProductDetail> product(String id);
}
