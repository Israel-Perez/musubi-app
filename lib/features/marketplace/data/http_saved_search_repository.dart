import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/domain/saved_search.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';

/// Cliente HTTP del contrato HU-12 de musubi-api. Requiere sesión.
class HttpSavedSearchRepository implements SavedSearchRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<({SavedSearch search, bool created})> save({
    required String query,
    SearchFilter filter = const SearchFilter(),
  }) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.savedSearches,
      data: {
        'q': query.trim(),
        if (filter.categories.isNotEmpty) 'category': filter.categories,
        'minPriceCents': ?filter.minCents,
        'maxPriceCents': ?filter.maxCents,
        'condition': ?filter.condition.apiValue,
      },
    );
    return (
      search: savedSearchFromJson(response.data ?? const {}),
      created: response.statusCode == 201,
    );
  });

  @override
  Future<List<SavedSearch>> mine() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.savedSearches,
    );
    return [
      for (final item
          in (response.data?['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        savedSearchFromJson(item),
    ];
  });

  @override
  Future<void> remove(String id) =>
      _guard(() => _dio.delete<void>(ApiPaths.savedSearch(id)));

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

/// `SavedSearchResponse` de musubi-api.
SavedSearch savedSearchFromJson(Map<String, dynamic> json) => SavedSearch(
  id: json['id'] as String,
  query: json['query'] as String,
  categories: [
    for (final slug in json['categories'] as List<dynamic>? ?? const [])
      slug as String,
  ],
  minCents: (json['minPriceCents'] as num?)?.toInt(),
  maxCents: (json['maxPriceCents'] as num?)?.toInt(),
  condition: json['condition'] as String?,
  expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
);
