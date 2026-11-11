import 'package:musubi_app/features/notifications/domain/notification_models.dart';

/// El centro de notificaciones y el registro del dispositivo (HU-31).
abstract interface class NotificationRepository {
  /// Mis avisos de una pestana, del mas nuevo al mas viejo.
  Future<NotificationPage> list(NotificationTab tab, {String? cursor});

  /// Marca uno como leido.
  Future<void> markRead(String id);

  /// "Marcar leidas".
  Future<void> markAllRead();

  /// Registra el token de FCM de este telefono para la sesion actual.
  Future<void> registerDevice(String token);
}
