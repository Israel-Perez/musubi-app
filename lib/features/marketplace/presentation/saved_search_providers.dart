import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/marketplace/data/http_saved_search_repository.dart';
import 'package:musubi_app/features/marketplace/domain/saved_search.dart';

final savedSearchRepositoryProvider = Provider<SavedSearchRepository>(
  (ref) => HttpSavedSearchRepository(ref.watch(dioProvider)),
);

/// "Mis alertas" (HU-12), para la fila de `Ajustes` y su pantalla. Sin el
/// reintento automatico: la pantalla ofrece reintentar.
final FutureProvider<List<SavedSearch>> mySavedSearchesProvider =
    FutureProvider.autoDispose<List<SavedSearch>>(
      (ref) => ref.watch(savedSearchRepositoryProvider).mine(),
      retry: (_, _) => null,
    );
