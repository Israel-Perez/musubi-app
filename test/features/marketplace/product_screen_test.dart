import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/marketplace/data/http_catalog_repository.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 6, 21);

ProductDetail _detail({
  String status = 'active',
  int stock = 1,
  String? sellerId = '6716a0000000000000000001',
}) => ProductDetail(
  id: 'p1',
  title: 'Calculadora científica Casio fx-991ES Plus',
  description: 'La usé un semestre para Cálculo y Física.',
  categoryName: 'Calculadoras',
  priceCents: 45000,
  condition: 'used',
  conditionDetail: 'likeNew',
  stock: stock,
  status: status,
  photoUrls: const [],
  publishedAt: _now.subtract(const Duration(days: 2)),
  sellerId: sellerId,
  sellerName: sellerId == null ? null : 'Valeria C.',
);

Future<FakeCatalogRepository> _open(
  WidgetTester tester, {
  required ProductDetail? detail,
  SessionTokens? session,
  FakeFavoritesRepository? favorites,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final catalog = FakeCatalogRepository();
  if (detail != null) catalog.details['p1'] = detail;
  final profiles = FakeProfileRepository();
  profiles.publicProfiles['6716a0000000000000000001'] =
      FakeProfileRepository.publicSample;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        brandSplashEnabledProvider.overrideWithValue(false),
        catalogRepositoryProvider.overrideWithValue(catalog),
        favoritesRepositoryProvider.overrideWithValue(
          favorites ?? FakeFavoritesRepository(),
        ),
        profileRepositoryProvider.overrideWithValue(profiles),
        sessionApiProvider.overrideWithValue(FakeSessionApi()),
        clockProvider.overrideWithValue(() => _now),
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
        initialSessionTokensProvider.overrideWithValue(session),
        chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
        chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
      ],
      child: const MusubiApp(),
    ),
  );
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MusubiApp)),
  );
  container.read(routerProvider).go(AppRoutes.product('p1'));
  await tester.pumpAndSettle();
  return catalog;
}

