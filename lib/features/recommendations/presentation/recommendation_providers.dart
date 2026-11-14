import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/recommendations/data/http_recommendation_repository.dart';
import 'package:musubi_app/features/recommendations/domain/recommendation_models.dart';
import 'package:musubi_app/features/recommendations/domain/recommendation_repository.dart';

/// Recomendaciones con ML (HU-35). En pruebas, un fake; en modo demo, vacias.
final recommendationRepositoryProvider = Provider<RecommendationRepository>((
  ref,
) {
  final config = ref.watch(appConfigProvider);
  return config.demoCatalog
      ? const EmptyRecommendationRepository()
      : HttpRecommendationRepository(ref.watch(dioProvider), config.apiBaseUrl);
});

/// "Recomendado para ti" de `Inicio`. Es una seccion secundaria: si falla,
/// Inicio se muestra sin ella. Se recarga con
/// `ref.invalidate(forYouProvider)`.
final FutureProvider<RecommendationPage> forYouProvider =
    FutureProvider.autoDispose<RecommendationPage>(
      (ref) => ref.watch(recommendationRepositoryProvider).forYou(),
      retry: (_, _) => null,
    );

/// "Ver parecidos" de una publicacion (`Producto`).
final FutureProviderFamily<RecommendationPage, String> similarProductsProvider =
    FutureProvider.autoDispose.family<RecommendationPage, String>(
      (ref, productId) =>
          ref.watch(recommendationRepositoryProvider).similar(productId),
      retry: (_, _) => null,
    );
