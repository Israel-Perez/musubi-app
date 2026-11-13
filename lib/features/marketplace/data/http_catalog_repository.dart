import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';
import 'package:musubi_app/features/marketplace/domain/search_sort.dart';

/// Vitrina real sobre `GET /api/v1/products` y `GET /api/v1/categories`
/// (fila 73 de `musubi-api/docs/endpoints.md`, HU-48 fase 2 y HU-09).
///
/// Va con el cliente con sesion: sin sesion no lleva token y la API no
/// devuelve al vendedor (RNF-05); con sesion, si.
///
/// "Se busca" sale del tablero (`GET /api/v1/wanted`, HU-15).
///
class HttpCatalogRepository implements CatalogRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  /// Tarjetas de "Recién publicados" que se piden de una vez.
  static const pageSize = 20;

  /// Boletos de "Se busca" en Inicio (la fila se desliza de lado).
  static const wantedCount = 6;

  @override
  Future<HomeFeed> homeFeed({
    required PopularPeriod period,
    CatalogFilter filter = const CatalogFilter(),
  }) async {
    try {
      // "Se busca" nunca falla (ver _wanted); productos y categorias si.
      final wantedFuture = _wanted();
      final responses = await Future.wait([
        _dio.get<Map<String, dynamic>>(
          ApiPaths.popularProducts,
          queryParameters: {'period': period.name, 'limit': 6},
        ),
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
      final wanted = await wantedFuture;
      final popularBody =
          responses[0].data as Map<String, dynamic>? ?? const {};
      final page = responses[1].data as Map<String, dynamic>? ?? const {};
      final categories = responses[2].data as List<dynamic>? ?? const [];
      return HomeFeed(
        popular: [
          for (final item
              in (popularBody['items'] as List<dynamic>? ?? const [])
                  .cast<Map<String, dynamic>>())
            productFromJson(
              item['product'] as Map<String, dynamic>,
              _apiBaseUrl,
              views: (item['views'] as num).toInt(),
            ),
        ],
        recent: [
          for (final item in page['items'] as List<dynamic>? ?? const [])
            productFromJson(item as Map<String, dynamic>, _apiBaseUrl),
        ],
        wanted: wanted,
        categories: _categoriesFrom(categories),
        recentTotal: (page['total'] as num?)?.toInt() ?? 0,
      );
    } on DioException catch (error) {
      // Se traduce (no se traga): Inicio decide por el code.
      throw ApiFailure.fromDio(error);
    }
  }

  /// "Se busca" de Inicio. Es una seccion secundaria: si el tablero no
  /// responde, Inicio se muestra sin ella ("Nadie ha pedido nada todavía")
  /// en lugar de caer entero.
  Future<List<WantedSummary>> _wanted() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.wanted,
        queryParameters: {'limit': wantedCount},
      );
      return [
        for (final item
            in (response.data?['items'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          _wantedSummary(item),
      ];
    } on DioException {
      return const [];
    }
  }

  static WantedSummary _wantedSummary(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>? ?? const {};
    final neededBy = json['neededBy'] as String?;
    return WantedSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      budgetCents: (json['budgetCents'] as num).toInt(),
      // "2026-11-13": un dia del campus, sin zona.
      neededBy: neededBy == null ? null : DateTime.parse(neededBy),
      category: category['slug'] as String?,
      categoryName: category['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
    );
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
    SearchSort sort = SearchSort.relevant,
    int page = 1,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.products,
        queryParameters: {
          'q': query.trim(),
          if (filter.categories.isNotEmpty) 'category': filter.categories,
          'minPriceCents': ?filter.minCents,
          'maxPriceCents': ?filter.maxCents,
          'condition': ?filter.condition.apiValue,
          // HU-10: la busqueda oculta los agotados salvo que se pidan.
          'hideSoldOut': filter.hideSoldOut,
          'sort': sort.apiValue,
          'limit': searchPageSize,
          'page': page,
        },
      );
      return _page(response.data);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  /// Publicaciones activas de una persona (`GET /products?sellerId=`, fila
  /// "M-03", spec `musubi-api:HU-05`). Misma pagina de 20 que la vitrina;
  /// `total` es el numero de "Publicaciones (N)".
  @override
  Future<ProductPage> sellerListings(
    String sellerId, {
    int page = 1,
    String? cursor,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.products,
        queryParameters: {
          'sellerId': sellerId,
          'hideSoldOut': true,
          'limit': pageSize,
          'cursor': ?cursor,
          if (cursor == null) 'page': page,
        },
      );
      return _page(response.data);
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }

  /// `ProductPage` de la vitrina (`items[]`, `total` y `nextCursor`).
  ProductPage _page(Map<String, dynamic>? body) {
    try {
      return ProductPage(
        items: [
          for (final item in body?['items'] as List<dynamic>? ?? const [])
            productFromJson(item as Map<String, dynamic>, _apiBaseUrl),
        ],
        total: (body?['total'] as num?)?.toInt() ?? 0,
        nextCursor: body?['nextCursor'] as String?,
      );
    } on Object {
      // Forma inesperada: estado de error, nunca un crash.
      throw const ApiFailure(
        code: ApiFailure.serverError,
        message: 'El servidor respondió algo inesperado.',
      );
    }
  }

  @override
  Future<ProductPage> recentProducts({String? cursor}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        ApiPaths.products,
        queryParameters: {
          'sort': 'newest',
          'hideSoldOut': true,
          'limit': recentProductsPageSize,
          'cursor': ?cursor,
        },
      );
      final body = response.data ?? const <String, dynamic>{};
      return ProductPage(
        items: [
          for (final item in body['items'] as List<dynamic>? ?? const [])
            productFromJson(item as Map<String, dynamic>, _apiBaseUrl),
        ],
        total: (body['total'] as num?)?.toInt() ?? 0,
        nextCursor: body['nextCursor'] as String?,
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
