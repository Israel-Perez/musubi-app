import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/features/marketplace/data/demo_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';

// SCRUM-82: la vitrina de muestra (solo dev) reproduce los datos de la
// maqueta `Inicio-visitante` para revisar el diseno en un celular.
void main() {
  final now = DateTime.utc(2026, 10, 5, 20);
  final repository = DemoCatalogRepository(() => now);

  test('populares de hoy: el ranking de la maqueta, sin agotados', () async {
    final feed = await repository.homeFeed(period: PopularPeriod.today);

    expect(feed.popular.map((p) => p.title), [
      'Calculadora Casio fx-991ES Plus',
      'Laptop Lenovo IdeaPad 5, Ryzen 7, 16 GB de RAM',
      'Bata de laboratorio',
      'Set de dibujo técnico',
      'Cálculo de una variable, Stewart 8a ed.',
    ]);
    expect(feed.popular.first.views, 128);
    expect(feed.popular.every((p) => !p.soldOut), isTrue);
  });

  test('populares de la semana cambian el ranking', () async {
    final feed = await repository.homeFeed(period: PopularPeriod.week);

    expect(feed.popular.first.title, 'Set de dibujo técnico');
    expect(feed.popular.first.views, 912);
  });

  test('recien publicados: el mosaico de "Todo" empieza como la maqueta', () {
    return repository.homeFeed(period: PopularPeriod.today).then((feed) {
      expect(feed.recent.take(6).map((p) => p.title), [
        'Calculadora Casio fx-991ES Plus',
        'Set de dibujo técnico',
        'Laptop Lenovo IdeaPad 5, Ryzen 7, 16 GB de RAM',
        'Bata de laboratorio',
        'Audífonos inalámbricos',
        'Cálculo de una variable, Stewart 8a ed.',
      ]);
      expect(feed.recent[4].stockLabel, isNull);
      expect(feed.recent[4].soldOut, isTrue);
      expect(feed.categories, hasLength(5));
      expect(feed.recentTotal, 48);
    });
  });

  test('filtro: una categoria y ocultar agotados', () async {
    final tech = await repository.homeFeed(
      period: PopularPeriod.today,
      filter: const CatalogFilter(category: 'tecnologia'),
    );
    final available = await repository.homeFeed(
      period: PopularPeriod.today,
      filter: const CatalogFilter(category: 'tecnologia', hideSoldOut: true),
    );

    expect(tech.recent.every((p) => p.category == 'tecnologia'), isTrue);
    expect(tech.recent.any((p) => p.soldOut), isTrue);
    expect(available.recent.any((p) => p.soldOut), isFalse);
    expect(available.recent.length, lessThan(tech.recent.length));
  });

  test('"hace 20 min" se cuenta desde el reloj de la app', () async {
    final feed = await repository.homeFeed(period: PopularPeriod.today);
    final laptop = feed.recent.firstWhere((p) => p.id == 'lenovo');

    expect(timeAgo(laptop.publishedAt!, now), 'hace 20 min');
    expect(timeAgo(feed.wanted.first.createdAt!, now), 'hace 20 min');
    expect(shortDate(feed.wanted.first.neededBy!), 'lun 5 oct');
  });

  test('con sesion, lo mas nuevo primero (maqueta Inicio)', () async {
    final feed = await repository.homeFeed(period: PopularPeriod.today);

    expect(feed.newestFirst.take(4).map((p) => p.title), [
      'Laptop Lenovo IdeaPad 5, Ryzen 7, 16 GB de RAM',
      'Cálculo de una variable, Stewart 8a ed.',
      'Bata de laboratorio',
      'Calculadora Casio fx-991LA X',
    ]);
  });

  test('lo mas nuevo primero: sin fecha al final y empates en orden', () {
    ProductSummary at(String id, int? minutesAgo) => ProductSummary(
      id: id,
      title: id,
      priceCents: 100,
      stock: 1,
      publishedAt: minutesAgo == null
          ? null
          : now.subtract(Duration(minutes: minutesAgo)),
    );
    final feed = HomeFeed(
      recent: [
        at('sin-fecha', null),
        at('viejo', 90),
        at('nuevo-a', 5),
        at('nuevo-b', 5),
      ],
    );

    expect(feed.newestFirst.map((p) => p.id), [
      'nuevo-a',
      'nuevo-b',
      'viejo',
      'sin-fecha',
    ]);
  });

  // HU-09: la busqueda de muestra aproxima la palabra completa de la API.
  test(
    'busqueda de muestra: plural, sin agotados y mas nueva primero',
    () async {
      final plural = await repository.search(query: 'calculadoras');
      final casio = await repository.search(query: 'casio');
      final soldOut = await repository.search(query: 'audifonos');

      expect(
        plural.items.map((p) => p.title),
        contains('Calculadora Casio fx-991ES Plus'),
      );
      expect(plural.items.every((p) => !p.soldOut), isTrue);
      expect(casio.items.first.title, 'Calculadora Casio fx-991LA X');
      expect(soldOut.items, isEmpty);
      expect(soldOut.total, 0);
    },
  );

  test('busqueda de muestra: coincide por prefijo de palabra', () async {
    final page = await repository.search(query: 'calc');
    final infix = await repository.search(query: 'culadora');

    expect(
      page.items.map((p) => p.title),
      contains('Calculadora Casio fx-991ES Plus'),
    );
    expect(infix.items, isEmpty);
  });

  test('busqueda de muestra: la pagina 2 viene vacia', () async {
    final page = await repository.search(query: 'casio', page: 2);

    expect(page.items, isEmpty);
  });

  test('busqueda de muestra: categoria, precio inclusivo y estado', () async {
    final used = await repository.search(
      query: 'calculadora',
      filter: const SearchFilter(
        categories: ['calculadoras'],
        minCents: 45000,
        maxCents: 52000,
        condition: ProductConditionFilter.used,
      ),
    );
    final brandNew = await repository.search(
      query: 'calculadora',
      filter: const SearchFilter(
        categories: ['calculadoras'],
        minCents: 45000,
        maxCents: 52000,
        condition: ProductConditionFilter.newItem,
      ),
    );

    expect(used.items.map((p) => p.title), ['Calculadora Casio fx-991ES Plus']);
    expect(brandNew.items.map((p) => p.title), [
      'Calculadora Casio fx-991LA X',
    ]);
  });

  test('categories devuelve las del campus', () async {
    final categories = await repository.categories();

    expect(categories.map((c) => c.slug), contains('calculadoras'));
    expect(categories, hasLength(5));
  });

  test('perfil del vendedor: demo-<vendedor> devuelve sus activas', () async {
    final page = await repository.sellerListings('demo-valeria-c');
    final missing = await repository.sellerListings('demo-no-existe');
    final second = await repository.sellerListings('demo-valeria-c', page: 2);

    expect(page.total, 2);
    expect(page.items.map((p) => p.id), ['casio-991es', 'compas']);
    expect(page.items.first.publishedAt, isNotNull);
    expect(missing.items, isEmpty);
    expect(second.items, isEmpty);
  });

  test('pocas piezas: "Último" con 1 y "Quedan 2" con 2 (maqueta)', () {
    ProductSummary withStock(int stock) =>
        ProductSummary(id: 'x', title: 'x', priceCents: 100, stock: stock);

    expect(withStock(1).stockLabel, 'Último');
    expect(withStock(2).stockLabel, 'Quedan 2');
    expect(withStock(3).stockLabel, isNull);
    expect(withStock(0).stockLabel, isNull);
  });
}
