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

  final List<String> uploaded = [];
  final List<NewListing> published = [];
  List<OwnListing> own = const [];

  @override
  Future<List<CatalogCategory>> categories() async => categoryList;

  @override
  Future<UploadedPhoto> uploadPhoto(String filePath) async {
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
