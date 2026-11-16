import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/comparison.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Las cinco opciones de la Casio de Valeria en la maqueta (`Producto`): la
/// API las da en este orden (el mismo modelo primero y luego el precio mas
/// cercano a $450).
List<ComparisonOption> casioOptions() => [
  _option(
    'c1',
    'Calculadora Casio fx-991ES Plus',
    48000,
    'Fernanda O.',
    4.8,
    7,
    4,
    same: true,
  ),
  _option(
    'c2',
    'Calculadora Casio fx-991ES Plus',
    40000,
    'Diego H.',
    4.9,
    32,
    21,
    same: true,
  ),
  _option(
    'c3',
    'Calculadora Casio fx-991LA X',
    52000,
    'Luis M.',
    5,
    11,
    9,
    condition: 'Nuevo',
    photo: 'asset:assets/products/casio-lax.webp',
  ),
  _option(
    'c4',
    'Calculadora Casio fx-570ES Plus',
    38000,
    'Paola N.',
    4.8,
    24,
    19,
  ),
  _option(
    'c5',
    'Calculadora Casio fx-991LA CW',
    65000,
    'Jorge S.',
    4.7,
    29,
    26,
    condition: 'Nuevo',
    photo: 'asset:assets/products/casio-lax.webp',
  ),
];

ComparisonOption _option(
  String id,
  String title,
  int priceCents,
  String seller,
  double? rating,
  int count,
  int? sales, {
  bool same = false,
  String condition = 'Usado',
  String photo = 'asset:assets/products/casio.webp',
}) => ComparisonOption(
  product: ProductSummary(
    id: id,
    title: title,
    priceCents: priceCents,
    stock: 1,
    condition: condition,
    category: 'calculadoras',
    sellerName: seller,
    photoUrl: photo,
  ),
  seller: ComparisonSeller(
    id: '6716a00000000000000000a$id',
    name: seller,
    ratingAvg: rating,
    ratingCount: count,
    sales: sales,
  ),
  sameModel: same,
);

/// Comparar y "Avísame" en memoria (HU-51).
class FakeComparisonRepository implements ComparisonRepository {
  new({Map<String, List<ComparisonOption>>? options, Set<String>? watching})
    : options = options ?? {},
      watching = watching ?? {};

  /// Opciones por publicacion.
  final Map<String, List<ComparisonOption>> options;

  /// Publicaciones con "Avísame".
  final Set<String> watching;

  /// Lo que se pidio, en orden ("compare:p1", "watch:p1"...).
  final List<String> calls = [];

  /// Falla la siguiente llamada.
  ApiFailure? failure;

  void _throwIfFailing() {
    final failure = this.failure;
    if (failure == null) return;
    this.failure = null;
    throw failure;
  }

  @override
  Future<List<ComparisonOption>> compare(String productId) async {
    calls.add('compare:$productId');
    _throwIfFailing();
    return options[productId] ?? const [];
  }

  @override
  Future<bool> stockAlert(String productId) async {
    calls.add('status:$productId');
    _throwIfFailing();
    return watching.contains(productId);
  }

  @override
  Future<void> watch(String productId) async {
    calls.add('watch:$productId');
    _throwIfFailing();
    watching.add(productId);
  }

  @override
  Future<void> unwatch(String productId) async {
    calls.add('unwatch:$productId');
    _throwIfFailing();
    watching.remove(productId);
  }
}
