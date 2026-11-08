/// Orden de los resultados de la busqueda (HU-10).
enum SearchSort {
  relevant('Más relevantes', 'relevant'),
  recent('Más recientes', 'recent'),
  priceAsc('Menor precio', 'priceAsc'),
  priceDesc('Mayor precio', 'priceDesc');

  new(this.label, this.apiValue);

  final String label;

  /// Valor de `sort` en `GET /api/v1/products`.
  final String apiValue;
}
