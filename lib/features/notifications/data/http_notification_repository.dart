import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/domain/notification_repository.dart';

/// [NotificationRepository] sobre las filas "M-09" de
/// `musubi-api/docs/endpoints.md` (spec `musubi-api:HU-31`). Siempre con
/// sesion.
class HttpNotificationRepository implements NotificationRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<NotificationPage> list(NotificationTab tab, {String? cursor}) =>
      _guard(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          ApiPaths.notifications,
          queryParameters: {'category': ?tab.category, 'cursor': ?cursor},
        );
        final body = response.data ?? const <String, dynamic>{};
        return NotificationPage(
          items: [
            for (final item
                in (body['items'] as List<dynamic>? ?? const [])
                    .cast<Map<String, dynamic>>())
              notificationFromJson(item),
          ],
          unread: body['unread'] as int? ?? 0,
          nextCursor: body['nextCursor'] as String?,
        );
      });

  @override
  Future<void> markRead(String id) =>
      _guard(() => _dio.post<void>(ApiPaths.notificationRead(id)));

  @override
  Future<void> markAllRead() =>
      _guard(() => _dio.post<void>(ApiPaths.notificationsRead));

  @override
  Future<void> registerDevice(String token) => _guard(
    () => _dio.put<void>(ApiPaths.notificationDevices, data: {'token': token}),
  );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}

/// Un `NotificationResponse` (fixture `notification-page.json`).
AppNotification notificationFromJson(Map<String, dynamic> json) {
  final target = json['target'] as Map<String, dynamic>? ?? const {};
  return AppNotification(
    id: json['id'] as String,
    type: json['type'] as String? ?? '',
    category: json['category'] as String? ?? '',
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
    target: NotificationTarget.parse(target['type'] as String?),
    targetId: target['id'] as String? ?? '',
    read: json['read'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String).toUtc(),
  );
}
