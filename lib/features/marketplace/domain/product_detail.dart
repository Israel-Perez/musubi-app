import 'package:flutter/foundation.dart';

/// Detalle de una publicacion (maqueta `Producto`, HU-11). Forma canonica:
/// fila `GET /api/v1/products/{id}` de musubi-api `docs/endpoints.md`.
@immutable
class ProductDetail {
  const new({
    required this.id,
    required this.title,
    required this.description,
    required this.categoryName,
    required this.priceCents,
    required this.condition,
    required this.stock,
    required this.status,
    required this.photoUrls,
    required this.publishedAt,
    this.conditionDetail,
    this.sellerId,
    this.sellerName,
  });

  final String id;
  final String title;
  final String description;
  final String categoryName;
  final int priceCents;

  /// `new` o `used`.
  final String condition;

  /// `likeNew`, `good` o `fair`.
  final String? conditionDetail;
  final int stock;

  /// `active`, `soldOut` o `hidden` (solo su dueno la ve pausada).
  final String status;
  final List<String> photoUrls;
  final DateTime publishedAt;

  /// `null` sin sesion: la API no muestra al vendedor a visitantes (RNF-05).
  final String? sellerId;
  final String? sellerName;

  bool get soldOut => status == 'soldOut' || stock <= 0;

  /// "Usado" o "Nuevo" (tarjeta "Estado").
  String get conditionName => condition == 'new' ? 'Nuevo' : 'Usado';

  /// "Usado · Como nuevo" (la pastilla junto al precio).
  String get conditionLabel => switch ((condition, conditionDetail)) {
    ('new', _) => 'Nuevo',
    (_, 'likeNew') => 'Usado · Como nuevo',
    (_, 'good') => 'Usado · Buen estado',
    (_, 'fair') => 'Usado · Con detalles',
    _ => 'Usado',
  };
}
