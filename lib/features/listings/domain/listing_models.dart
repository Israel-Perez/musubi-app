import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Estado del producto (maqueta `Vender-4`).
enum ProductCondition {
  brandNew('new', 'Nuevo', 'Sin usar, en su empaque'),
  used('used', 'Usado', 'Ya tuvo uso');

  new(this.apiValue, this.label, this.description);

  /// Valor del contrato (`CreateProductRequest.condition`).
  final String apiValue;
  final String label;
  final String description;
}

/// "¿Cómo está?" de un producto usado (maqueta `Vender-4`).
enum UsedDetail {
  likeNew('likeNew', 'Como nuevo'),
  good('good', 'Buen estado'),
  fair('fair', 'Con detalles');

  new(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Lo que se publica (`CreateProductRequest` de musubi-api, HU-06).
@immutable
class NewListing {
  const new({
    required this.title,
    required this.description,
    required this.category,
    required this.priceCents,
    required this.condition,
    required this.quantity,
    required this.photoKeys,
    this.usedDetail,
  });

  final String title;
  final String description;

  /// `slug` de la categoria.
  final String category;
  final int priceCents;
  final ProductCondition condition;

  /// Solo con [ProductCondition.used].
  final UsedDetail? usedDetail;

  /// Piezas disponibles (1 a 10, HU-50).
  final int quantity;

  /// Llaves de las fotos ya subidas; la primera es la portada.
  final List<String> photoKeys;

  Map<String, Object?> toJson() => {
    'title': title.trim(),
    'description': description.trim(),
    'category': category,
    'priceCents': priceCents,
    'condition': condition.apiValue,
    'conditionDetail': condition == ProductCondition.used
        ? usedDetail?.apiValue
        : null,
    'stock': quantity,
    'photos': photoKeys,
  };
}

/// Foto subida (`PhotoResponse`): la llave va en la publicacion.
@immutable
class UploadedPhoto {
  const new({required this.key, required this.url});

  final String key;
  final String url;
}

/// "Productos parecidos se venden entre…" (maqueta `Vender-3`).
@immutable
class PriceRange {
  const new({required this.lowCents, required this.highCents});

  final int lowCents;
  final int highCents;
}

/// Estado de una publicacion propia ("Mis productos").
enum ListingStatus { active, soldOut, hidden }

/// Publicacion propia con su estado.
@immutable
class OwnListing {
  const new({required this.product, required this.status});

  final ProductSummary product;
  final ListingStatus status;
}
