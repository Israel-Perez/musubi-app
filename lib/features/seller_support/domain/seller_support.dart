import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';

/// Una idea para vender (HU-37, RN-38: solo orienta; nunca cambia nada).
enum SalesTipKind {
  price,
  description,
  photos;

  static SalesTipKind parse(String? value) => switch (value) {
    'description' => description,
    'photos' => photos,
    _ => price,
  };
}

/// "Revisa el precio", "Mejora la descripción" o "Actualiza las fotos".
@immutable
class SalesTip {
  const new({
    required this.kind,
    required this.title,
    required this.body,
    this.applies = false,
  });

  final SalesTipKind kind;
  final String title;
  final String body;

  /// Si los datos de la publicacion la piden (precio arriba, descripcion
  /// corta o pocas fotos).
  final bool applies;
}

/// Una publicacion que lleva mas de 3 semanas sin venderse (HU-36,
/// `Mis-productos` → "Llevan tiempo sin venderse").
@immutable
class SlowListing {
  const new({
    required this.listing,
    required this.daysListed,
    this.views = 0,
    this.messages = 0,
    this.people = 0,
    this.requests = 0,
    this.tips = const [],
  });

  final OwnListing listing;

  /// "Publicada hace 34 días".
  final int daysListed;

  /// Vistas de otras personas en los ultimos 30 dias ("96 vistas").
  final int views;

  /// Conversaciones que se abrieron desde ella ("0 mensajes").
  final int messages;

  /// Personas que la buscan ("3 estudiantes la buscan", HU-38).
  final int people;

  /// De esas, cuantas tienen una solicitud "Se busca".
  final int requests;

  final List<SalesTip> tips;
}

/// "Llevan tiempo sin venderse" y a partir de cuantos dias.
@immutable
class SlowListings {
  const new({this.items = const [], this.thresholdDays = 21});

  final List<SlowListing> items;
  final int thresholdDays;
}

/// Una solicitud "Se busca" que coincide con mi publicacion (HU-38).
@immutable
class DemandRequest {
  const new({
    required this.id,
    required this.title,
    required this.budgetCents,
    required this.requesterName,
    required this.expiresAt,
  });

  final String id;
  final String title;
  final int budgetCents;
  final String requesterName;
  final DateTime expiresAt;
}

/// "Quienes la buscan": las solicitudes publicas y cuantas personas mas la
/// esperan con una alerta (RN-37: nunca se dice quienes).
@immutable
class ProductDemand {
  const new({this.people = 0, this.alerts = 0, this.requests = const []});

  final int people;
  final int alerts;
  final List<DemandRequest> requests;
}

/// Contrato de M-12 (filas "M-12" de `musubi-api/docs/endpoints.md`).
abstract interface class SellerSupportRepository {
  /// `GET /products/mine/slow`.
  Future<SlowListings> slow();

  /// `GET /products/{id}/demand`.
  Future<ProductDemand> demand(String productId);
}

/// Modo demo y vitrina sin cuenta: nada lleva tiempo sin venderse.
class EmptySellerSupportRepository implements SellerSupportRepository {
  const new();

  @override
  Future<SlowListings> slow() async => const SlowListings();

  @override
  Future<ProductDemand> demand(String productId) async => const ProductDemand();
}
