import 'package:flutter/foundation.dart';

// Pedidos (HU-23). Forma canonica: filas "M-08" de musubi-api
// `docs/endpoints.md`; aqui solo lo que muestra la app.

/// Estado del pedido (RF-31): los cuatro pasos de `Pedido-pago`.
enum OrderStatus {
  /// Recien creado: quien vende lo acepta (RN-16, HU-24).
  pending,

  /// Quien vende lo acepto (HU-24).
  confirmed,

  /// Entregado (HU-24).
  completed,

  /// Cancelado (RN-20).
  cancelled;

  /// Valor de la API.
  static OrderStatus parse(Object? value) => switch (value) {
    'confirmed' => confirmed,
    'completed' => completed,
    'cancelled' => cancelled,
    _ => pending,
  };

  /// Etiqueta de la maqueta ("Pendiente").
  String get label => switch (this) {
    pending => 'Pendiente',
    confirmed => 'Confirmado',
    completed => 'Completado',
    cancelled => 'Cancelado',
  };

  /// Sigue abierto (pendiente o confirmado).
  bool get open => this == pending || this == confirmed;
}

/// Un punto de entrega del campus (`GET /orders/meeting-points`).
@immutable
class MeetingPoint {
  const new({required this.slug, required this.name, this.suggested = false});

  final String slug;
  final String name;

  /// Es el edificio de la carrera de quien compra.
  final bool suggested;

  @override
  bool operator ==(Object other) => other is MeetingPoint && other.slug == slug;

  @override
  int get hashCode => slug.hashCode;
}

/// Lo que se compra (copia del momento del pedido).
@immutable
class OrderItem {
  const new({
    required this.title,
    required this.priceCents,
    required this.quantity,
    required this.totalCents,
    this.photoUrl,
    this.productId,
  });

  final String title;
  final int priceCents;
  final int quantity;
  final int totalCents;

  /// URL completa de la foto, o `null`.
  final String? photoUrl;

  /// La publicacion, o `null` en una oferta directa.
  final String? productId;
}

/// Un pedido, visto por una de sus partes.
@immutable
class Order {
  const new({
    required this.id,
    required this.number,
    required this.status,
    required this.isBuyer,
    required this.conversationId,
    required this.item,
    required this.buyerName,
    required this.sellerName,
    required this.pointName,
    required this.deliveryAt,
    this.detail,
    this.paysCash = false,
    this.transferAvailable = false,
  });

  final String id;

  /// "MS-1001".
  final String number;
  final OrderStatus status;

  /// Quien mira es quien compra.
  final bool isBuyer;
  final String conversationId;
  final OrderItem item;
  final String buyerName;
  final String sellerName;

  /// "Biblioteca".
  final String pointName;

  /// Precision del lugar ("Planta baja, junto a la entrada"), o `null`.
  final String? detail;

  /// Fecha y hora de la entrega (UTC).
  final DateTime deliveryAt;

  /// Ya eligio "Efectivo al entregar" (RN-18).
  final bool paysCash;

  /// Quien vende registro su cuenta (HU-55; hoy siempre `false`).
  final bool transferAvailable;
}

/// "Crear pedido" desde el resumen del chat.
@immutable
class NewOrder {
  const new({
    required this.conversationId,
    required this.quantity,
    required this.meetingPoint,
    required this.deliveryAt,
    this.detail,
  });

  final String conversationId;
  final int quantity;

  /// Slug del punto.
  final String meetingPoint;
  final String? detail;

  /// Fecha y hora (se manda en UTC).
  final DateTime deliveryAt;

  Map<String, Object?> toJson() => {
    'conversationId': conversationId,
    'quantity': quantity,
    'meetingPoint': meetingPoint,
    'meetingDetail': ?detail,
    'deliveryAt': deliveryAt.toUtc().toIso8601String(),
  };
}
