import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/seller_support/domain/seller_support.dart';

/// La bata de la maqueta (`Mis-productos` → "Llevan tiempo sin venderse").
SlowListing sampleSlow({
  String id = 'bata',
  String title = 'Bata de laboratorio blanca, talla M',
  int priceCents = 25000,
  int days = 34,
  int views = 96,
  int messages = 0,
  int people = 3,
  int requests = 2,
}) => SlowListing(
  listing: OwnListing(
    product: ProductSummary(
      id: id,
      title: title,
      priceCents: priceCents,
      stock: 1,
      category: 'laboratorio',
      condition: 'Usado',
      publishedAt: DateTime.utc(2026, 10, 12, 18),
    ),
    status: ListingStatus.active,
    description: 'Bata de manga larga.',
  ),
  daysListed: days,
  views: views,
  messages: messages,
  people: people,
  requests: requests,
  tips: const [
    SalesTip(
      kind: SalesTipKind.price,
      title: 'Revisa el precio',
      body: r'Quienes buscan algo así ofrecen hasta $220 y tú pides $250.',
      applies: true,
    ),
    SalesTip(
      kind: SalesTipKind.description,
      title: 'Mejora la descripción',
      body:
          'Es muy corta. Cuenta el estado, la marca o la medida para que te '
          'escriban sin tantas dudas.',
      applies: true,
    ),
    SalesTip(
      kind: SalesTipKind.photos,
      title: 'Actualiza las fotos',
      body:
          'Una foto nueva, con luz natural y fondo limpio, la hace ver como '
          'recién publicada.',
    ),
  ],
);

/// Apoyo a vendedores en memoria (HU-36/37/38).
class FakeSellerSupportRepository implements SellerSupportRepository {
  new({
    this.slowItems = const [],
    Map<String, ProductDemand>? demands,
    this.anyDemand,
  }) : demands = demands ?? {};

  List<SlowListing> slowItems;
  final Map<String, ProductDemand> demands;

  /// La demanda de cualquier otra publicacion (una recien publicada).
  final ProductDemand? anyDemand;

  /// Falla la siguiente lectura de "Llevan tiempo sin venderse".
  ApiFailure? slowFailure;

  int slowCalls = 0;
  final List<String> demandCalls = [];

  /// Lo que propone la IA de prueba.
  ListingIdeas ideasAnswer = const ListingIdeas(
    title: 'Bata de laboratorio blanca, talla M',
    description:
        'Bata de manga larga en buen estado. La usé dos semestres en química '
        'y está limpia.',
  );

  /// Falla la siguiente propuesta (`seller_support.ideas_unavailable`).
  ApiFailure? ideasFailure;

  final List<String> ideasCalls = [];

  @override
  Future<SlowListings> slow() async {
    slowCalls++;
    if (slowFailure case final failure?) throw failure;
    return SlowListings(items: slowItems);
  }

  @override
  Future<ProductDemand> demand(String productId) async {
    demandCalls.add(productId);
    return demands[productId] ?? anyDemand ?? const ProductDemand();
  }

  @override
  Future<ListingIdeas> ideas(String productId) async {
    ideasCalls.add(productId);
    if (ideasFailure case final failure?) {
      ideasFailure = null;
      throw failure;
    }
    return ideasAnswer;
  }
}
