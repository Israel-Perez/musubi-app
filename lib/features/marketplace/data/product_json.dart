import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// `ProductResponse` de musubi-api (fixture `product.json`) → tarjeta de la
/// vitrina. Las fotos llegan como rutas (`/media/...`) relativas a la URL
/// base de la API: CloudFront sirve la API y las imagenes en el mismo dominio.
ProductSummary productFromJson(Map<String, dynamic> json, Uri apiBaseUrl) {
  final photos = (json['photos'] as List<dynamic>).cast<String>();
  final seller = json['seller'] as Map<String, dynamic>?;
  return ProductSummary(
    id: json['id'] as String,
    title: json['title'] as String,
    priceCents: (json['priceCents'] as num).toInt(),
    stock: json['status'] == 'soldOut' ? 0 : (json['stock'] as num).toInt(),
    photoUrl: photos.isEmpty ? null : mediaUrl(photos.first, apiBaseUrl),
    category: json['category'] as String?,
    condition: json['condition'] == 'new' ? 'Nuevo' : 'Usado',
    sellerName: seller?['name'] as String?,
    publishedAt: DateTime.parse(json['publishedAt'] as String).toUtc(),
  );
}

/// Ruta de una imagen de la API (`/media/...`) → URL completa.
String mediaUrl(String path, Uri apiBaseUrl) =>
    apiBaseUrl.replace(path: path).toString();

/// Foto de la tarjeta de una categoria en "Filtrar" (ilustraciones de la
/// maqueta empaquetadas en la app).
String? categoryPhoto(String slug) => switch (slug) {
  'calculadoras' => 'asset:assets/products/casio.webp',
  'libros' => 'asset:assets/products/calculo.webp',
  'laptops' => 'asset:assets/products/laptop.webp',
  'laboratorio' => 'asset:assets/products/bata.webp',
  'dibujo' => 'asset:assets/products/set-dibujo.webp',
  'electronica' => 'asset:assets/products/arduino.webp',
  _ => null,
};
