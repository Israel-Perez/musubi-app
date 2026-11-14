import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/recommendations/domain/recommendation_models.dart';
import 'package:musubi_app/features/recommendations/domain/recommendation_repository.dart';

/// Recomendaciones en memoria (HU-35): lo que se le pone en [forYouItems] y
/// en [similarItems] por publicacion.
class FakeRecommendationRepository implements RecommendationRepository {
  new({
    this.forYouItems = const [],
    this.basis = RecommendationBasis.personal,
    Map<String, List<ProductSummary>>? similarItems,
  }) : similarItems = similarItems ?? {};

  List<ProductSummary> forYouItems;
  RecommendationBasis basis;
  final Map<String, List<ProductSummary>> similarItems;

  /// Cuantas veces se pidio "Recomendado para ti".
  int forYouCalls = 0;

  /// Lo que pidio "Ver parecidos".
  final List<String> similarCalls = [];

  /// Falla la siguiente lectura.
  ApiFailure? failure;

  @override
  Future<RecommendationPage> forYou({int? limit}) async {
    forYouCalls++;
    _throwIfFailing();
    return RecommendationPage(items: forYouItems, basis: basis);
  }

  @override
  Future<RecommendationPage> similar(String productId, {int? limit}) async {
    similarCalls.add(productId);
    _throwIfFailing();
    return RecommendationPage(
      items: similarItems[productId] ?? const [],
      basis: RecommendationBasis.similar,
    );
  }

  void _throwIfFailing() {
    final pending = failure;
    if (pending != null) {
      failure = null;
      throw pending;
    }
  }
}
