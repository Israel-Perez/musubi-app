import 'package:flutter/foundation.dart';

// Pedidos (HU-23 y HU-24). Forma canonica: filas "M-08" de musubi-api
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

/// Motivo de "Rechazar" o "Cancelar pedido" (HU-24, RN-20): una lista
/// cerrada, cada uno con quien lo puede elegir.
enum CancelReason {
  /// Solo quien compra.
  changedMind('changed_mind', 'Ya no lo necesito'),

  /// Solo quien vende.
  unavailable('unavailable', 'Ya no tengo el producto'),

  noAgreement('no_agreement', 'No nos pusimos de acuerdo'),
  schedule('schedule', 'No puedo en la fecha acordada'),
  noShow('no_show', 'La otra persona no llegó'),
  other('other', 'Otro motivo'),

  /// Lo pone la API al borrar una cuenta (HU-46); no se elige.
  accountDeleted('account_deleted', 'La cuenta se eliminó');

  new(this.code, this.label);

  /// Valor de la API.
  final String code;

  /// Texto de la lista.
  final String label;

  /// Los que ve quien compra.
  static const List<CancelReason> forBuyer = [
    changedMind,
    noAgreement,
    schedule,
    noShow,
    other,
  ];

  /// Los que ve quien vende.
  static const List<CancelReason> forSeller = [
    unavailable,
    noAgreement,
    schedule,
    noShow,
    other,
  ];

  static CancelReason parse(Object? value) =>
      values.firstWhere((r) => r.code == value, orElse: () => other);
}

/// Quien cancelo y por que (HU-24).
@immutable
class OrderCancellation {
  const new({
    required this.byBuyer,
    required this.reason,
    this.bySystem = false,
  });

  /// Lo cancelo quien compra (si no, quien vende o el sistema).
  final bool byBuyer;

  /// Una cuenta borrada (HU-46).
  final bool bySystem;
  final CancelReason reason;
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
    this.buyerConfirmed = false,
    this.sellerConfirmed = false,
    this.cancellation,
    this.updatedAt,
    this.ratedByMe = false,
    this.rateUntil,
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

  /// Quien compra ya marco "Confirmar entrega" (HU-24, RN-19).
  final bool buyerConfirmed;

  /// Quien vende ya marco "Marcar como entregado" (HU-24, RN-19).
  final bool sellerConfirmed;

  /// Quien cancelo y por que, o `null` (HU-24).
  final OrderCancellation? cancellation;

  /// Ultimo cambio (UTC): cuando se completo o se cancelo (HU-25).
  final DateTime? updatedAt;

  /// Quien mira ya califico el pedido (HU-27, HU-45).
  final bool ratedByMe;

  /// Hasta cuando se puede calificar (7 dias despues de completado), o `null`
  /// si no esta completado.
  final DateTime? rateUntil;

  /// "Calificar a Diego": completado, sin calificar y dentro del plazo.
  bool canRate(DateTime now) =>
      status == OrderStatus.completed &&
      !ratedByMe &&
      rateUntil != null &&
      now.isBefore(rateUntil!);

  /// Quien mira ya confirmo su lado de la entrega.
  bool get iConfirmed => isBuyer ? buyerConfirmed : sellerConfirmed;

  /// Nombre de la otra parte.
  String get otherName => isBuyer ? sellerName : buyerName;

  /// El mismo pedido con otro estado (lo usan los fakes de las pruebas).
  Order copyWith({
    OrderStatus? status,
    bool? isBuyer,
    bool? paysCash,
    bool? buyerConfirmed,
    bool? sellerConfirmed,
    OrderCancellation? cancellation,
    bool? ratedByMe,
    DateTime? rateUntil,
  }) => Order(
    id: id,
    number: number,
    status: status ?? this.status,
    isBuyer: isBuyer ?? this.isBuyer,
    conversationId: conversationId,
    item: item,
    buyerName: buyerName,
    sellerName: sellerName,
    pointName: pointName,
    deliveryAt: deliveryAt,
    detail: detail,
    paysCash: paysCash ?? this.paysCash,
    transferAvailable: transferAvailable,
    buyerConfirmed: buyerConfirmed ?? this.buyerConfirmed,
    sellerConfirmed: sellerConfirmed ?? this.sellerConfirmed,
    cancellation: cancellation ?? this.cancellation,
    updatedAt: updatedAt,
    ratedByMe: ratedByMe ?? this.ratedByMe,
    rateUntil: rateUntil ?? this.rateUntil,
  );
}

/// Pestanas de "Mis pedidos" (HU-25, decision de la usuaria del 12-Nov-2026).
enum MyOrdersTab {
  /// Pendientes y confirmados.
  active('active', 'Activos'),
  completed('completed', 'Completados'),
  cancelled('cancelled', 'Cancelados');

  new(this.code, this.label);

  /// Valor de la API (`?tab=`).
  final String code;

  /// Texto de la pestana.
  final String label;
}

/// Los numeros de las tres pestanas de "Mis pedidos".
@immutable
class MyOrdersCounts {
  const new({this.active = 0, this.completed = 0, this.cancelled = 0});

  final int active;
  final int completed;
  final int cancelled;

  /// El numero de una pestana.
  int of(MyOrdersTab tab) => switch (tab) {
    MyOrdersTab.active => active,
    MyOrdersTab.completed => completed,
    MyOrdersTab.cancelled => cancelled,
  };
}

/// Una pagina de "Mis pedidos" (`GET /api/v1/orders/mine`): mis compras, del
/// mas nuevo al mas viejo.
@immutable
class MyOrdersPage {
  const new({
    this.items = const [],
    this.nextCursor,
    this.total = 0,
    this.counts = const MyOrdersCounts(),
  });

  final List<Order> items;

  /// Cursor de la pagina siguiente, o `null` si no hay mas.
  final String? nextCursor;

  /// Cuantos hay en la pestana (sin pestana, todos).
  final int total;
  final MyOrdersCounts counts;
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
