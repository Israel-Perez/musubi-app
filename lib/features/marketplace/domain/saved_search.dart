import 'package:flutter/foundation.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';

/// "Avísame cuando aparezca" (HU-12, `SavedSearchResponse` de musubi-api).
@immutable
class SavedSearch {
  const new({
    required this.id,
    required this.query,
    required this.expiresAt,
    this.categories = const [],
    this.minCents,
    this.maxCents,
    this.condition,
  });

  final String id;

  /// Lo que se escribio.
  final String query;
  final List<String> categories;
  final int? minCents;
  final int? maxCents;

  /// `new`, `used` o `null`.
  final String? condition;

  /// Vence a los 30 dias (RN-34).
  final DateTime expiresAt;
}

/// "Avísame cuando aparezca" y "Mis alertas" (filas HU-12 de musubi-api).
abstract interface class SavedSearchRepository {
  /// Guarda la busqueda con sus filtros; `created` es `false` si ya la tenia
  /// (solo se renovo).
  Future<({SavedSearch search, bool created})> save({
    required String query,
    SearchFilter filter = const SearchFilter(),
  });

  /// Las vigentes, de la mas nueva a la mas vieja.
  Future<List<SavedSearch>> mine();

  Future<void> remove(String id);
}
