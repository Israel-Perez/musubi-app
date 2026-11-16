import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Quien vende una opcion de "Compara antes de comprar" (HU-51).
@immutable
class ComparisonSeller {
  const new({
    required this.id,
    required this.name,
    this.ratingAvg,
    this.ratingCount = 0,
    this.sales,
  });

  final String id;

  /// Nombre corto ("Valeria C.").
  final String name;

  /// Promedio, o `null` sin calificaciones (RN-26).
  final double? ratingAvg;
  final int ratingCount;

  /// Ventas, o `null` si la persona las oculta (HU-04).
  final int? sales;
}

/// Una publicacion que se compara (`ComparisonItemResponse` de musubi-api).
@immutable
class ComparisonOption {
  const new({
    required this.product,
    required this.seller,
    this.sameModel = false,
  });

  final ProductSummary product;
  final ComparisonSeller seller;

  /// Comparte el codigo del modelo con la que se ve ("Mismo modelo").
  final bool sameModel;
}

/// Las pestanas de "Ordenar por" de la maqueta.
enum CompareOrder {
  forYou('Para ti', 'Combina reputación, ventas y precio.'),
  reputation(
    'Reputación',
    'Calificación de quien vende y cuántas opiniones tiene.',
  ),
  sales('Ventas', 'Quién ha vendido más en Musubi.'),
  price('Precio', 'Del más barato al más caro.');

  new(this.label, this.explanation);

  final String label;

  /// La linea de "i" debajo de las pestanas.
  final String explanation;
}

/// La insignia de una opcion (solo con 2 o mas opciones).
enum CompareBadge {
  bestReputation('Mejor reputación'),
  mostSales('Más ventas'),
  lowestPrice('Precio más bajo');

  new(this.label);

  final String label;
}

/// "Buen precio", "Precio justo" o "Arriba del promedio".
enum PriceVerdict {
  good('Buen precio'),
  fair('Precio justo'),
  high('Arriba del promedio');

  new(this.label);

  final String label;
}

/// Una opcion ya puntuada para la lista.
@immutable
class RankedOption {
  const new({
    required this.option,
    required this.rank,
    required this.reputation,
    required this.score,
    required this.differenceCents,
    this.badge,
    this.best = false,
  });

  final ComparisonOption option;

  /// 1, 2, 3… en el orden elegido.
  final int rank;

  /// Calificacion ponderada: con pocas opiniones pesa menos.
  final double reputation;

  /// "Para ti": 45 % reputacion, 25 % ventas y 30 % precio, mas el modelo.
  final double score;

  /// Precio de la opcion menos el de la que se ve.
  final int differenceCents;
  final CompareBadge? badge;

  /// "Mejor opción": la primera de "Para ti".
  final bool best;
}

/// La barra "Este modelo en UTTT": los precios de referencia y el de la que se
/// ve, en porcentajes de la barra.
@immutable
class PriceBand {
  const new({
    required this.minCents,
    required this.maxCents,
    required this.averageCents,
    required this.currentPercent,
    required this.otherPercents,
    required this.verdict,
    required this.sameModel,
  });

  final int minCents;
  final int maxCents;
  final int averageCents;
  final int currentPercent;
  final List<int> otherPercents;
  final PriceVerdict verdict;

  /// Las referencias son del mismo modelo (si no, de la categoria).
  final bool sameModel;
}

/// "Compara antes de comprar" con las reglas de la maqueta (`compareVals`).
/// La API elige las opciones; aqui se puntuan y se ordenan.
@immutable
class Comparison {
  new(this.currentPriceCents, List<ComparisonOption> options)
    : options = List.unmodifiable(options);

  /// Peso de la calificacion "a priori" (4.5 con 10 opiniones).
  static const priorRating = 4.5;
  static const priorCount = 10;

  final int currentPriceCents;
  final List<ComparisonOption> options;

  bool get isEmpty => options.isEmpty;

  int get sameModelCount => options.where((o) => o.sameModel).length;

  /// Calificacion ponderada (`(calif * n + 4.5 * 10) / (n + 10)`).
  static double weightedReputation(ComparisonSeller seller) =>
      ((seller.ratingAvg ?? 0) * seller.ratingCount +
          priorRating * priorCount) /
      (seller.ratingCount + priorCount);

