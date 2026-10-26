import 'package:flutter/foundation.dart';

/// Periodo de "Populares" (maqueta: Hoy / Semana; HU-49).
enum PopularPeriod {
  today('Hoy'),
  week('Semana');

  new(this.label);

  final String label;
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
  });

  final String id;
  final String title;

  /// Precio en centavos (entero, como en la base).
  final int priceCents;

  /// Piezas disponibles; 0 = agotado (HU-50).
  final int stock;
  final String? photoUrl;

  /// Vistas en el periodo de "Populares" (`productStatsDaily`).
  final int views;

  bool get soldOut => stock <= 0;

  /// Etiqueta de inventario de la maqueta: "Quedan 2", "Último" o nada.
  String? get stockLabel => switch (stock) {
    <= 0 => null,
    1 => 'Último',
    <= 3 => 'Quedan $stock',
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
  });

  final String id;
  final String title;
  final int budgetCents;
  final DateTime neededBy;
}

/// Lo que muestra Inicio.
@immutable
class HomeFeed {
  const new({
    this.popular = const [],
    this.recent = const [],
    this.wanted = const [],
  });

  final List<ProductSummary> popular;
  final List<ProductSummary> recent;
  final List<WantedSummary> wanted;
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
