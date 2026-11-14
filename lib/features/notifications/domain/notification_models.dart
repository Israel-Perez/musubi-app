import 'package:flutter/foundation.dart';

/// Pestanas de `Notificaciones` (la API filtra por `category`).
enum NotificationTab {
  all('Todas', null),
  matches('Coincidencias', 'matches'),
  orders('Pedidos', 'orders'),
  requests('Solicitudes', 'requests');

  new(this.label, this.category);

  final String label;

  /// `null` es "Todas".
  final String? category;
}

/// Lo que abre un aviso.
enum NotificationTarget {
  conversation,
  order,

  /// Mi solicitud, con sus ofertas (HU-30).
  wanted,

  /// Una solicitud del tablero, para responder "Yo tengo este producto"
  /// (HU-19).
  wantedBoard,

  /// Nada que abrir (`none`) o un destino que esta version no conoce.
  unknown;

  static NotificationTarget parse(String? value) => switch (value) {
    'conversation' => conversation,
    'order' => order,
    'wanted' => wanted,
    'wanted_board' => wantedBoard,
    _ => unknown,
  };
}

/// Un aviso del centro de notificaciones (`NotificationResponse`).
@immutable
class AppNotification {
  const new({
    required this.id,
    required this.type,
    required this.category,
    required this.title,
    required this.body,
    required this.target,
    required this.targetId,
    required this.read,
    required this.createdAt,
  });

  final String id;

  /// `order_created`, `offer_received`, `request_expiring`…
  final String type;
  final String category;
  final String title;
  final String body;
  final NotificationTarget target;
  final String targetId;
  final bool read;
  final DateTime createdAt;

  AppNotification markedRead() => AppNotification(
    id: id,
    type: type,
    category: category,
    title: title,
    body: body,
    target: target,
    targetId: targetId,
    read: true,
    createdAt: createdAt,
  );
}

/// Una pagina de avisos y cuantos no se han leido en total.
@immutable
class NotificationPage {
  const new({required this.items, required this.unread, this.nextCursor});

  final List<AppNotification> items;
  final int unread;
  final String? nextCursor;
}

/// Lo que trae un push al tocarlo o al llegar con la app abierta.
@immutable
class PushOpen {
  const new({
    required this.type,
    required this.target,
    required this.targetId,
    this.title,
    this.body,
    this.notificationId,
  });

  /// Lee los `data` del push (`type`, `targetType`, `targetId`).
  factory fromData(Map<String, dynamic> data, {String? title, String? body}) =>
      PushOpen(
        type: data['type'] as String? ?? '',
        target: NotificationTarget.parse(data['targetType'] as String?),
        targetId: data['targetId'] as String? ?? '',
        notificationId: data['notificationId'] as String?,
        title: title,
        body: body,
      );

  final String type;
  final NotificationTarget target;
  final String targetId;
  final String? title;
  final String? body;
  final String? notificationId;
}