  /// Las opciones en el orden de la pestana, con su lugar, insignia y si es la
  /// "Mejor opción".
  List<RankedOption> ranked(CompareOrder order) {
    if (options.isEmpty) return const [];
    final reputation = [for (final o in options) weightedReputation(o.seller)];
    final sales = [for (final o in options) (o.seller.sales ?? 0).toDouble()];
    final prices = [for (final o in options) o.product.priceCents.toDouble()];
    double normalize(double x, List<double> values) {
      final low = values.reduce((a, b) => a < b ? a : b);
      final high = values.reduce((a, b) => a > b ? a : b);
      return high == low ? 1 : (x - low) / (high - low);
    }

    final scores = [
      for (var i = 0; i < options.length; i++)
        0.45 * normalize(reputation[i], reputation) +
            0.25 * normalize(sales[i], sales) +
            0.30 * (1 - normalize(prices[i], prices)) +
            (options[i].sameModel ? 0.08 : 0),
    ];

    // El primero que gana se queda (como `reduce` de la maqueta).
    int leader(List<double> values, {bool lowest = false}) {
      var best = 0;
      for (var i = 1; i < values.length; i++) {
        if (lowest ? values[i] < values[best] : values[i] > values[best]) {
          best = i;
        }
      }
      return best;
    }

    final topReputation = leader(reputation);
    final topSales = leader(sales);
    final topPrice = leader(prices, lowest: true);
    CompareBadge? badgeOf(int i) => options.length < 2
        ? null
        : i == topReputation
        ? CompareBadge.bestReputation
        : i == topSales
        ? CompareBadge.mostSales
        : i == topPrice
        ? CompareBadge.lowestPrice
        : null;

    final indexes = List<int>.generate(options.length, (i) => i);
    int compare(int a, int b) => switch (order) {
      CompareOrder.forYou => scores[b].compareTo(scores[a]),
      CompareOrder.reputation => reputation[b].compareTo(reputation[a]),
      CompareOrder.sales => sales[b].compareTo(sales[a]),
      CompareOrder.price => prices[a].compareTo(prices[b]),
    };
    // Orden estable: en empate se queda el orden de la API.
    indexes.sort((a, b) {
      final byOrder = compare(a, b);
      return byOrder != 0 ? byOrder : a.compareTo(b);
    });
    return [
      for (var place = 0; place < indexes.length; place++)
        RankedOption(
          option: options[indexes[place]],
          rank: place + 1,
          reputation: reputation[indexes[place]],
          score: scores[indexes[place]],
          differenceCents:
              options[indexes[place]].product.priceCents - currentPriceCents,
          badge: badgeOf(indexes[place]),
          best: order == CompareOrder.forYou && place == 0,
        ),
    ];
  }

  /// La barra de precios: con el mismo modelo, solo esos; si no, la categoria.
  PriceBand? get priceBand {
    if (options.isEmpty) return null;
    final same = options.where((o) => o.sameModel).toList();
    final reference = same.isNotEmpty ? same : options;
    final prices = [
      currentPriceCents,
      for (final o in reference) o.product.priceCents,
    ];
    final low = prices.reduce((a, b) => a < b ? a : b);
    final high = prices.reduce((a, b) => a > b ? a : b);
    // Como la maqueta: el promedio en pesos cerrados ($443).
    final average =
        (prices.reduce((a, b) => a + b) / prices.length / 100).round() * 100;
    int percent(int cents) =>
        high == low ? 100 : ((cents - low) / (high - low) * 100).round();
    final deviation = (currentPriceCents - average) / average;
    return PriceBand(
      minCents: low,
      maxCents: high,
      averageCents: average,
      currentPercent: percent(currentPriceCents),
      otherPercents: [for (final o in reference) percent(o.product.priceCents)],
      verdict: deviation < -0.05
          ? PriceVerdict.good
          : deviation > 0.05
          ? PriceVerdict.high
          : PriceVerdict.fair,
      sameModel: same.isNotEmpty,
    );
  }
}

/// "Ver todas las calculadoras" (el boton al final del comparador).
String seeAllLabel(String? categoryName) => switch (categoryName) {
  'Calculadoras' => 'Ver todas las calculadoras',
  'Libros' => 'Ver todos los libros',
  'Laptops' => 'Ver todas las laptops',
  'Laboratorio' => 'Ver todo de laboratorio',
  'Dibujo' => 'Ver todo de dibujo',
  'Electrónica' => 'Ver toda la electrónica',
  _ => 'Ver más como este',
};

/// Comparar y "Avísame" (filas de HU-51 en `musubi-api/docs/endpoints.md`).
abstract interface class ComparisonRepository {
  /// "Compara antes de comprar" (hasta 5).
  Future<List<ComparisonOption>> compare(String productId);

  /// Si ya pedi "Avísame" de esta publicacion.
  Future<bool> stockAlert(String productId);

  /// "Avísame" (una agotada que no es mia).
  Future<void> watch(String productId);

  /// Quita el aviso (idempotente).
  Future<void> unwatch(String productId);
}
