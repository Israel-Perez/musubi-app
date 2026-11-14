import 'package:musubi_app/features/recommendations/domain/recommendation_models.dart';

/// Recomendaciones con ML (HU-35). Lanza `ApiFailure` con el mensaje en
/// espanol de la API.
abstract interface class RecommendationRepository {
  /// "Recomendado para ti" (con sesion). [limit] de 1 a 20 (10 si no se
  /// manda).
  Future<RecommendationPage> forYou({int? limit});

  /// "Ver parecidos" de una publicacion (con o sin sesion).
  Future<RecommendationPage> similar(String productId, {int? limit});
}

/// Sin API (modo demo): no recomienda nada y las secciones no se muestran.
class EmptyRecommendationRepository implements RecommendationRepository {
  const new();

  @override
  Future<RecommendationPage> forYou({int? limit}) async =>
      const RecommendationPage();

  @override
  Future<RecommendationPage> similar(String productId, {int? limit}) async =>
      const RecommendationPage(basis: RecommendationBasis.similar);
}
