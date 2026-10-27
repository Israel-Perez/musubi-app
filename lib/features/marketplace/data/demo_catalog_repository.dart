import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Vitrina de muestra con los productos ficticios de la maqueta
/// (`Inicio-visitante`): solo con `DEMO_CATALOG=true` en `dev`, para revisar
/// el diseno en un celular mientras no hay catalogo real.
/// NOTE (HU-06): se queda para pruebas y demos cuando exista la API.
class DemoCatalogRepository implements CatalogRepository {
  const new(this._clock);

  /// "hace 20 min" se cuenta desde este reloj.
  final DateTime Function() _clock;

  static const _photos = 'asset:assets/products';

  static const categories = [
    CatalogCategory(
      slug: 'calculadoras',
      name: 'Calculadoras',
      photoUrl: '$_photos/casio.webp',
    ),
    CatalogCategory(
      slug: 'libros',
      name: 'Libros',
      photoUrl: '$_photos/calculo.webp',
    ),
    CatalogCategory(
      slug: 'tecnologia',
      name: 'Tecnología',
      photoUrl: '$_photos/laptop.webp',
    ),
    CatalogCategory(
      slug: 'laboratorio',
      name: 'Laboratorio',
      photoUrl: '$_photos/bata.webp',
    ),
    CatalogCategory(
      slug: 'dibujo',
      name: 'Dibujo',
      photoUrl: '$_photos/set-dibujo.webp',
    ),
  ];

  static (ProductSummary, int) _product(
    String id,
    String title,
    int pesos,
    int stock,
    String photo,
    String category, {
    required String condition,
    required String seller,
    required double rating,
    required int minutesAgo,
  }) => (
    ProductSummary(
      id: id,
      title: title,
      priceCents: pesos * 100,
      stock: stock,
      photoUrl: '$_photos/$photo.webp',
      category: category,
      condition: condition,
      sellerName: seller,
      sellerRating: rating,
    ),
    minutesAgo,
  );

  /// Los 14 productos de la vitrina (con sus minutos de publicados); los 6
  /// primeros son los del mosaico de "Todo". Los titulos que la maqueta
  /// recorta en `Inicio-visitante` van completos, como en `Inicio`.
  static final List<(ProductSummary, int)> _products = [
    _product(
      'casio-991es',
      'Calculadora Casio fx-991ES Plus',
      450,
      2,
      'casio',
      'calculadoras',
      condition: 'Usado',
      seller: 'Valeria C.',
      rating: 4.6,
      minutesAgo: 2880,
    ),
    _product(
      'set-dibujo',
      'Set de dibujo técnico',
      320,
      2,
      'set-dibujo',
      'dibujo',
      condition: 'Nuevo',
      seller: 'Paola N.',
      rating: 4.8,
      minutesAgo: 300,
    ),
    _product(
      'lenovo',
      'Laptop Lenovo IdeaPad 5, Ryzen 7, 16 GB de RAM',
      11800,
      1,
      'laptop',
      'tecnologia',
      condition: 'Usado',
      seller: 'Jorge S.',
      rating: 4.7,
      minutesAgo: 20,
    ),
    _product(
      'bata-s',
      'Bata de laboratorio',
      220,
      3,
      'bata',
      'laboratorio',
      condition: 'Nuevo',
      seller: 'Paola N.',
      rating: 4.8,
      minutesAgo: 120,
    ),
    _product(
      'audifonos',
      'Audífonos inalámbricos',
      650,
      0,
      'audifonos',
      'tecnologia',
      condition: 'Usado',
      seller: 'Mariana L.',
      rating: 4.8,
      minutesAgo: 1440,
    ),
    _product(
      'stewart',
      'Cálculo de una variable, Stewart 8a ed.',
      380,
      3,
      'calculo',
      'libros',
      condition: 'Usado',
      seller: 'Diego H.',
      rating: 4.9,
      minutesAgo: 60,
    ),
    _product(
      'casio-lax',
      'Calculadora Casio fx-991LA X',
      520,
      1,
      'casio-lax',
      'calculadoras',
      condition: 'Nuevo',
      seller: 'Luis M.',
      rating: 5,
      minutesAgo: 180,
    ),
    _product(
      'quimica',
      'Química orgánica, Wade',
      420,
      1,
      'quimica',
      'libros',
      condition: 'Usado',
      seller: 'Fernanda R.',
      rating: 4.7,
      minutesAgo: 17280,
    ),
    _product(
      'monitor',
      'Monitor de 24 pulgadas',
      1900,
      3,
      'monitor',
      'tecnologia',
      condition: 'Usado',
      seller: 'Jorge S.',
      rating: 4.7,
      minutesAgo: 30240,
    ),
    _product(
      'tableta',
      'Tableta gráfica Wacom One',
      1200,
      0,
      'tableta',
      'tecnologia',
      condition: 'Usado',
      seller: 'Valeria C.',
      rating: 4.6,
      minutesAgo: 36000,
    ),
    _product(
      'arduino',
      'Kit Arduino UNO con sensores',
      420,
      3,
      'arduino',
      'tecnologia',
      condition: 'Usado',
      seller: 'Jorge S.',
      rating: 4.7,
      minutesAgo: 5760,
    ),
    _product(
      'esteto',
      'Estetoscopio de doble campana',
      890,
      3,
      'estetoscopio',
      'laboratorio',
      condition: 'Usado',
      seller: 'Andrea G.',
      rating: 4.9,
      minutesAgo: 1500,
    ),
    _product(
      'matraces',
      'Kit de matraces y tubos',
      350,
      3,
      'matraces',
      'laboratorio',
      condition: 'Usado',
      seller: 'Andrea G.',
      rating: 4.9,
      minutesAgo: 23040,
    ),
    _product(
      'compas',
      'Compás de precisión',
      260,
      3,
      'compas',
      'dibujo',
      condition: 'Usado',
      seller: 'Valeria C.',
      rating: 4.6,
      minutesAgo: 28800,
    ),
  ];

