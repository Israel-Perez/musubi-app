import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/listings/data/photo_picker.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/domain/listings_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Fake de [ListingsRepository] con el comportamiento del back (HU-06): las
/// 6 categorias de la maqueta, una llave por foto subida y la publicacion
/// tal como llega a la vitrina.
class FakeListingsRepository implements ListingsRepository {
  new({this.range, this.failUploads = 0});

  static const categoryList = [
    CatalogCategory(slug: 'calculadoras', name: 'Calculadoras'),
    CatalogCategory(slug: 'libros', name: 'Libros'),
    CatalogCategory(slug: 'laptops', name: 'Laptops'),
    CatalogCategory(slug: 'laboratorio', name: 'Laboratorio'),
    CatalogCategory(slug: 'dibujo', name: 'Dibujo'),
    CatalogCategory(slug: 'electronica', name: 'Electrónica'),
  ];

  /// Rango de precios de cualquier categoria (`null`: aun no hay datos).
  final PriceRange? range;

  /// Cuantas subidas fallan antes de que funcionen.
  int failUploads;

  /// Fotos que la moderacion de la API rechaza (02-07).
  final Set<String> rejectedPaths = {};

  final List<String> uploaded = [];
  final List<NewListing> published = [];
  List<OwnListing> own = const [];

  @override
  Future<List<CatalogCategory>> categories() async => categoryList;

  @override
  Future<UploadedPhoto> uploadPhoto(String filePath) async {
    if (rejectedPaths.contains(filePath)) {
      throw const ApiFailure(
        code: 'moderation.image_rejected',
        message: 'Esta foto no cumple las reglas de la comunidad. Usa otra.',
        status: 422,
      );
    }
    if (failUploads > 0) {
      failUploads--;
      throw const ApiFailure(
        code: ApiFailure.networkOffline,
        message: 'Sin conexión.',
      );
    }
    uploaded.add(filePath);
    final key = 'media/products/u1/${uploaded.length}.webp';
    return UploadedPhoto(key: key, url: 'https://api.musubi.example/$key');
  }

  @override
  Future<ProductSummary> publish(NewListing listing) async {
    published.add(listing);
    return ProductSummary(
      id: 'nuevo-${published.length}',
      title: listing.title.trim(),
      priceCents: listing.priceCents,
      stock: listing.quantity,
      photoUrl: 'https://api.musubi.example/${listing.photoKeys.first}',
      category: listing.category,
      condition: listing.condition.label,
      sellerName: 'Ana R.',
      publishedAt: DateTime.utc(2026, 10, 27, 12),
    );
  }

  @override
  Future<List<OwnListing>> mine() async => own;

  @override
  Future<PriceRange?> priceRange(String category) async => range;

  /// Lo que se mando al editar (HU-07), por id.
  final Map<String, ListingUpdate> updates = {};

  /// Ids eliminados.
  final List<String> deleted = [];

  /// Error que responde la siguiente escritura (editar, pausar, reactivar o
  /// eliminar), como la API (p. ej. `409 listings.product_has_orders`).
  ApiFailure? nextFailure;

  void _failIfAsked() {
    final failure = nextFailure;
    if (failure != null) {
      nextFailure = null;
      throw failure;
    }
  }

  OwnListing _find(String id) =>
      own.where((l) => l.product.id == id).firstOrNull ??
      (throw const ApiFailure(
        code: 'listings.product_not_found',
        message: 'Esta publicación ya no está disponible.',
        status: 404,
      ));

  void _replace(OwnListing listing) => own = [
    for (final l in own)
      if (l.product.id == listing.product.id) listing else l,
  ];

  /// Ids marcados como vendidos (HU-08).
  final List<String> soldIds = [];

  /// Tamano de pagina de [minePage] (la API usa 50).
  int pageSize = 50;

  static const Map<MyProductsTab, Set<ListingStatus>> _tabStatuses = {
    MyProductsTab.active: {ListingStatus.active, ListingStatus.hidden},
    MyProductsTab.sold: {ListingStatus.sold},
    MyProductsTab.soldOut: {ListingStatus.soldOut},
  };

  @override
  Future<MyListingsPage> minePage(MyProductsTab tab, {String? cursor}) async {
    final all = [
      for (final l in own)
        if (_tabStatuses[tab]!.contains(l.status)) l,
    ];
    final start = cursor == null ? 0 : int.parse(cursor);
    final items = all.skip(start).take(pageSize).toList();
    final next = start + items.length;
    int count(MyProductsTab t) =>
        own.where((l) => _tabStatuses[t]!.contains(l.status)).length;
    return MyListingsPage(
      items: items,
      nextCursor: next < all.length ? '$next' : null,
      total: all.length,
      counts: MyListingsCounts(
        active: count(MyProductsTab.active),
        sold: count(MyProductsTab.sold),
        soldOut: count(MyProductsTab.soldOut),
      ),
    );
  }

  @override
  Future<OwnListing> markSold(String id) async {
    _failIfAsked();
    final current = _find(id);
    soldIds.add(id);
    final sold = _withStatus(
      current,
      ListingStatus.sold,
      soldAt: current.soldAt ?? DateTime.utc(2026, 11, 10, 12),
    );
    _replace(sold);
    return sold;
  }

  @override
  Future<OwnListing> update(String id, ListingUpdate update) async {
    _failIfAsked();
    final current = _find(id);
    updates[id] = update;
    final product = current.product;
    final edited = OwnListing(
      product: ProductSummary(
        id: product.id,
        title: update.title.trim(),
        priceCents: update.priceCents,
        stock: product.stock,
        photoUrl: product.photoUrl,
        category: update.category,
        condition: update.condition.label,
        sellerName: product.sellerName,
        publishedAt: product.publishedAt,
      ),
      status: current.status,
      description: update.description.trim(),
      condition: update.condition,
      usedDetail: update.condition == ProductCondition.used
          ? update.usedDetail
          : null,
    );
    _replace(edited);
    return edited;
  }

  @override
  Future<OwnListing> pause(String id) async {
    _failIfAsked();
    final current = _find(id);
    final paused = _withStatus(current, ListingStatus.hidden);
    _replace(paused);
    return paused;
  }

  @override
  Future<OwnListing> resume(String id) async {
    _failIfAsked();
    final current = _find(id);
    final resumed = _withStatus(
      current,
      current.product.stock > 0 ? ListingStatus.active : ListingStatus.soldOut,
    );
    _replace(resumed);
    return resumed;
  }

  @override
  Future<void> delete(String id) async {
    _failIfAsked();
    _find(id);
    deleted.add(id);
    own = [
      for (final l in own)
        if (l.product.id != id) l,
    ];
  }

  static OwnListing _withStatus(
    OwnListing l,
    ListingStatus status, {
    DateTime? soldAt,
  }) => OwnListing(
    product: l.product,
    status: status,
    description: l.description,
    condition: l.condition,
    usedDetail: l.usedDetail,
    soldAt: soldAt ?? l.soldAt,
  );
}

/// Camara y galeria falsas: devuelven rutas inventadas (la foto no se lee).
class FakePhotoPicker implements PhotoPicker {
  int _taken = 0;
  final List<int> galleryRequests = [];

  /// `true`: la camara no esta disponible.
  bool cameraFails = false;

  @override
  Future<String?> takePhoto() async {
    if (cameraFails) throw const PhotoPickFailure('no_available_camera');
    return 'fotos/camara-${++_taken}.jpg';
  }

  @override
  Future<List<String>> pickFromGallery({required int max}) async {
    galleryRequests.add(max);
    return [for (var i = 1; i <= 3; i++) 'fotos/galeria-$i.jpg'];
  }
}
