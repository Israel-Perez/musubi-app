import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/domain/status_repository.dart';

/// Catalogo mientras no existen los endpoints publicos de productos.
/// NOTE (HU-06): reemplazar por `HttpCatalogRepository` sobre
/// `GET /api/v1/products` (populares de HU-49, filtro de HU-10 y "Se busca"
/// de HU-15).
///
/// Ya distingue los estados reales de Inicio: si la API no responde el ping,
/// lanza un error de red (maqueta `Inicio-error`); si responde, la vitrina
/// esta vacia porque todavia nadie publica.
class PendingCatalogRepository implements CatalogRepository {
  new(this._status);

  final StatusRepository _status;

  @override
  Future<HomeFeed> homeFeed({
    required PopularPeriod period,
    CatalogFilter filter = const CatalogFilter(),
  }) async {
    final status = await _status.check();
    return switch (status) {
      ApiOnline() => const HomeFeed(),
      ApiOffline(:final message) => throw ApiFailure(
        code: ApiFailure.networkOffline,
        message: message,
      ),
    };
  }
}
