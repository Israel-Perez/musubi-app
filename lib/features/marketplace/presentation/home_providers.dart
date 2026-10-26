import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/features/marketplace/data/pending_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

/// Catalogo de la vitrina (en pruebas, un fake).
final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => PendingCatalogRepository(ref.watch(statusRepositoryProvider)),
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
