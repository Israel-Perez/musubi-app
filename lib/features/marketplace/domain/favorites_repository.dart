import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';

/// Favoritos de la persona del token (filas 79–81 de
/// `musubi-api/docs/endpoints.md`, HU-53). Las rutas no llevan el id del
/// usuario: la API decide por la sesion.
abstract interface class FavoritesRepository {
  /// `GET /api/v1/favorites`: del mas reciente al mas viejo, maximo 200.
  Future<Favorites> list();

  /// `PUT /api/v1/favorites/{productId}`: idempotente.
  Future<void> add(String productId);

  /// `DELETE /api/v1/favorites/{productId}`: idempotente.
  Future<void> remove(String productId);
}
