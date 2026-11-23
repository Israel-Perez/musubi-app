import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/marketplace/data/http_comparison_repository.dart';
import 'package:musubi_app/features/marketplace/domain/comparison.dart';

final comparisonRepositoryProvider = Provider<ComparisonRepository>(
  (ref) => HttpComparisonRepository(
    ref.watch(dioProvider),
    ref.watch(appConfigProvider).apiBaseUrl,
  ),
);

/// "Compara antes de comprar" de una publicacion (HU-51). Con sesion: sin ella
/// la pantalla no lo pide (RNF-05). Si falla, la seccion no aparece.
final FutureProviderFamily<List<ComparisonOption>, String> comparisonProvider =
    FutureProvider.autoDispose.family<List<ComparisonOption>, String>(
      (ref, id) => ref.watch(comparisonRepositoryProvider).compare(id),
      retry: (_, _) => null,
    );

/// Lo que estima el modelo de ML (HU-58); `null` sin datos o si falla (la
/// seccion sigue con la regla de la maqueta).
final FutureProviderFamily<PriceEstimate?, String> priceEstimateProvider =
    FutureProvider.autoDispose.family<PriceEstimate?, String>(
      (ref, id) => ref.watch(comparisonRepositoryProvider).estimate(id),
      retry: (_, _) => null,
    );

/// Si ya pedi "Avísame" de una agotada ("Te avisaremos", HU-51). El toque lo
/// maneja `Producto` y luego invalida este provider.
final FutureProviderFamily<bool, String> stockAlertProvider = FutureProvider
    .autoDispose
    .family<bool, String>(
      (ref, id) => ref.watch(comparisonRepositoryProvider).stockAlert(id),
      retry: (_, _) => null,
    );
