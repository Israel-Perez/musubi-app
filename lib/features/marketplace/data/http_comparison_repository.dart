import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/marketplace/domain/comparison.dart';

/// Cliente HTTP del contrato HU-51 de musubi-api. Requiere sesion.
class HttpComparisonRepository implements ComparisonRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<List<ComparisonOption>> compare(String productId) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.productCompare(productId),
    );
    return [
      for (final item
          in (response.data?['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        comparisonOptionFromJson(item, _apiBaseUrl),
    ];
  });

  @override
  Future<PriceEstimate?> estimate(String productId) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.productPriceEstimate(productId),
    );
    final body = response.data;
    final min = body?['minCents'];
    final max = body?['maxCents'];
    if (min is! num || max is! num) return null;
    return PriceEstimate(
      minCents: min.toInt(),
      maxCents: max.toInt(),
      verdict: switch (body?['verdict']) {
        'good' => PriceVerdict.good,
        'high' => PriceVerdict.high,
        _ => PriceVerdict.fair,
      },
    );
  });

  @override
  Future<bool> stockAlert(String productId) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.productStockAlert(productId),
    );
    return response.data?['active'] == true;
  });

  @override
  Future<void> watch(String productId) => _guard(
    () => _dio.put<Map<String, dynamic>>(ApiPaths.productStockAlert(productId)),
  );

  @override
  Future<void> unwatch(String productId) =>
      _guard(() => _dio.delete<void>(ApiPaths.productStockAlert(productId)));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

/// `ComparisonItemResponse` de musubi-api (fixture `product-comparison.json`).
ComparisonOption comparisonOptionFromJson(
  Map<String, dynamic> json,
  Uri apiBaseUrl,
) {
  final seller = json['seller'] as Map<String, dynamic>;
  return ComparisonOption(
    product: productFromJson(
      json['product'] as Map<String, dynamic>,
      apiBaseUrl,
    ),
    seller: ComparisonSeller(
      id: seller['id'] as String,
      name: seller['name'] as String,
      ratingAvg: (seller['ratingAvg'] as num?)?.toDouble(),
      ratingCount: (seller['ratingCount'] as num?)?.toInt() ?? 0,
      sales: (seller['sales'] as num?)?.toInt(),
    ),
    sameModel: json['sameModel'] == true,
  );
}
