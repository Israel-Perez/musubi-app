import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/saved_search.dart';
import 'package:musubi_app/features/marketplace/domain/search_filter.dart';

/// HU-12: "Avísame cuando aparezca" y "Mis alertas" en memoria.
class FakeSavedSearchRepository implements SavedSearchRepository {
  new({List<SavedSearch>? stored}) : stored = stored ?? [];

  final List<SavedSearch> stored;
  final saves = <(String, SearchFilter)>[];
  final removed = <String>[];
  ApiFailure? saveFailure;
  ApiFailure? loadFailure;

  @override
  Future<({SavedSearch search, bool created})> save({
    required String query,
    SearchFilter filter = const SearchFilter(),
  }) async {
    saves.add((query, filter));
    if (saveFailure != null) throw saveFailure!;
    final existing = stored.where((s) => s.query == query).firstOrNull;
    if (existing != null) return (search: existing, created: false);
    final search = SavedSearch(
      id: 's${stored.length + 1}',
      query: query,
      categories: filter.categories,
      minCents: filter.minCents,
      maxCents: filter.maxCents,
      condition: filter.condition.apiValue,
      expiresAt: DateTime.utc(2026, 12, 14, 18),
    );
    stored.insert(0, search);
    return (search: search, created: true);
  }

  @override
  Future<List<SavedSearch>> mine() async {
    if (loadFailure != null) throw loadFailure!;
    return [...stored];
  }

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    stored.removeWhere((s) => s.id == id);
  }
}
