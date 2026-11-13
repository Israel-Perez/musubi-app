import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/domain/search_sort.dart';

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

  /// Busca por palabra clave (HU-09) con los filtros de la hoja
  /// `Busqueda-filtros` (HU-10). Con `q`, la API devuelve solo disponibles.
  Future<ProductPage> search({
    required String query,
    SearchFilter filter = const SearchFilter(),
    SearchSort sort = SearchSort.relevant,
    int page = 1,
  });

  /// Publicaciones disponibles, newest first, paginadas con cursor (HU-49).
  Future<ProductPage> recentProducts({String? cursor});

  /// Categorias del campus para los chips de `Busqueda-filtros`.
  Future<List<CatalogCategory>> categories();

  /// Detalle de una publicacion (HU-11). Sin sesion, sin el vendedor.
  Future<ProductDetail> product(String id);

  /// Publicaciones activas de una persona (`GET /products?sellerId=`, fila
  /// "M-03", spec `musubi-api:HU-05`). `total` es el contador de
  /// "Publicaciones (N)" de `Perfil-vendedor`; "Ver más" usa [cursor].
  Future<ProductPage> sellerListings(
    String sellerId, {
    int page = 1,
    String? cursor,
  });
}
