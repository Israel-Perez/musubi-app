import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/recommendations/domain/recommendation_models.dart';
import 'package:musubi_app/features/recommendations/domain/recommendation_repository.dart';

/// Recomendaciones por HTTP (filas "M-11" de `musubi-api/docs/endpoints.md`).
class HttpRecommendationRepository implements RecommendationRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<RecommendationPage> forYou({int? limit}) =>
      _page(ApiPaths.recommendations, limit);

  @override
  Future<RecommendationPage> similar(String productId, {int? limit}) =>
      _page(ApiPaths.productSimilar(productId), limit);

  Future<RecommendationPage> _page(String path, int? limit) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: {'limit': ?limit},
      );
      final body = response.data ?? const <String, dynamic>{};
      return RecommendationPage(
        items: [
          for (final item in body['items'] as List<dynamic>? ?? const [])
            productFromJson(item as Map<String, dynamic>, _apiBaseUrl),
        ],
        basis: RecommendationBasis.parse(body['basis'] as String?),
      );
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
