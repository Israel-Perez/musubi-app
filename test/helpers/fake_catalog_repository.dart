import 'dart:async';

import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';

/// Fake de [CatalogRepository]: responde en orden y registra los periodos y
/// los filtros.
class FakeCatalogRepository implements CatalogRepository {
  new([
    List<Object> responses = const [HomeFeed()],
    List<Object> searchResponses = const [ProductPage()],
  ]) : _responses = [...responses],
       _searchResponses = [...searchResponses];

  /// Nunca responde (estado "cargando").
  factory pending() => FakeCatalogRepository([Completer<HomeFeed>()]);

  final List<Object> _responses;
  final List<Object> _searchResponses;
  final List<PopularPeriod> periods = [];
  final List<CatalogFilter> filters = [];
  final List<String> queries = [];
  final List<SearchFilter> searchFilters = [];
  final List<String?> cursors = [];

  /// Categorias que devuelve `categories()`.
  List<CatalogCategory> categoriesResponse = const [];

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

  @override
  Future<ProductPage> search({
    required String query,
    SearchFilter filter = const SearchFilter(),
    String? cursor,
  }) {
    queries.add(query);
    searchFilters.add(filter);
    cursors.add(cursor);
    final next = _searchResponses.length > 1
        ? _searchResponses.removeAt(0)
        : _searchResponses.first;
    return switch (next) {
      final ProductPage page => Future.value(page),
      final ApiFailure failure => Future.error(failure),
      final Completer<ProductPage> completer => completer.future,
      _ => throw StateError('Respuesta no soportada: $next'),
    };
  }

  @override
  Future<List<CatalogCategory>> categories() async => categoriesResponse;

  /// Detalles por id (HU-11). Sin el id: 404 como la API.
  final Map<String, ProductDetail> details = {};

  @override
  Future<ProductDetail> product(String id) async {
    final found = details[id];
    if (found == null) {
      throw const ApiFailure(
        code: 'listings.product_not_found',
        message: 'Esta publicación ya no está disponible.',
        status: 404,
      );
    }
    return found;
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
