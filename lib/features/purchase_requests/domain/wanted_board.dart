import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/purchase_requests/domain/wanted_models.dart';

// Tablero "Se busca" (HU-15): la hoja "Filtrar solicitudes" y la lupa de la
// maqueta `Se-busca`. Forma canonica: fila `GET /api/v1/wanted` de
// musubi-api `docs/endpoints.md`.

/// "Presupuesto" (`BUDGETS` de la maqueta). Los rangos son inclusivos y en
/// centavos, como los pide la API.
enum WantedBudget {
  any('Cualquier presupuesto'),
  upTo300(r'Hasta $300', max: 30000),
  from300To1000(r'$300 – $1,000', min: 30000, max: 100000),
  over1000(r'Más de $1,000', min: 100001);

  new(this.label, {this.min, this.max});

  final String label;
  final int? min;
  final int? max;
}

/// "Fecha límite" (`DEADLINES` de la maqueta): las que la necesitan en ese
/// plazo. Una solicitud sin fecha no sale con este filtro.
enum WantedDeadline {
  any('Cualquier fecha'),
  within3('En 3 días o menos', days: 3),
  thisWeek('Esta semana', days: 7);

  new(this.label, {this.days});

  final String label;
  final int? days;
}

/// Filtros del tablero. [categories] guarda el slug y el nombre para el
/// subtitulo "Laboratorio, Libros" de la hoja.
@immutable
class WantedBoardFilter {
  const new({
    this.categories = const [],
    this.budget = WantedBudget.any,
    this.deadline = WantedDeadline.any,
    this.query = '',
  });

  final List<CatalogCategory> categories;
  final WantedBudget budget;
  final WantedDeadline deadline;

  /// Lo escrito en la lupa ("Busca solicitudes: bata, laptop…").
  final String query;

  /// Filtros activos de la hoja (el numero del boton); la lupa no cuenta.
  int get count =>
      categories.length +
      (budget == WantedBudget.any ? 0 : 1) +
      (deadline == WantedDeadline.any ? 0 : 1);

  /// Hay algo que reduce la lista (hoja o lupa).
  bool get narrowed => count > 0 || query.trim().isNotEmpty;

  WantedBoardFilter copyWith({
    List<CatalogCategory>? categories,
    WantedBudget? budget,
    WantedDeadline? deadline,
    String? query,
  }) => WantedBoardFilter(
    categories: categories ?? this.categories,
    budget: budget ?? this.budget,
    deadline: deadline ?? this.deadline,
    query: query ?? this.query,
  );

  /// Parametros de `GET /api/v1/wanted` (`category` se repite).
  Map<String, Object> toQuery() {
    final q = query.trim();
    return {
      if (categories.isNotEmpty)
        'category': [for (final c in categories) c.slug],
      'minBudgetCents': ?budget.min,
      'maxBudgetCents': ?budget.max,
      'neededWithinDays': ?deadline.days,
      if (q.isNotEmpty) 'q': q,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is WantedBoardFilter &&
      listEquals(
        [for (final c in other.categories) c.slug],
        [for (final c in categories) c.slug],
      ) &&
      other.budget == budget &&
      other.deadline == deadline &&
      other.query == query;

  @override
  int get hashCode => Object.hash(
    Object.hashAll([for (final c in categories) c.slug]),
    budget,
    deadline,
    query,
  );
}

/// Una pagina del tablero.
@immutable
class WantedPage {
  const new({this.items = const [], this.nextCursor});

  final List<WantedRequest> items;

  /// Id de la ultima, o `null` si no hay mas.
  final String? nextCursor;
}
