import 'package:flutter/foundation.dart';

/// Estado de la publicacion que se puede filtrar (HU-10).
enum ProductConditionFilter {
  all('Todos', null),
  newItem('Nuevo', 'new'),
  used('Usado', 'used');

  new(this.label, this.apiValue);

  final String label;

  /// Valor de `condition` en `GET /api/v1/products`.
  final String? apiValue;

  /// Etiqueta que usa la tarjeta (`ProductSummary.condition`).
  String? get productLabel => switch (this) {
    all => null,
    newItem => 'Nuevo',
    used => 'Usado',
  };
}

/// Filtros de `Busqueda-filtros` (HU-10): categoria, rango de precio, estado
/// y agotados.
///
/// Es distinto de `CatalogFilter`: Inicio conserva su hoja de categoria y
/// "Ocultar agotados".
@immutable
class SearchFilter {
  const new({
    this.categories = const [],
    this.minCents,
    this.maxCents,
    this.condition = ProductConditionFilter.all,
    this.hideSoldOut = true,
  });

  /// `slug` de las categorias elegidas; vacio es todas.
  final List<String> categories;

  /// Precio minimo inclusivo en centavos; `null` es sin limite.
  final int? minCents;

  /// Precio maximo inclusivo en centavos; `null` es sin limite.
  final int? maxCents;

  final ProductConditionFilter condition;

  /// `true` oculta los agotados; por defecto, como la maqueta.
  final bool hideSoldOut;

  /// Numero de filtros activos (el globo del boton).
  int get count =>
      (categories.isEmpty ? 0 : 1) +
      (minCents == null && maxCents == null ? 0 : 1) +
      (condition == ProductConditionFilter.all ? 0 : 1) +
      (hideSoldOut ? 0 : 1);

  bool get isEmpty => count == 0;

  @override
  bool operator ==(Object other) =>
      other is SearchFilter &&
      listEquals(other.categories, categories) &&
      other.minCents == minCents &&
      other.maxCents == maxCents &&
      other.condition == condition &&
      other.hideSoldOut == hideSoldOut;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(categories),
    minCents,
    maxCents,
    condition,
    hideSoldOut,
  );
}