  /// Vistas por periodo (los agotados no entran a Populares).
  static const Map<PopularPeriod, List<(String, int)>> _ranking = {
    PopularPeriod.today: [
      ('casio-991es', 128),
      ('lenovo', 96),
      ('bata-s', 74),
      ('set-dibujo', 61),
      ('stewart', 48),
    ],
    PopularPeriod.week: [
      ('set-dibujo', 912),
      ('casio-991es', 840),
      ('esteto', 655),
      ('arduino', 498),
      ('monitor', 431),
    ],
  };

  static final List<(WantedSummary, int)> _wanted = [
    (
      WantedSummary(
        id: 'w-bata',
        title: 'Bata de laboratorio talla M',
        budgetCents: 30000,
        neededBy: DateTime(2026, 10, 5),
        category: 'laboratorio',
        categoryName: 'Laboratorio',
      ),
      20,
    ),
    (
      WantedSummary(
        id: 'w-laptop',
        title: 'Laptop para programación, 16 GB',
        budgetCents: 1200000,
        neededBy: DateTime(2026, 10, 15),
        category: 'tecnologia',
        categoryName: 'Laptops',
      ),
      60,
    ),
    (
      WantedSummary(
        id: 'w-anatomia',
        title: 'Anatomía de Moore, 8a edición',
        budgetCents: 60000,
        neededBy: DateTime(2026, 10, 9),
        category: 'libros',
        categoryName: 'Libros',
      ),
      180,
    ),
  ];

  @override
  Future<HomeFeed> homeFeed({
    required PopularPeriod period,
    CatalogFilter filter = const CatalogFilter(),
  }) async {
    final now = _clock();
    ProductSummary timed((ProductSummary, int) entry, {int? views}) {
      final (p, minutes) = entry;
      return ProductSummary(
        id: p.id,
        title: p.title,
        priceCents: p.priceCents,
        stock: p.stock,
        photoUrl: p.photoUrl,
        views: views ?? p.views,
        category: p.category,
        condition: p.condition,
        sellerName: p.sellerName,
        sellerRating: p.sellerRating,
        publishedAt: now.subtract(Duration(minutes: minutes)),
      );
    }

    (ProductSummary, int) byId(String id) =>
        _products.firstWhere((entry) => entry.$1.id == id);
    final popular = [
      for (final (id, views) in _ranking[period]!)
        if (!byId(id).$1.soldOut) timed(byId(id), views: views),
    ];
    final category = filter.category;
    final recent = [
      for (final entry in _products)
        if ((category == null || entry.$1.category == category) &&
            (!filter.hideSoldOut || !entry.$1.soldOut))
          timed(entry),
    ];
    final wanted = [
      for (final (w, minutes) in _wanted)
        WantedSummary(
          id: w.id,
          title: w.title,
          budgetCents: w.budgetCents,
          neededBy: w.neededBy,
          category: w.category,
          categoryName: w.categoryName,
          createdAt: now.subtract(Duration(minutes: minutes)),
        ),
    ];
    return HomeFeed(
      popular: popular,
      recent: recent,
      wanted: wanted,
      categories: categories,
      recentTotal: 48,
    );
  }
}
