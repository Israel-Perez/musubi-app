import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';

/// Vitrina real sobre `GET /api/v1/products` y `GET /api/v1/categories`
/// (fila 73 de `musubi-api/docs/endpoints.md`, HU-48 fase 2 y HU-09).
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

  /// Tarjetas de una pagina de busqueda (HU-09).
  static const searchPageSize = 20;

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
        categories: _categoriesFrom(categories),
        recentTotal: (page['total'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (error) {
      // Se traduce (no se traga): Inicio decide por el code.
      throw ApiFailure.fromDio(error);
    }
  }

  @override
  Future<List<CatalogCategory>> categories() async {
    try {
      final response = await _dio.get<List<dynamic>>(ApiPaths.categories);
      return _categoriesFrom(response.data ?? const []);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  static List<CatalogCategory> _categoriesFrom(List<dynamic> data) => [
    for (final item in data.cast<Map<String, dynamic>>())
      CatalogCategory(
        slug: item['slug'] as String,
        name: item['name'] as String,
        photoUrl: categoryPhoto(item['slug'] as String),
      ),
  ];

  @override
  Future<ProductPage> search({
    required String query,
    SearchFilter filter = const SearchFilter(),
    String? cursor,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.products,
        queryParameters: {
          'q': query.trim(),
          'category': ?filter.category,
          'minPriceCents': ?filter.minCents,
          'maxPriceCents': ?filter.maxCents,
          'condition': ?filter.condition.apiValue,
          // HU-10: la busqueda oculta los agotados salvo que se pidan.
          'hideSoldOut': filter.hideSoldOut,
          'limit': searchPageSize,
          'cursor': ?cursor,
        },
      );
      final page = response.data ?? const <String, dynamic>{};
      return ProductPage(
        items: [
          for (final item in page['items'] as List<dynamic>? ?? const [])
            productFromJson(item as Map<String, dynamic>, _apiBaseUrl),
        ],
        total: (page['total'] as num?)?.toInt() ?? 0,
        nextCursor: page['nextCursor'] as String?,
      );
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  @override
  Future<ProductDetail> product(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.product(id),
      );
      final json = response.data ?? const <String, dynamic>{};
      final category = json['category'] as Map<String, dynamic>;
      final seller = json['seller'] as Map<String, dynamic>?;
      return ProductDetail(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        categoryName: category['name'] as String,
        priceCents: (json['priceCents'] as num).toInt(),
        condition: json['condition'] as String,
        conditionDetail: json['conditionDetail'] as String?,
        stock: (json['stock'] as num).toInt(),
        status: json['status'] as String,
        photoUrls: [
          for (final path in (json['photos'] as List<dynamic>).cast<String>())
            mediaUrl(path, _apiBaseUrl),
        ],
        publishedAt: DateTime.parse(json['publishedAt'] as String).toUtc(),
        sellerId: seller?['id'] as String?,
        sellerName: seller?['name'] as String?,
      );
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
