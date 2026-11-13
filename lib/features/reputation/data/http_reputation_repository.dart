import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/marketplace/data/product_json.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/domain/reputation_repository.dart';

/// [ReputationRepository] sobre las filas "M-13" de
/// `musubi-api/docs/endpoints.md` (specs `musubi-api:HU-28`, `HU-57`, `HU-27`
/// y `HU-45`). Usa el cliente con sesion.
class HttpReputationRepository implements ReputationRepository {
  new(this._dio, this._apiBaseUrl);

  final Dio _dio;
  final Uri _apiBaseUrl;

  @override
  Future<void> report(
    ReportTarget target,
    ReportReason reason, {
    String? details,
  }) => _guard(() async {
    final text = details?.trim();
    await _dio.post<void>(
      ApiPaths.reports,
      data: {
        ...switch (target) {
          GeneralReport() => {'targetType': 'general'},
          UserReport(:final userId, :final conversationId) => {
            'targetType': 'user',
            'targetId': userId,
            'conversationId': ?conversationId,
          },
        },
        'reason': reason.code,
        if (text != null && text.isNotEmpty) 'details': text,
      },
    );
  });

  @override
  Future<void> block(String userId) => _guard(() async {
    await _dio.post<void>(ApiPaths.blocks, data: {'userId': userId});
  });

  @override
  Future<void> unblock(String userId) => _guard(() async {
    await _dio.delete<void>(ApiPaths.block(userId));
  });

  @override
  Future<List<BlockedUser>> blocked() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.blocks);
    final items = (response.data?['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    return [
      for (final item in items)
        BlockedUser(
          id: item['id'] as String,
          name: item['name'] as String,
          blockedAt: DateTime.parse(item['blockedAt'] as String).toUtc(),
          photoUrl: switch (item['photo']) {
            final String photo => mediaUrl(photo, _apiBaseUrl),
            _ => null,
          },
        ),
    ];
  });

  @override
  Future<void> rate(String orderId, NewRating rating) => _guard(() async {
    await _dio.post<void>(
      ApiPaths.orderRating(orderId),
      data: {
        'stars': rating.stars,
        'tags': [for (final tag in rating.tags) tag.code],
        'comment': ?rating.comment,
      },
    );
  });

  @override
  Future<OpinionPage> opinions(String userId, {String? cursor}) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiPaths.profileRatings(userId),
          queryParameters: {'cursor': ?cursor},
        );
        final body = response.data ?? const <String, dynamic>{};
        return OpinionPage(
          items: [
            for (final item
                in (body['items'] as List<dynamic>? ?? const [])
                    .cast<Map<String, dynamic>>())
              Opinion(
                id: item['id'] as String,
                stars: (item['stars'] as num).toInt(),
                raterName: item['raterName'] as String,
                createdAt: DateTime.parse(item['createdAt'] as String).toUtc(),
                comment: item['comment'] as String?,
                tags: [
                  for (final code in item['tags'] as List<dynamic>? ?? const [])
                    ?RatingTag.parse(code),
                ],
              ),
          ],
          nextCursor: body['nextCursor'] as String?,
        );
      });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
