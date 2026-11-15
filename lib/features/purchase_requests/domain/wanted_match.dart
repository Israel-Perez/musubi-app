import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';

/// Una publicacion que coincide con mi solicitud (HU-18, `WantedMatchPage` de
/// musubi-api).
@immutable
class WantedMatch {
  const new({required this.product, required this.exact});

  final ProductSummary product;

  /// Cumple las reglas de HU-19 (`exact`); si no, es parecida (`similar`,
  /// "Modelo parecido", RF-24).
  final bool exact;
}