// HU-11: la maqueta `Producto` (con sesion) y `Producto-visitante`.
void main() {
  testWidgets('con sesion: todo el detalle y la tarjeta de quien vende', (
    tester,
  ) async {
    await _open(tester, detail: _detail(), session: chatTokens(_now));

    expect(find.text(r'$450'), findsOneWidget);
    expect(find.text('Usado · Como nuevo'), findsOneWidget);
    expect(
      find.text('Calculadora científica Casio fx-991ES Plus'),
      findsOneWidget,
    );
    expect(find.text('Calculadoras · Publicado hace 2 días'), findsOneWidget);
    expect(find.text('Último'), findsOneWidget);
    expect(find.text('Campus'), findsOneWidget);
    expect(
      find.text('La usé un semestre para Cálculo y Física.'),
      findsOneWidget,
    );
    expect(find.text('Valeria Cruz'), findsOneWidget);
    expect(
      find.textContaining('15 ventas · Arquitectura', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Comprar'), findsOneWidget);
    expect(find.text('Apartar'), findsOneWidget);
  });

  testWidgets('la tarjeta de quien vende abre su perfil (HU-05)', (
    tester,
  ) async {
    final catalog = await _open(
      tester,
      detail: _detail(),
      session: chatTokens(_now),
    );
    catalog.sellerListingsResponse = const ProductPage(total: 3);

    final card = find.bySemanticsLabel('Ver perfil de Valeria Cruz');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('UTTT · Arquitectura · 8º cuatrimestre'), findsOneWidget);
    expect(find.text('Publicaciones (3)'), findsOneWidget);
  });

  testWidgets('visitante: la tarjeta del vendedor pide la cuenta', (
    tester,
  ) async {
    await _open(tester, detail: _detail(sellerId: null));

    final card = find.bySemanticsLabel(
      'Crea tu cuenta para ver quién lo vende',
    );
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Crea tu perfil'), findsOneWidget);
  });

  testWidgets('mi publicación: la tarjeta lleva a mi Perfil (HU-05)', (
    tester,
  ) async {
    await _open(
      tester,
      detail: _detail(sellerId: myId),
      session: chatTokens(_now),
    );

    final card = find.bySemanticsLabel('Ver perfil de Valeria C.');
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(find.text('Mis publicaciones'), findsOneWidget);
  });

  testWidgets('el corazon guarda y quita el producto', (tester) async {
    final favorites = FakeFavoritesRepository();
    await _open(
      tester,
      detail: _detail(),
      session: chatTokens(_now),
      favorites: favorites,
    );

    await tester.tap(find.bySemanticsLabel('Guardar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(favorites.added, ['p1']);
    expect(find.bySemanticsLabel('Quitar de favoritos'), findsOneWidget);
    expect(find.textContaining('Guardaste'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.tap(find.bySemanticsLabel('Quitar de favoritos'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(favorites.removed, ['p1']);
    expect(find.text('Lo quitaste de Favoritos'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('si guardar falla, avisa y no se marca', (tester) async {
    final favorites = FakeFavoritesRepository(
      addFailure: const ApiFailure(
        code: ApiFailure.networkOffline,
        message: 'Sin conexión.',
      ),
    );
    await _open(
      tester,
      detail: _detail(),
      session: chatTokens(_now),
      favorites: favorites,
    );

    await tester.tap(find.bySemanticsLabel('Guardar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(favorites.added, ['p1']);
    expect(find.text('Sin conexión.'), findsOneWidget);
    expect(find.bySemanticsLabel('Guardar'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('visitante: sin quien vende, y "Mensaje" pide la cuenta', (
    tester,
  ) async {
    await _open(tester, detail: _detail(sellerId: null));

    expect(find.text('Estudiante verificado'), findsOneWidget);
    expect(find.text('Crea tu cuenta para ver quién lo vende'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Enviar mensaje'));
    await tester.pumpAndSettle();

    expect(find.text('Crea tu cuenta para chatear'), findsOneWidget);
  });

  testWidgets('visitante: el corazon pide la cuenta', (tester) async {
    final favorites = FakeFavoritesRepository();
    await _open(tester, detail: _detail(sellerId: null), favorites: favorites);

    await tester.tap(find.bySemanticsLabel('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Guarda lo que te gusta'), findsOneWidget);
    expect(favorites.listCalls, 0);
    expect(favorites.added, isEmpty);
  });

  testWidgets('agotado: precio tachado, aviso y "Ver parecidos"', (
    tester,
  ) async {
    await _open(
      tester,
      detail: _detail(status: 'soldOut', stock: 0),
      session: chatTokens(_now),
    );

    expect(find.text('Ya no está disponible'), findsOneWidget);
    expect(find.text('Agotado'), findsOneWidget);
    expect(find.text('Avísame'), findsOneWidget);
    expect(find.text('Ver parecidos'), findsOneWidget);
    expect(find.text('Comprar'), findsNothing);
  });

  testWidgets('mi propia publicacion lleva a "Mis productos", no al chat', (
    tester,
  ) async {
    await _open(
      tester,
      detail: _detail(sellerId: myId),
      session: chatTokens(_now),
    );

    expect(find.text('Ver mis productos'), findsOneWidget);
    expect(find.bySemanticsLabel('Enviar mensaje'), findsNothing);
  });

  testWidgets('una publicacion que ya no existe lo explica', (tester) async {
    await _open(tester, detail: null);

    expect(
      find.text('Esta publicación ya no está disponible.'),
      findsOneWidget,
    );
  });

  test('el repositorio lee GET /products/{id} con la foto completa', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({
        'id': 'p1',
        'title': 'Calculadora',
        'description': 'Como nueva.',
        'category': {'slug': 'calculadoras', 'name': 'Calculadoras'},
        'priceCents': 45000,
        'condition': 'used',
        'conditionDetail': 'good',
        'stock': 2,
        'status': 'active',
        'photos': ['/media/products/u1/a.webp', '/media/products/u1/b.webp'],
        'seller': null,
        'publishedAt': '2026-11-04T21:00:00Z',
      }),
    );
    final repository = HttpCatalogRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );

    final detail = await repository.product('p1');

    expect(adapter.requests.single.path, ApiPaths.product('p1'));
    expect(detail.photoUrls, hasLength(2));
    expect(
      detail.photoUrls.first,
      'https://api.musubi.example/media/products/u1/a.webp',
    );
    expect(detail.conditionLabel, 'Usado · Buen estado');
    expect(detail.sellerId, isNull);
  });

  test('ProductSummary sigue siendo la tarjeta para la vista previa', () {
    const card = ProductSummary(id: 'p1', title: 'x', priceCents: 1, stock: 1);
    expect(card.soldOut, isFalse);
    expect(const Visitor(), isA<SessionState>());
  });
}
