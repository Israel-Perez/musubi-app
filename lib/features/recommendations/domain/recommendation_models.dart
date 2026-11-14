import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// De donde salen las recomendaciones (`basis` de la API, HU-35).
enum RecommendationBasis {
  /// Del modelo de ML con lo que la persona vio, guardo, escribio y compro.
  personal,

  /// Sin historial: lo mas activo del campus y lo mas nuevo (RN-46).
  general,

  /// "Ver parecidos".
  similar;

  static RecommendationBasis parse(String? value) => switch (value) {
    'personal' => personal,
    'similar' => similar,
    _ => general,
  };
}

/// Una pagina de recomendaciones (`RecommendationPage` de la API).
@immutable
class RecommendationPage {
  const new({this.items = const [], this.basis = RecommendationBasis.general});

  final List<ProductSummary> items;
  final RecommendationBasis basis;
}
