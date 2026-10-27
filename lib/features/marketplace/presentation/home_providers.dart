import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
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

/// Filtro aplicado a "Recién publicados" (Todo por defecto).
final catalogFilterProvider =
    NotifierProvider<CatalogFilterNotifier, CatalogFilter>(
      CatalogFilterNotifier.new,
    );

class CatalogFilterNotifier extends Notifier<CatalogFilter> {
  @override
  CatalogFilter build() => const CatalogFilter();

  // ignore: use_setters_to_change_properties, se lee como accion de la UI.
  void apply(CatalogFilter filter) => state = filter;
}

/// Vitrina de Inicio. Para reintentar: `ref.invalidate(homeFeedProvider)`.
///
/// Sin el reintento automatico de Riverpod 3: si falla, se ve `Inicio-error`
/// de inmediato y la persona decide con "Reintentar" o jalando la pantalla.
final FutureProvider<HomeFeed> homeFeedProvider =
    FutureProvider.autoDispose<HomeFeed>(
      (ref) => ref
          .watch(catalogRepositoryProvider)
          .homeFeed(
            period: ref.watch(popularPeriodProvider),
            filter: ref.watch(catalogFilterProvider),
          ),
      retry: (_, _) => null,
    );

/// Cuantos productos veria la persona con el filtro que esta eligiendo
/// ("Ver 6 productos").
final FutureProviderFamily<int, CatalogFilter> filterPreviewProvider =
    FutureProvider.autoDispose.family<int, CatalogFilter>(
      (ref, filter) async =>
          (await ref
                  .watch(catalogRepositoryProvider)
                  .homeFeed(
                    period: ref.watch(popularPeriodProvider),
                    filter: filter,
                  ))
              .recent
              .length,
      retry: (_, _) => null,
    );
