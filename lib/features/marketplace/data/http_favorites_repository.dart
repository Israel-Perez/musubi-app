import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';
import 'package:musubi_app/features/marketplace/domain/favorites_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Favoritos reales sobre `GET`, `PUT` y `DELETE /api/v1/favorites` (filas
/// 79–81 de `musubi-api/docs/endpoints.md`, HU-53).
class HttpFavoritesRepository implements FavoritesRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  /// La API no manda conteos: se derivan de `items` en [Favorites].
  @override
  Future<Favorites> list() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiPaths.favorites);
      final rawItems = response.data?['items'];
      if (rawItems is! List) return const Favorites();
      return Favorites(items: [for (final raw in rawItems) ?_item(raw)]);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  /// Un elemento incompleto se descarta; uno con estado desconocido o sin
  /// producto se muestra como `unavailable`, sin exponer datos.
  FavoriteItem? _item(Object? raw) {
    if (raw is! Map<String, dynamic>) return null;
    final productId = raw['productId'];
    final savedAt = raw['savedAt'];
    if (productId is! String || productId.isEmpty || savedAt is! String) {
      return null;
    }
    final saved = DateTime.tryParse(savedAt);
    if (saved == null) return null;

    final rawStatus = raw['status'];
    var status = FavoriteStatus.fromApi(rawStatus);
    ProductSummary? product;
    if (status != FavoriteStatus.unavailable &&
        raw['product'] is Map<String, dynamic>) {
      try {
        product = productFromJson(
          raw['product'] as Map<String, dynamic>,
          _apiBaseUrl,
        );
      } on Object {
        // Falla cerrado: un producto ilegible no se muestra ni se expone.
        product = null;
      }
    }
    if (status != FavoriteStatus.unavailable && product == null) {
      status = FavoriteStatus.unavailable;
    }
    return FavoriteItem(
      productId: productId,
      savedAt: saved.toUtc(),
      status: status,
      product: status == FavoriteStatus.unavailable ? null : product,
    );
  }

  @override
  Future<void> add(String productId) async {
    try {
      await _dio.put<void>(ApiPaths.favorite(productId));
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  @override
  Future<void> remove(String productId) async {
    try {
      await _dio.delete<void>(ApiPaths.favorite(productId));
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
