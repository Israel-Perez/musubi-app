import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

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
}
