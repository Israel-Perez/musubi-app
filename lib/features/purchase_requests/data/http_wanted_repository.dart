import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_repository.dart';

/// [WantedRepository] sobre las filas "M-05" de `musubi-api/docs/endpoints.md`
/// (spec `musubi-api:HU-13`). Usa el cliente con sesion.
class HttpWantedRepository implements WantedRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<WantedRequest> publish(NewWanted request) => _guard(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiPaths.wanted,
      data: request.toJson(),
    );
    return wantedFromJson(response.data ?? const {});
  });

  @override
  Future<List<WantedRequest>> mine() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myWanted);
    return [
      for (final item
          in (response.data?['items'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>())
        wantedFromJson(item),
    ];
  });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

/// Un `WantedResponse` de la API.
WantedRequest wantedFromJson(Map<String, dynamic> json) {
  final category = json['category'] as Map<String, dynamic>? ?? const {};
  final requester = json['requester'] as Map<String, dynamic>? ?? const {};
  final neededBy = json['neededBy'] as String?;
  return WantedRequest(
    id: json['id'] as String,
    title: json['title'] as String,
    categorySlug: category['slug'] as String? ?? 'otro',
    categoryName: category['name'] as String? ?? 'Otro',
    description: json['description'] as String?,
    features: [
      for (final f in json['features'] as List<dynamic>? ?? const [])
        f as String,
    ],
    budgetCents: (json['budgetCents'] as num).toInt(),
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    // "2026-11-13": un dia del campus, sin zona.
    neededBy: neededBy == null ? null : DateTime.parse(neededBy),
    status: WantedStatus.parse(json['status']),
    offersCount: (json['offersCount'] as num?)?.toInt() ?? 0,
    requesterName: requester['name'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
  );
}
