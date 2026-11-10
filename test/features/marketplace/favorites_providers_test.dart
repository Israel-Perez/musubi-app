import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';

import '../../helpers/fake_chat.dart' show jwtFor;
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/in_memory_token_store.dart';

// HU-53: el estado global de favoritos se arma con GET /favorites, vive por
// userId y se limpia al cerrar sesion (RNF-07).
void main() {
  final now = DateTime.utc(2026, 11, 9, 12);

  ProductSummary product(String id, {int stock = 1}) => ProductSummary(
    id: id,
    title: 'Producto $id',
    priceCents: 100,
    stock: stock,
  );

  FavoriteItem item(
    String id, {
    FavoriteStatus status = FavoriteStatus.available,
    ProductSummary? product,
  }) => FavoriteItem(
    productId: id,
    savedAt: now,
    status: status,
    product: product,
  );

  SessionTokens tokens(String sub) => SessionTokens(
    accessToken: jwtFor(sub),
    accessExpiresAt: now.add(const Duration(minutes: 15)),
    refreshToken: 'refresh-$sub',
    profile: const SessionProfile(
      fullName: 'Ana Sofía Ramírez',
      email: 'ana.ramirez@uttt.edu.mx',
      campus: 'UTTT',
    ),
  );

  ProviderContainer containerFor(FakeFavoritesRepository repository) =>
      ProviderContainer.test(
        overrides: [
          favoritesRepositoryProvider.overrideWithValue(repository),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
          initialSessionTokensProvider.overrideWithValue(null),
          clockProvider.overrideWithValue(() => now),
        ],
      )..listen(favoritesProvider, (_, _) {});

  Future<Favorites> signIn(ProviderContainer container, String sub) async {
    await container
        .read(sessionControllerProvider.notifier)
        .signIn(tokens(sub));
    return await container.read(favoritesProvider.future);
  }

  Future<Favorites> signOut(ProviderContainer container) async {
    await container.read(sessionControllerProvider.notifier).signOut();
    return await container.read(favoritesProvider.future);
  }

  test('sin sesion queda vacio y no llama a la API', () async {
    final repository = FakeFavoritesRepository();
    final container = containerFor(repository);

    final favorites = await container.read(favoritesProvider.future);

    expect(favorites.items, isEmpty);
    expect(repository.listCalls, 0);
  });

  test('con sesion carga la lista del usuario', () async {
    final repository = FakeFavoritesRepository(
      favorites: Favorites(items: [item('p1', product: product('p1'))]),
    );
    final container = containerFor(repository);

    final favorites = await signIn(container, 'user-1');

    expect(favorites.ids, {'p1'});
    expect(repository.listCalls, 1);
  });

  test('al cambiar de usuario recarga y no mezcla los favoritos', () async {
    final repository = FakeFavoritesRepository(
      favorites: Favorites(items: [item('p1', product: product('p1'))]),
    );
    final container = containerFor(repository);

    await signIn(container, 'user-1');
    repository.favorites = Favorites(
      items: [item('p2', product: product('p2'))],
    );
    final second = await signIn(container, 'user-2');

    expect(second.ids, {'p2'});
    expect(repository.listCalls, 2);
  });

  test('al cerrar sesion se limpia sin volver a pedir la lista', () async {
    final repository = FakeFavoritesRepository(
      favorites: Favorites(items: [item('p1', product: product('p1'))]),
    );
    final container = containerFor(repository);

    await signIn(container, 'user-1');
    final favorites = await signOut(container);

    expect(favorites.items, isEmpty);
    expect(repository.listCalls, 1);
  });

  test('toggle agrega con la hora del reloj y quita', () async {
    final repository = FakeFavoritesRepository();
    final container = containerFor(repository);
    await signIn(container, 'user-1');
    final controller = container.read(favoritesProvider.notifier);

    expect(await controller.toggle(product('p1')), isTrue);
    final saved = container.read(favoritesProvider).requireValue;
    expect(saved.items.single.productId, 'p1');
    expect(saved.items.single.savedAt, now);
    expect(saved.items.single.status, FavoriteStatus.available);
    expect(repository.added, ['p1']);

    expect(await controller.toggle(product('p1')), isFalse);
    expect(container.read(favoritesProvider).requireValue.items, isEmpty);
    expect(repository.removed, ['p1']);
  });

  test('un producto agotado se guarda como soldOut', () async {
    final repository = FakeFavoritesRepository();
    final container = containerFor(repository);
    await signIn(container, 'user-1');

    await container
        .read(favoritesProvider.notifier)
        .toggle(product('p1', stock: 0));

    expect(
      container.read(favoritesProvider).requireValue.items.single.status,
      FavoriteStatus.soldOut,
    );
  });

  test('un fallo conserva el estado anterior', () async {
    final repository = FakeFavoritesRepository(
      favorites: Favorites(items: [item('p1', product: product('p1'))]),
      removeFailure: const ApiFailure(
        code: ApiFailure.networkOffline,
        message: 'Sin conexión.',
      ),
    );
    final container = containerFor(repository);
    await signIn(container, 'user-1');

    await expectLater(
      container.read(favoritesProvider.notifier).toggle(product('p1')),
      throwsA(isA<ApiFailure>()),
    );

    expect(container.read(favoritesProvider).requireValue.ids, {'p1'});
  });

  test('dos toques seguidos hacen una sola peticion', () async {
    final repository = FakeFavoritesRepository();
    final pending = Completer<void>();
    repository.pendingAdd = pending;
    final container = containerFor(repository);
    await signIn(container, 'user-1');
    final controller = container.read(favoritesProvider.notifier);

    final first = controller.toggle(product('p1'));
    final second = await controller.toggle(product('p1'));

    expect(second, isNull);
    expect(repository.added, ['p1']);

    pending.complete();
    await first;
    expect(container.read(favoritesProvider).requireValue.ids, {'p1'});
  });

  test('una sesion nueva no hereda una peticion en vuelo', () async {
    final repository = FakeFavoritesRepository();
    final pending = Completer<void>();
    repository.pendingAdd = pending;
    final container = containerFor(repository);
    await signIn(container, 'user-1');

    final first = container
        .read(favoritesProvider.notifier)
        .toggle(product('p1'));
    await signIn(container, 'user-2');
    pending.complete();
    await first;

    expect(container.read(favoritesProvider).requireValue.ids, isEmpty);
  });

  test('un error de la lista deja AsyncError y se puede reintentar', () async {
    final repository = FakeFavoritesRepository(
      listFailure: const ApiFailure(
        code: ApiFailure.networkOffline,
        message: 'Sin conexión.',
      ),
    );
    final container = containerFor(repository);

    await container
        .read(sessionControllerProvider.notifier)
        .signIn(tokens('user-1'));
    await expectLater(
      container.read(favoritesProvider.future),
      throwsA(isA<ApiFailure>()),
    );
    expect(container.read(favoritesProvider), isA<AsyncError<Favorites>>());

    repository
      ..listFailure = null
      ..favorites = Favorites(items: [item('p1', product: product('p1'))]);
    container.invalidate(favoritesProvider);

    expect((await container.read(favoritesProvider.future)).ids, {'p1'});
  });

  test('la pestana elegida se conserva', () {
    final container = containerFor(FakeFavoritesRepository());

    expect(container.read(favoriteTabProvider), FavoriteTab.all);
    container.read(favoriteTabProvider.notifier).select(FavoriteTab.soldOut);

    expect(container.read(favoriteTabProvider), FavoriteTab.soldOut);
  });
}
