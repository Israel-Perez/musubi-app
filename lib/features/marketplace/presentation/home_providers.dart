import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/data/demo_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/data/http_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Catalogo de la vitrina (en pruebas, un fake): `GET /api/v1/products`
/// (HU-48 fase 2). Con `DEMO_CATALOG` (solo en dev) muestra los productos
/// ficticios de la maqueta.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.demoCatalog
      ? DemoCatalogRepository(ref.watch(clockProvider))
      : HttpCatalogRepository(ref.watch(dioProvider), config.apiBaseUrl);
});

/// Categorias del campus para los chips de `Busqueda-filtros` (HU-10).
/// Sin el reintento automatico de Riverpod 3: la hoja ofrece reintentar.
final FutureProvider<List<CatalogCategory>> categoriesProvider =
    FutureProvider.autoDispose<List<CatalogCategory>>(
      (ref) => ref.watch(catalogRepositoryProvider).categories(),
      retry: (_, _) => null,
    );

/// Periodo elegido en "Populares" (Hoy por defecto).
final popularPeriodProvider =
    NotifierProvider<PopularPeriodNotifier, PopularPeriod>(
      PopularPeriodNotifier.new,
    );

class PopularPeriodNotifier extends Notifier<PopularPeriod> {
  @override
  PopularPeriod build() => PopularPeriod.today;

  // ignore: use_setters_to_change_properties, se lee como accion de la UI.
  void select(PopularPeriod period) => state = period;
}

/// Vitrina de Inicio. Para reintentar: `ref.invalidate(homeFeedProvider)`.
///
/// Sin el reintento automatico de Riverpod 3: si falla, se ve `Inicio-error`
/// de inmediato y la persona decide con "Reintentar" o jalando la pantalla.
final FutureProvider<HomeFeed> homeFeedProvider =
    FutureProvider.autoDispose<HomeFeed>(
      (ref) => ref
          .watch(catalogRepositoryProvider)
          .homeFeed(period: ref.watch(popularPeriodProvider)),
      retry: (_, _) => null,
    );
