import 'dart:async';

import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Fake de [CatalogRepository]: responde en orden y registra los periodos y
/// los filtros.
class FakeCatalogRepository implements CatalogRepository {
  new([List<Object> responses = const [HomeFeed()]])
    : _responses = [...responses];

  /// Nunca responde (estado "cargando").
  factory pending() => FakeCatalogRepository([Completer<HomeFeed>()]);

  final List<Object> _responses;
  final List<PopularPeriod> periods = [];
  final List<CatalogFilter> filters = [];

  @override
  Future<HomeFeed> homeFeed({
    required PopularPeriod period,
    CatalogFilter filter = const CatalogFilter(),
  }) {
    periods.add(period);
    filters.add(filter);
    final next = _responses.length > 1
        ? _responses.removeAt(0)
        : _responses.first;
    return switch (next) {
      final HomeFeed feed => Future.value(feed),
      final ApiFailure failure => Future.error(failure),
      final Completer<HomeFeed> completer => completer.future,
      _ => throw StateError('Respuesta no soportada: $next'),
    };
  }
}

const offlineFailure = ApiFailure(
  code: ApiFailure.networkOffline,
  message: 'Sin conexión.',
);

/// Vitrina con datos de muestra (ficticios, como en la maqueta).
final sampleFeed = HomeFeed(
  popular: const [
    ProductSummary(
      id: 'p1',
      title: 'Calculadora Casio fx-991ES',
      priceCents: 45000,
      stock: 2,
      views: 128,
    ),
    ProductSummary(
      id: 'p2',
      title: 'Laptop Lenovo IdeaPad 5',
      priceCents: 1180000,
      stock: 1,
      views: 96,
    ),
  ],
  recent: const [
    ProductSummary(
      id: 'p3',
      title: 'Audífonos inalámbricos',
      priceCents: 65000,
      stock: 0,
    ),
  ],
  wanted: [
    WantedSummary(
      id: 'w1',
      title: 'Bata de laboratorio talla M',
      budgetCents: 30000,
      neededBy: DateTime(2026, 10, 5),
    ),
  ],
);
