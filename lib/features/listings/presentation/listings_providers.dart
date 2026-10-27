import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/listings/data/http_listings_repository.dart';
import 'package:musubi_app/features/listings/data/photo_picker.dart';
import 'package:musubi_app/features/listings/domain/listing_models.dart';
import 'package:musubi_app/features/listings/domain/listings_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Publicar productos (HU-06), con sesion. En pruebas, un fake.
final listingsRepositoryProvider = Provider<ListingsRepository>(
  (ref) => HttpListingsRepository(
    ref.watch(dioProvider),
    ref.watch(appConfigProvider).apiBaseUrl,
  ),
);

/// Camara y galeria. En pruebas, un fake.
final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => ImagePickerPhotoPicker(),
);

/// Categorias para `Vender-3`.
final FutureProvider<List<CatalogCategory>> sellCategoriesProvider =
    FutureProvider.autoDispose<List<CatalogCategory>>(
      (ref) => ref.watch(listingsRepositoryProvider).categories(),
      retry: (_, _) => null,
    );

/// Rango de precios de la categoria; `null` si aun no hay suficientes.
final FutureProviderFamily<PriceRange?, String> priceRangeProvider =
    FutureProvider.autoDispose.family<PriceRange?, String>(
      (ref, category) =>
          ref.watch(listingsRepositoryProvider).priceRange(category),
      retry: (_, _) => null,
    );

/// "Mis productos".
final FutureProvider<List<OwnListing>> myListingsProvider =
    FutureProvider.autoDispose<List<OwnListing>>(
      (ref) => ref.watch(listingsRepositoryProvider).mine(),
      retry: (_, _) => null,
    );
