import 'package:flutter/foundation.dart';

/// Estado del acuerdo con IA (HU-34).
enum AgreementStatus {
  /// "Esperando confirmación" (`Acuerdo-esperando`): 0 o 1 de 2.
  proposed,

  /// "Acuerdo confirmado" (`Acuerdo-confirmado`): los dos (RN-41).
  confirmed;

  static AgreementStatus parse(String? value) =>
      value == 'confirmed' ? confirmed : proposed;
}

/// Los datos que tiene que tener el acuerdo para confirmarse (nombres de la
/// API: `notIdentified` y `missing`).
abstract final class AgreementField {
  static const title = 'title';
  static const price = 'priceCents';
  static const quantity = 'quantity';
  static const meetingPoint = 'meetingPoint';
  static const deliveryAt = 'deliveryAt';
}

/// Los datos del acuerdo; `null` es "No identificado" (RN-42).
@immutable
class AgreementProposal {
  const new({
    required this.title,
    this.priceCents,
    this.quantity,
    this.meetingPoint,
    this.pointName,
    this.detail,
    this.deliveryAt,
    this.conditions,
  });

  final String title;
  final int? priceCents;
  final int? quantity;

  /// Slug del punto de entrega.
  final String? meetingPoint;
  final String? pointName;
  final String? detail;
  final DateTime? deliveryAt;
  final String? conditions;
}

/// El acuerdo de una conversacion (`AgreementResponse`), visto por una de sus
/// partes.
@immutable
class Agreement {
  const new({
    required this.id,
    required this.conversationId,
    required this.revision,
    required this.status,
    required this.isBuyer,
    required this.requestedByBuyer,
    required this.buyerName,
    required this.sellerName,
    required this.proposal,
    required this.maxQuantity,
    this.notIdentified = const {},
    this.missing = const [],
    this.buyerConfirmedAt,
    this.sellerConfirmedAt,
    this.updatedAt,
  });

  final String id;
  final String conversationId;

  /// Sube con cada cambio: se confirma la version que se ve (RN-41).
  final int revision;
  final AgreementStatus status;
  final bool isBuyer;
  final bool requestedByBuyer;
  final String buyerName;
  final String sellerName;
  final AgreementProposal proposal;
  final int maxQuantity;

  /// Lo que la IA no encontro; si ya tiene valor, se marca "Agregada".
  final Set<String> notIdentified;

  /// Lo que falta para poder confirmar.
  final List<String> missing;
  final DateTime? buyerConfirmedAt;
  final DateTime? sellerConfirmedAt;

  /// El ultimo cambio (la hora de "lo confirmaron").
  final DateTime? updatedAt;

  bool get confirmed => status == AgreementStatus.confirmed;

  bool get complete => missing.isEmpty;

  /// "0 de 2", "1 de 2"…
  int get confirmations =>
      (buyerConfirmedAt == null ? 0 : 1) + (sellerConfirmedAt == null ? 0 : 1);

  bool get confirmedByMe =>
      (isBuyer ? buyerConfirmedAt : sellerConfirmedAt) != null;

  /// La otra parte.
  String get counterpartName => isBuyer ? sellerName : buyerName;

  /// Si lo agrego una persona (la IA no lo encontro).
  bool added(String field) =>
      notIdentified.contains(field) && !missing.contains(field);
}

/// Lo que corrige una persona; lo que queda en `null` no cambia. Un texto
/// vacio en el detalle o en las condiciones lo quita.
@immutable
class AgreementEdit {
  const new({
    this.title,
    this.priceCents,
    this.quantity,
    this.meetingPoint,
    this.detail,
    this.deliveryAt,
    this.conditions,
  });

  final String? title;
  final int? priceCents;
  final int? quantity;
  final String? meetingPoint;
  final String? detail;
  final DateTime? deliveryAt;
  final String? conditions;

  Map<String, Object?> toJson(int revision) => {
    'revision': revision,
    'title': ?title,
    'priceCents': ?priceCents,
    'quantity': ?quantity,
    'meetingPoint': ?meetingPoint,
    'meetingDetail': ?detail,
    'deliveryAt': ?deliveryAt?.toUtc().toIso8601String(),
    'conditions': ?conditions,
  };
}
