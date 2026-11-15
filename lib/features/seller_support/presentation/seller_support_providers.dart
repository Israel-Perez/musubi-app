import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/seller_support/data/http_seller_support_repository.dart';
import 'package:musubi_app/features/seller_support/domain/seller_support.dart';

/// Apoyo a vendedores (M-12). En pruebas, un fake; en modo demo, vacio.
final sellerSupportRepositoryProvider = Provider<SellerSupportRepository>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  return config.demoCatalog
      ? const EmptySellerSupportRepository()
      : HttpSellerSupportRepository(ref.watch(dioProvider), config.apiBaseUrl);
});

/// "Llevan tiempo sin venderse" de `Mis-productos` (HU-36). Es una seccion
/// secundaria: si falla, la pantalla se muestra sin ella. Se recarga con
/// `ref.invalidate(slowListingsProvider)`.
final FutureProvider<SlowListings> slowListingsProvider =
    FutureProvider.autoDispose<SlowListings>(
      (ref) => ref.watch(sellerSupportRepositoryProvider).slow(),
      retry: (_, _) => null,
    );

/// "Quienes la buscan" de una publicacion mia (HU-38).
final FutureProviderFamily<ProductDemand, String> productDemandProvider =
    FutureProvider.autoDispose.family<ProductDemand, String>(
      (ref, productId) =>
          ref.watch(sellerSupportRepositoryProvider).demand(productId),
      retry: (_, _) => null,
    );
