import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/marketplace/domain/favorite_models.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_screen.dart';

import '../../helpers/fake_chat.dart' show jwtFor;
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

// HU-53: `Favoritos` con tabs, tres estados, vacio, error y quitar.
void main() {
  final now = DateTime.utc(2026, 11, 9, 12);

  SessionTokens session() => SessionTokens(
    accessToken: jwtFor('user-favorites'),
    accessExpiresAt: now.add(const Duration(minutes: 15)),
    refreshToken: 'refresh-favorites',
    profile: const SessionProfile(
      fullName: 'Ana Sofía Ramírez',
      email: 'ana.ramirez@uttt.edu.mx',
      campus: 'UTTT',
    ),
  );

  ProductSummary summary(
    String id,
    String title, {
    int stock = 1,
    String? seller,
    String? condition,
  }) => ProductSummary(
    id: id,
    title: title,
    priceCents: 45000,
    stock: stock,
    sellerName: seller,
    condition: condition,
    publishedAt: now.subtract(const Duration(days: 2)),
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

  Favorites sample() => Favorites(
    items: [
      item(
        'p1',
        product: summary(
          'p1',
          'Calculadora Casio fx-991ES',
          stock: 2,
          seller: 'Ana R.',
          condition: 'Nuevo',
        ),
      ),
      item(
        'p2',
        status: FavoriteStatus.soldOut,
        product: summary(
          'p2',
          'Bata de laboratorio',
          stock: 0,
          seller: 'Luis M.',
          condition: 'Usado',
        ),
      ),
      item('p3', status: FavoriteStatus.unavailable),
    ],
  );

  Future<void> open(
    WidgetTester tester,
    FakeFavoritesRepository repository, {
    bool settle = true,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.favorites,
      routes: [
        GoRoute(path: AppRoutes.home, builder: (_, _) => const Text('Inicio')),
        GoRoute(
          path: AppRoutes.favorites,
          builder: (_, _) => const FavoritesScreen(),
        ),
        GoRoute(
          path: '/producto/:id',
          builder: (_, state) => Text('Detalle ${state.pathParameters['id']}'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          favoritesRepositoryProvider.overrideWithValue(repository),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          initialSessionTokensProvider.overrideWithValue(session()),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session())),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('cargando: muestra el indicador', (tester) async {
    final pending = Completer<Favorites>();
    final repository = FakeFavoritesRepository()..pendingList = pending;

    await open(tester, repository, settle: false);

    expect(find.text('Cargando tus favoritos…'), findsOneWidget);

    pending.complete(const Favorites());
    await tester.pumpAndSettle();
  });

  testWidgets('error: mensaje y Reintentar', (tester) async {
    final repository = FakeFavoritesRepository(
      listFailure: const ApiFailure(
        code: ApiFailure.networkOffline,
        message: 'Sin conexión.',
      ),
    );
    await open(tester, repository);

    expect(find.text('Algo salió mal'), findsOneWidget);
    expect(find.text('Sin conexión.'), findsOneWidget);

    repository
      ..listFailure = null
      ..favorites = sample();
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Calculadora Casio fx-991ES'), findsOneWidget);
  });

  testWidgets('vacio: invita a guardar y a ver lo recién publicado', (
    tester,
  ) async {
    await open(tester, FakeFavoritesRepository());

    expect(find.text('Aún no guardas nada'), findsOneWidget);
    expect(
      find.text('Toca el corazón en cualquier producto para guardarlo aquí.'),
      findsOneWidget,
    );
    expect(find.text('Ver lo recién publicado'), findsOneWidget);

    await tester.tap(find.byKey(const Key('favorite-tab-soldOut')));
    await tester.pump();

    expect(find.text('Nada agotado'), findsOneWidget);
    expect(find.text('Ver lo recién publicado'), findsOneWidget);
  });

  testWidgets('lista los tres estados con los conteos y filtra por tab', (
    tester,
  ) async {
    await open(tester, FakeFavoritesRepository(favorites: sample()));

    expect(find.text('Todos (3)'), findsOneWidget);
    expect(find.text('Disponibles (1)'), findsOneWidget);
    expect(find.text('Agotados (2)'), findsOneWidget);
    expect(find.text('Calculadora Casio fx-991ES'), findsOneWidget);
    expect(find.text('Bata de laboratorio'), findsOneWidget);
    expect(find.text('Ya no está disponible'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);

    await tester.tap(find.byKey(const Key('favorite-tab-available')));
    await tester.pump();
    expect(find.text('Calculadora Casio fx-991ES'), findsOneWidget);
    expect(find.text('Bata de laboratorio'), findsNothing);

    await tester.tap(find.byKey(const Key('favorite-tab-soldOut')));
    await tester.pump();
    expect(find.text('Calculadora Casio fx-991ES'), findsNothing);
    expect(find.text('Bata de laboratorio'), findsOneWidget);
    expect(find.text('Ya no está disponible'), findsOneWidget);

    await tester.tap(find.text('Ya no está disponible'));
    await tester.pump();
    expect(find.text('Detalle p3'), findsNothing);

    await tester.tap(find.text('Bata de laboratorio'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle p2'), findsOneWidget);
  });

  testWidgets('una tarjeta disponible abre el detalle', (tester) async {
    await open(tester, FakeFavoritesRepository(favorites: sample()));

    await tester.tap(find.text('Calculadora Casio fx-991ES'));
    await tester.pumpAndSettle();

    expect(find.text('Detalle p1'), findsOneWidget);
  });

  testWidgets('el corazon quita el favorito y ofrece Deshacer', (tester) async {
    final repository = FakeFavoritesRepository(favorites: sample());
    await open(tester, repository);

    await tester.tap(find.byKey(const Key('favorite-heart-p1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.removed, ['p1']);
    expect(find.text('Calculadora Casio fx-991ES'), findsNothing);
    expect(find.text('Lo quitaste de Favoritos'), findsOneWidget);
    expect(find.text('Deshacer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('unavailable se quita sin Deshacer', (tester) async {
    final repository = FakeFavoritesRepository(favorites: sample());
    await open(tester, repository);

    await tester.tap(find.byKey(const Key('favorite-heart-p3')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.removed, ['p3']);
    expect(find.text('Ya no está disponible'), findsNothing);
    expect(find.text('Lo quitaste de Favoritos'), findsOneWidget);
    expect(find.text('Deshacer'), findsNothing);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('accesibilidad y 360x640 sin overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 640 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await open(tester, FakeFavoritesRepository(favorites: sample()));

    expect(tester.takeException(), isNull);
    expect(tester, meetsGuideline(textContrastGuideline));
    expect(
      tester,
      meetsGuideline(
        const MinimumTapTargetGuideline(
          size: Size(44, 44),
          link: 'RNF-27: área táctil mínima de 44 dp',
        ),
      ),
    );
  });

  testWidgets('tablet sin overflow', (tester) async {
    tester.view
      ..physicalSize = const Size(800 * 3, 1280 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await open(tester, FakeFavoritesRepository(favorites: sample()));

    expect(tester.takeException(), isNull);
  });
}
