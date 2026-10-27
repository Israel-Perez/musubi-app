import 'package:flutter/foundation.dart';

/// Periodo de "Populares" (maqueta: Hoy / Semana; HU-49).
enum PopularPeriod {
  today('Hoy'),
  week('Semana');

  new(this.label);

  final String label;
}

/// Categoria del catalogo (coleccion `categories` de musubi-api, HU-41).
@immutable
class CatalogCategory {
  const new({required this.slug, required this.name, this.photoUrl});

  final String slug;
  final String name;

  /// Foto de la tarjeta de la categoria en "Filtrar".
  final String? photoUrl;

  @override
  bool operator ==(Object other) =>
      other is CatalogCategory && other.slug == slug && other.name == name;

  @override
  int get hashCode => Object.hash(slug, name);
}

/// Filtro de "Recién publicados" (maqueta `Inicio-visitante`, HU-10):
/// una categoria (o todas) y "Ocultar agotados".
@immutable
class CatalogFilter {
  const new({this.category, this.hideSoldOut = false});

  /// `slug` de la categoria; `null` es "Todo".
  final String? category;
  final bool hideSoldOut;

  /// Numero de filtros activos (el globo del boton).
  int get count => (category == null ? 0 : 1) + (hideSoldOut ? 1 : 0);

  @override
  bool operator ==(Object other) =>
      other is CatalogFilter &&
      other.category == category &&
      other.hideSoldOut == hideSoldOut;

  @override
  int get hashCode => Object.hash(category, hideSoldOut);
}

/// Tarjeta de producto de la vitrina (modelo `products` de musubi-api 02-01).
@immutable
class ProductSummary {
  const new({
    required this.id,
    required this.title,
    required this.priceCents,
    required this.stock,
    this.photoUrl,
    this.views = 0,
    this.category,
    this.condition,
    this.sellerName,
    this.sellerRating,
    this.publishedAt,
  });

  final String id;
  final String title;

  /// Precio en centavos (entero, como en la base).
  final int priceCents;

  /// Piezas disponibles; 0 = agotado (HU-50).
  final int stock;

  /// Foto en la red o, con el esquema `asset:`, empaquetada en la app.
  final String? photoUrl;

  /// Vistas en el periodo de "Populares" (`productStatsDaily`).
  final int views;

  /// `slug` de la categoria.
  final String? category;

  /// "Usado" o "Nuevo".
  final String? condition;

  /// Copia del vendedor en el producto (`seller{name, ratingAvg}`).
  final String? sellerName;
  final double? sellerRating;
  final DateTime? publishedAt;

  bool get soldOut => stock <= 0;

  /// Pocas piezas (maqueta: 1 o 2): "Último" o "Quedan 2".
  String? get stockLabel => switch (stock) {
    1 => 'Último',
    2 => 'Quedan 2',
    _ => null,
  };
}

/// Boleto "Se busca" (HU-13/HU-15): alguien pide algo y paga hasta X.
@immutable
class WantedSummary {
  const new({
    required this.id,
    required this.title,
    required this.budgetCents,
    required this.neededBy,
    this.category,
    this.categoryName,
    this.createdAt,
  });

  final String id;
  final String title;
  final int budgetCents;
  final DateTime neededBy;

  /// `slug` de la categoria (elige el icono del boleto).
  final String? category;
  final String? categoryName;
  final DateTime? createdAt;
}

/// Lo que muestra Inicio.
@immutable
class HomeFeed {
  const new({
    this.popular = const [],
    this.recent = const [],
    this.wanted = const [],
    this.categories = const [],
    this.recentTotal = 0,
  });

  final List<ProductSummary> popular;
  final List<ProductSummary> recent;
  final List<WantedSummary> wanted;

  /// Categorias para "Filtrar" (sin categorias no se muestra el filtro).
  final List<CatalogCategory> categories;

  /// Total de recien publicados ("Ver todo lo nuevo · 48 productos").
  final int recentTotal;

  /// [recent] del mas nuevo al mas viejo, como "Publicaciones recientes" de
  /// la maqueta `Inicio` ("hace 20 min", "hace 1 h"…). Sin fecha van al final
  /// y los empates conservan su orden.
  List<ProductSummary> get newestFirst {
    final indexed = recent.indexed.toList()
      ..sort((a, b) {
        final byDate = switch ((a.$2.publishedAt, b.$2.publishedAt)) {
          (final x?, final y?) => y.compareTo(x),
          (null, null) => 0,
          (null, _) => 1,
          (_, null) => -1,
        };
        return byDate != 0 ? byDate : a.$1.compareTo(b.$1);
      });
    return [for (final (_, product) in indexed) product];
  }
}

/// "$11,800" (pesos sin centavos si son cero).
String formatPrice(int cents) {
  final pesos = cents ~/ 100;
  final digits = pesos.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  final rest = cents % 100;
  return rest == 0
      ? '\$$buffer'
      : '\$$buffer.${rest.toString().padLeft(2, '0')}';
}

const _days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
const _months = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

/// "lun 5 oct".
String shortDate(DateTime date) =>
    '${_days[date.weekday - 1]} ${date.day} ${_months[date.month - 1]}';

/// "hace 20 min", "hace 3 h", "ayer", "hace 5 días" (`whenText` de la
/// maqueta).
String timeAgo(DateTime then, DateTime now) {
  final minutes = now.difference(then).inMinutes;
  if (minutes < 60) return 'hace ${minutes < 1 ? 1 : minutes} min';
  if (minutes < 1440) return 'hace ${(minutes / 60).round()} h';
  if (minutes < 2880) return 'ayer';
  final days = (minutes / 1440).round();
  if (days < 14) return 'hace $days días';
  if (days < 60) return 'hace ${(days / 7).round()} semanas';
  return 'hace ${(days / 30).round()} meses';
}
