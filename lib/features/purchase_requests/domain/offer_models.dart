import 'package:flutter/foundation.dart';

// "Yo tengo este producto" (HU-16). Forma canonica: filas
// `.../offers/mine` de musubi-api `docs/endpoints.md`.

/// Como se responde a una solicitud.
enum OfferKind {
  /// "Vincular publicación": una publicacion propia disponible.
  listing,

  /// "Oferta directa": un producto sin publicar que solo ve quien busca.
  direct;

  static OfferKind parse(Object? value) =>
      value == 'listing' ? OfferKind.listing : OfferKind.direct;
}

/// Estado de una oferta (HU-17).
enum OfferStatus {
  /// Enviada: quien busca aun no decide.
  sent,

  /// Quien busca la acepto.
  accepted,

  /// Quien busca la rechazo.
  rejected;

  static OfferStatus parse(Object? value) => switch (value) {
    'accepted' => OfferStatus.accepted,
    'rejected' => OfferStatus.rejected,
    _ => OfferStatus.sent,
  };
}

/// Mi oferta a una solicitud.
@immutable
class WantedOffer {
  const new({
    required this.id,
    required this.requestId,
    required this.kind,
    required this.title,
    required this.priceCents,
    required this.condition,
    this.productId,
    this.photoUrl,
    this.photoKey,
    this.message,
    this.overBudget = false,
    this.status = OfferStatus.sent,
  });

  final String id;
  final String requestId;
  final OfferKind kind;

  /// HU-17: una oferta elegida o rechazada ya no se edita.
  final OfferStatus status;

  /// Publicacion vinculada, o `null` en una oferta directa.
  final String? productId;

  /// Nombre de la publicacion o descripcion de la oferta directa.
  final String title;
  final int priceCents;

  /// `new` o `used`.
  final String condition;
  final String? photoUrl;

  /// Llave de la foto (`media/products/...`): al editar una oferta directa
  /// se vuelve a mandar si no se cambia la foto.
  final String? photoKey;
  final String? message;

  /// El precio pasa el presupuesto (se permite).
  final bool overBudget;
}

/// Lo que se manda al tocar "Enviar oferta" (`OfferRequest`).
@immutable
class NewOffer {
  const new listing({required String this.productId, this.message})
    : description = null,
      priceCents = null,
      condition = null,
      photoKey = null;

  const new direct({
    required String this.description,
    required int this.priceCents,
    required String this.condition,
    this.photoKey,
    this.message,
  }) : productId = null;

  final String? productId;
  final String? description;
  final int? priceCents;
  final String? condition;

  /// Llave de `POST /products/photos`.
  final String? photoKey;
  final String? message;

  Map<String, Object?> toJson() => {
    'productId': productId,
    'description': description?.trim(),
    'priceCents': priceCents,
    'condition': condition,
    'photo': photoKey,
    'message': message == null || message!.trim().isEmpty
        ? null
        : message!.trim(),
  };
}

/// Quien ofrece, con su reputacion y su carrera visible (HU-17).
@immutable
class Offerer {
  const new({
    required this.id,
    required this.name,
    this.photoUrl,
    this.career,
    this.ratingAvg,
    this.ratingCount = 0,
  });

  final String id;

  /// Nombre completo ("Diego Hernández").
  final String name;
  final String? photoUrl;
  final String? career;

  /// Promedio de calificaciones, o `null` si aun no tiene.
  final double? ratingAvg;
  final int ratingCount;

  String get firstName => name.trim().split(' ').first;
}

/// Una oferta recibida en mi solicitud ("Compara las ofertas", HU-17).
@immutable
class ReceivedOffer {
  const new({
    required this.id,
    required this.kind,
    required this.title,
    required this.priceCents,
    required this.condition,
    required this.offerer,
    required this.createdAt,
    this.productId,
    this.conditionDetail,
    this.photoUrl,
    this.message,
    this.status = OfferStatus.sent,
  });

  final String id;
  final OfferKind kind;
  final String? productId;
  final String title;
  final int priceCents;

  /// `new` o `used`.
  final String condition;

  /// `likeNew`, `good` o `fair` (publicacion vinculada), o `null`.
  final String? conditionDetail;
  final String? photoUrl;
  final String? message;
  final OfferStatus status;
  final Offerer offerer;
  final DateTime createdAt;

  bool get accepted => status == OfferStatus.accepted;
}
