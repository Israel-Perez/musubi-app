import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Vitrina real sobre `GET /api/v1/products` y `GET /api/v1/categories`
/// (filas "M-03" de `musubi-api/docs/endpoints.md`, HU-48 fase 2).
///
/// Va con el cliente con sesion: sin sesion no lleva token y la API no
/// devuelve al vendedor (RNF-05); con sesion, si.
///
/// NOTE (HU-49): "Populares" llega con las vistas del detalle (HU-11).
/// NOTE (HU-15): "Se busca" llega con las solicitudes.
class HttpCatalogRepository implements CatalogRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  /// Tarjetas de "Recién publicados" que se piden de una vez.
  static const pageSize = 20;

  @override
  Future<HomeFeed> homeFeed({
    required PopularPeriod period,
    CatalogFilter filter = const CatalogFilter(),
  }) async {
    try {
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>(
          ApiPaths.products,
          queryParameters: {
            'category': ?filter.category,
            if (filter.hideSoldOut) 'hideSoldOut': true,
            'limit': pageSize,
          },
        ),
        _dio.get<List<dynamic>>(ApiPaths.categories),
      ]);
      final page = responses[0].data as Map<String, dynamic>? ?? const {};
      final categories = responses[1].data as List<dynamic>? ?? const [];
      return HomeFeed(
        recent: [
          for (final item in page['items'] as List<dynamic>? ?? const [])
            productFromJson(item as Map<String, dynamic>, _apiBaseUrl),
        ],
        categories: [
          for (final item in categories.cast<Map<String, dynamic>>())
            CatalogCategory(
              slug: item['slug'] as String,
              name: item['name'] as String,
              photoUrl: categoryPhoto(item['slug'] as String),
            ),
        ],
        recentTotal: (page['total'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (error) {
      // Se traduce (no se traga): Inicio decide por el code.
      throw ApiFailure.fromDio(error);
    }
  }
}
