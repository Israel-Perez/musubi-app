import 'dart:async';

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
import 'package:musubi_app/features/marketplace/domain/comparison.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/presentation/comparison_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/search_screen.dart';
import 'package:musubi_app/features/profile/domain/profile_models.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/profile/presentation/seller_profile_screen.dart';
import 'package:musubi_app/features/recommendations/presentation/recommendation_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_comparison.dart';
import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_recommendations.dart';
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
  categorySlug: 'calculadoras',
);

Future<FakeCatalogRepository> _open(
  WidgetTester tester, {
  required ProductDetail? detail,
  SessionTokens? session,
  FakeFavoritesRepository? favorites,
  FakeRecommendationRepository? recommendations,
  FakeComparisonRepository? comparison,
  PublicProfile? seller,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final catalog = FakeCatalogRepository();
  if (detail != null) catalog.details['p1'] = detail;
  final profiles = FakeProfileRepository();
  profiles.publicProfiles['6716a0000000000000000001'] =
      seller ?? FakeProfileRepository.publicSample;
  profiles.publicProfiles[myId] = FakeProfileRepository.publicSample;
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
        recommendationRepositoryProvider.overrideWithValue(
          recommendations ?? FakeRecommendationRepository(),
        ),
        comparisonRepositoryProvider.overrideWithValue(
          comparison ?? FakeComparisonRepository(),
        ),
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
    // HU-64: sin datos de respuesta ni confianza, no se inventan.
    expect(find.byKey(const Key('seller-trust')), findsNothing);
    expect(find.text('Comprar'), findsOneWidget);
    expect(find.text('Apartar'), findsOneWidget);
  });

  // HU-64: las insignias de confianza en la tarjeta de quien vende.
  testWidgets('quien vende: "Responde en ~1 h" y "Vendedor confiable"', (
    tester,
  ) async {
    await _open(
      tester,
      detail: _detail(),
      session: chatTokens(_now),
      seller: FakeProfileRepository.publicWithBadges,
    );

    final trust = find.byKey(const Key('seller-trust'));
    await tester.ensureVisible(trust);
    expect(
      find.descendant(of: trust, matching: find.text('Responde en ~1 h')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('trusted-badge')), findsOneWidget);
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

    expect(find.text('Arquitectura · 8º cuatrimestre'), findsOneWidget);
    expect(find.text('Publicaciones (3)'), findsOneWidget);
    // "Mensaje" del perfil abrira el chat de esta publicacion.
    final screen = tester.widget<SellerProfileScreen>(
      find.byType(SellerProfileScreen),
    );
    expect(screen.origin?.product?.id, _detail().id);
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

  // SCRUM-114: desde Inicio (con la barra abajo), empujar `Perfil` encima del
  // detalle reservaba dos veces la misma llave del Navigator: pantalla gris.
  testWidgets('mi publicación, desde Inicio: abre "así te ven" sin errores', (
    tester,
  ) async {
    await _open(
      tester,
      detail: _detail(sellerId: myId),
      session: chatTokens(_now),
    );
    final router = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    ).read(routerProvider)..go(AppRoutes.home);
    await tester.pumpAndSettle();
    unawaited(router.push(AppRoutes.product('p1')));
    await tester.pumpAndSettle();

    final card = find.bySemanticsLabel(RegExp('^Ver perfil de Valeria'));
    await tester.ensureVisible(card);
    await tester.tap(card);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SellerProfileScreen), findsOneWidget);
    expect(find.text('Así te ven los demás'), findsOneWidget);
    expect(find.byKey(const Key('seller-mensaje')), findsNothing);
    expect(find.byKey(const Key('seller-seguir')), findsNothing);
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

  // HU-35: "Productos parecidos" y "Ver parecidos" (ML de la API).
  group('Productos parecidos (HU-35)', () {
    FakeRecommendationRepository withSimilar() => FakeRecommendationRepository(
      similarItems: {
        'p1': [
          ProductSummary(
            id: 'p2',
            title: 'Calculadora Casio fx-82',
            priceCents: 28000,
            stock: 1,
            sellerName: 'Diego H.',
            publishedAt: _now.subtract(const Duration(hours: 3)),
          ),
        ],
      },
    );

    testWidgets('al final del detalle; tocar uno abre su detalle', (
      tester,
    ) async {
      final recommendations = withSimilar();
      final catalog = await _open(
        tester,
        detail: _detail(),
        session: chatTokens(_now),
        recommendations: recommendations,
      );
      catalog.details['p2'] = _detail();

      await tester.scrollUntilVisible(
        find.byKey(const Key('similar-p2')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Productos parecidos'), findsOneWidget);
      expect(recommendations.similarCalls, ['p1']);

      await tester.tap(find.byKey(const Key('similar-p2')));
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(MusubiApp)),
      );
      expect(
        container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation,
        AppRoutes.product('p2'),
      );
    });

    testWidgets('agotado: "Ver parecidos" baja hasta ellos', (tester) async {
      await _open(
        tester,
        detail: _detail(status: 'soldOut', stock: 0),
        session: chatTokens(_now),
        recommendations: withSimilar(),
      );
      final before = tester.getTopLeft(find.text('Productos parecidos')).dy;

      await tester.tap(find.text('Ver parecidos'));
      await tester.pumpAndSettle();

      // Sube y queda a la vista, lejos de la barra de abajo (es lo ultimo del
      // detalle: no puede quedar hasta arriba).
      final after = tester.getTopLeft(find.text('Productos parecidos')).dy;
      expect(after, lessThan(before - 200));
      expect(after, lessThan(600));
    });

    testWidgets('sin parecidos, la seccion no se muestra y el boton lo dice', (
      tester,
    ) async {
      await _open(
        tester,
        detail: _detail(status: 'soldOut', stock: 0),
        session: chatTokens(_now),
      );

      expect(find.text('Productos parecidos'), findsNothing);
      await tester.tap(find.text('Ver parecidos'));
      await tester.pump();

      expect(
        find.text('Aún no encontramos productos parecidos.'),
        findsOneWidget,
      );
    });
  });

  // HU-51: "Compara antes de comprar" y "Avísame" (maqueta `Producto`).
  group('Comparar y Avísame (HU-51)', () {
    FakeComparisonRepository withOptions({Set<String>? watching}) =>
        FakeComparisonRepository(
          options: {'p1': casioOptions()},
          watching: watching,
        );

    testWidgets('con la estimacion del modelo, la fila de Musubi (HU-58)', (
      tester,
    ) async {
      final comparison = withOptions()
        ..estimates['p1'] = const PriceEstimate(
          minCents: 40000,
          maxCents: 52000,
          verdict: PriceVerdict.fair,
        );
      await _open(
        tester,
        detail: _detail(),
        session: chatTokens(_now),
        comparison: comparison,
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('compare-estimate')),
        300,
        scrollable: find.byType(Scrollable).first,
      );

      expect(
        find.text(r'Musubi estima $400 – $520 para algo así · precio justo'),
        findsOneWidget,
      );
    });

    String location(WidgetTester tester) =>
        ProviderScope.containerOf(tester.element(find.byType(MusubiApp)))
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .last
            .matchedLocation;

    testWidgets('con sesion: la barra de precios, la mejor opción y el orden', (
      tester,
    ) async {
      final comparison = withOptions();
      await _open(
        tester,
        detail: _detail(),
        session: chatTokens(_now),
        comparison: comparison,
      );

      await tester.scrollUntilVisible(
        find.text('Compara antes de comprar'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      // HU-58: tambien pide la estimacion del modelo (sin ella no hay fila).
      expect(comparison.calls, unorderedEquals(['compare:p1', 'estimate:p1']));
      expect(find.byKey(const Key('compare-estimate')), findsNothing);
      expect(
        find.text('5 opciones en UTTT · 2 del mismo modelo'),
        findsOneWidget,
      );
      expect(find.text('Este modelo en UTTT'), findsOneWidget);
      expect(find.text('Precio justo'), findsOneWidget);
      expect(find.text(r'$400 más bajo'), findsOneWidget);
      expect(find.text(r'$480 más alto'), findsOneWidget);
      expect(
        find.textContaining(r'promedio $443', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Combina reputación, ventas y precio.'), findsOneWidget);

      // "Para ti": la de Diego es la mejor opción y va primero.
      final best = find.ancestor(
        of: find.byKey(const Key('compare-best')),
        matching: find.byType(Stack),
      );
      expect(
        find.descendant(of: best.first, matching: find.text('Diego H.')),
        findsOneWidget,
      );
      expect(find.text('Mejor reputación'), findsOneWidget);
      expect(find.text('Más ventas'), findsOneWidget);
      expect(find.text('Precio más bajo'), findsOneWidget);
      expect(find.text('Mismo modelo'), findsNWidgets(2));
      expect(find.text(r'$50 menos'), findsOneWidget);
      expect(find.text(r'$30 más'), findsOneWidget);

      // "Precio": del más barato al más caro y sin "Mejor opción".
      await tester.ensureVisible(find.byKey(const Key('compare-order-price')));
      await tester.tap(find.byKey(const Key('compare-order-price')));
      await tester.pumpAndSettle();

      expect(find.text('Del más barato al más caro.'), findsOneWidget);
      expect(find.byKey(const Key('compare-best')), findsNothing);
      final ys = [
        for (final id in ['c4', 'c2', 'c1', 'c3', 'c5'])
          tester.getTopLeft(find.byKey(Key('compare-$id'))).dy,
      ];
      expect(ys, orderedEquals([...ys]..sort()));
    });

    testWidgets('tocar una opción abre su detalle', (tester) async {
      final catalog = await _open(
        tester,
        detail: _detail(),
        session: chatTokens(_now),
        comparison: withOptions(),
      );
      catalog.details['c3'] = _detail();

      final card = find.byKey(const Key('compare-c3'));
      await tester.scrollUntilVisible(
        card,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(card);
      await tester.pumpAndSettle();

      expect(location(tester), AppRoutes.product('c3'));
    });

    testWidgets('"Ver todas las calculadoras" abre la búsqueda filtrada', (
      tester,
    ) async {
      await _open(
        tester,
        detail: _detail(),
        session: chatTokens(_now),
        comparison: withOptions(),
      );

      final all = find.text('Ver todas las calculadoras');
      await tester.scrollUntilVisible(
        all,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(all);
      await tester.pumpAndSettle();

      final search = tester.widget<SearchScreen>(find.byType(SearchScreen));
      expect(search.initialFilter?.categories, ['calculadoras']);
    });

    testWidgets('sin opciones o sin sesion no hay comparador', (tester) async {
      final empty = FakeComparisonRepository();
      await _open(
        tester,
        detail: _detail(),
        session: chatTokens(_now),
        comparison: empty,
      );
      expect(find.text('Compara antes de comprar'), findsNothing);
      expect(empty.calls, ['compare:p1']);
    });

    testWidgets('visitante: ni compara ni pide el aviso (RNF-05)', (
      tester,
    ) async {
      final comparison = withOptions();
      await _open(
        tester,
        detail: _detail(status: 'soldOut', stock: 0, sellerId: null),
        comparison: comparison,
      );

      expect(find.text('Compara antes de comprar'), findsNothing);
      await tester.tap(find.text('Avísame'));
      await tester.pumpAndSettle();

      expect(comparison.calls, isEmpty);
      expect(find.text('Te avisamos si vuelve'), findsOneWidget);
      expect(
        find.text('Crea tu cuenta para recibir el aviso.'),
        findsOneWidget,
      );
    });

    testWidgets('agotado: "Avísame" pasa a "Te avisaremos" y se puede quitar', (
      tester,
    ) async {
      final comparison = withOptions();
      await _open(
        tester,
        detail: _detail(status: 'soldOut', stock: 0),
        session: chatTokens(_now),
        comparison: comparison,
      );

      await tester.tap(find.text('Avísame'));
      await tester.pump();
      expect(
        find.text(
          'Te avisaremos cuando vuelva «Calculadora científica Casio '
          'fx-991ES Plus»',
        ),
        findsOneWidget,
      );
      await tester.pumpAndSettle();
      expect(find.text('Te avisaremos'), findsOneWidget);
      expect(find.text('Avísame'), findsNothing);
      expect(comparison.watching, {'p1'});

      await tester.tap(find.text('Te avisaremos'));
      // El aviso anterior sale primero (hideCurrentSnackBar).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Quitaste el aviso'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Avísame'), findsOneWidget);
      expect(comparison.watching, isEmpty);
      expect(
        comparison.calls.where(
          // HU-58: la estimacion tampoco es parte del aviso.
          (c) => !c.startsWith('compare') && !c.startsWith('estimate'),
        ),
        ['status:p1', 'watch:p1', 'status:p1', 'unwatch:p1', 'status:p1'],
      );
    });

    testWidgets('si ya lo pedí, abre en "Te avisaremos"', (tester) async {
      await _open(
        tester,
        detail: _detail(status: 'soldOut', stock: 0),
        session: chatTokens(_now),
        comparison: withOptions(watching: {'p1'}),
      );

      expect(find.text('Te avisaremos'), findsOneWidget);
    });

    testWidgets('si la API falla, regresa a "Avísame" y dice por qué', (
      tester,
    ) async {
      final comparison = withOptions();
      await _open(
        tester,
        detail: _detail(status: 'soldOut', stock: 0),
        session: chatTokens(_now),
        comparison: comparison,
      );
      comparison.failure = const ApiFailure(
        code: 'listings.product_available',
        message: 'Esta publicación ya está disponible.',
      );

      await tester.tap(find.text('Avísame'));
      await tester.pump();

      expect(find.text('Esta publicación ya está disponible.'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Avísame'), findsOneWidget);
      expect(comparison.watching, isEmpty);
    });

    testWidgets('agotado: "Ver parecidos" baja primero al comparador', (
      tester,
    ) async {
      await _open(
        tester,
        detail: _detail(status: 'soldOut', stock: 0),
        session: chatTokens(_now),
        comparison: withOptions(),
      );
      final before = tester
          .getTopLeft(find.text('Compara antes de comprar'))
          .dy;

      await tester.tap(find.text('Ver parecidos'));
      await tester.pumpAndSettle();

      final after = tester.getTopLeft(find.text('Compara antes de comprar')).dy;
      expect(after, lessThan(before - 200));
      expect(after, lessThan(120));
    });

    testWidgets('mi publicación agotada no pide el aviso', (tester) async {
      final comparison = withOptions();
      await _open(
        tester,
        detail: _detail(status: 'soldOut', stock: 0, sellerId: myId),
        session: chatTokens(_now),
        comparison: comparison,
      );

      expect(find.text('Ver mis productos'), findsOneWidget);
      expect(comparison.calls.where((c) => c.startsWith('status')), isEmpty);
    });
  });
}
