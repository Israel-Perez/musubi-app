import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/network/offline_cache.dart';
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

/// "Precio sugerido" del modelo de ML (HU-58); `null` sin datos suficientes o
/// si la API no responde (la tarjeta cae al rango de la categoria).
final FutureProviderFamily<PriceSuggestion?, PriceQuery>
priceSuggestionProvider = FutureProvider.autoDispose
    .family<PriceSuggestion?, PriceQuery>(
      (ref, query) => ref.watch(listingsRepositoryProvider).suggestPrice(query),
      retry: (_, _) => null,
    );

/// Una pestana de `Mis-productos` con los conteos de las tres (HU-08).
final FutureProviderFamily<MyListingsPage, MyProductsTab>
myListingsTabProvider = FutureProvider.autoDispose
    .family<MyListingsPage, MyProductsTab>((ref, tab) {
      // HU-63: abre con lo guardado y se actualiza al llegar lo nuevo.
      refreshWithOfflineCopies(ref, const {ApiPaths.myProducts});
      return ref.watch(listingsRepositoryProvider).minePage(tab);
    }, retry: (_, _) => null);

/// Todas mis publicaciones (Perfil y "Yo tengo este producto").
final FutureProvider<List<OwnListing>> myListingsProvider =
    FutureProvider.autoDispose<List<OwnListing>>(
      (ref) => ref.watch(listingsRepositoryProvider).mine(),
      retry: (_, _) => null,
    );
