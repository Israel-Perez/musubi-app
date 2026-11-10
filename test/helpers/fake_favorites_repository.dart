import 'dart:async';

import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';
import 'package:musubi_app/features/marketplace/domain/favorites_repository.dart';

/// Repositorio de favoritos en memoria para las pruebas: responde con
/// [favorites], registra las acciones y permite simular errores o una
/// respuesta pendiente.
class FakeFavoritesRepository implements FavoritesRepository {
  new({
    this.favorites = const Favorites(),
    this.listFailure,
    this.addFailure,
    this.removeFailure,
  });

  Favorites favorites;
  ApiFailure? listFailure;
  ApiFailure? addFailure;
  ApiFailure? removeFailure;

  /// Si se asigna, `list()` espera a que se complete.
  Completer<Favorites>? pendingList;

  /// Si se asigna, `add()` espera a que se complete.
  Completer<void>? pendingAdd;

  int listCalls = 0;
  final List<String> added = [];
  final List<String> removed = [];

  @override
  Future<Favorites> list() {
    listCalls++;
    if (listFailure case final failure?) return Future.error(failure);
    if (pendingList case final pending?) return pending.future;
    return Future.value(favorites);
  }

  @override
  Future<void> add(String productId) async {
    added.add(productId);
    if (addFailure case final failure?) throw failure;
    if (pendingAdd case final pending?) await pending.future;
  }

  @override
  Future<void> remove(String productId) async {
    removed.add(productId);
    if (removeFailure case final failure?) throw failure;
  }
}
