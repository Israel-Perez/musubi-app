import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_board.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_repository.dart';

/// [WantedRepository] sobre las filas "M-05" de `musubi-api/docs/endpoints.md`
/// (specs `musubi-api:HU-13` y `HU-15`). Usa el cliente con sesion: sin
/// sesion no lleva token y el tablero responde como a un visitante.
class HttpWantedRepository implements WantedRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<WantedPage> board({
    WantedBoardFilter filter = const WantedBoardFilter(),
    String? cursor,
    int? limit,
  }) => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.wanted,
      queryParameters: {
        ...filter.toQuery(),
        'cursor': ?cursor,
        'limit': ?limit,
      },
    );
    final data = response.data ?? const {};
    return WantedPage(
      items: [
        for (final item
            in (data['items'] as List<dynamic>? ?? const [])
                .cast<Map<String, dynamic>>())
          wantedFromJson(item, apiBaseUrl: _apiBaseUrl),
      ],
      nextCursor: data['nextCursor'] as String?,
    );
  });

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

/// Un `WantedResponse` de la API. [apiBaseUrl] resuelve la foto de quien
/// busca (`/media/avatars/...`, solo en el tablero con sesion).
WantedRequest wantedFromJson(Map<String, dynamic> json, {Uri? apiBaseUrl}) {
  final category = json['category'] as Map<String, dynamic>? ?? const {};
  final requester = json['requester'] as Map<String, dynamic>? ?? const {};
  final neededBy = json['neededBy'] as String?;
  final photo = requester['photo'] as String?;
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
    requesterId: requester['id'] as String?,
    requesterPhotoUrl: photo == null || apiBaseUrl == null
        ? null
        : mediaUrl(photo, apiBaseUrl),
    requesterCareer: requester['career'] as String?,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
  );
}
