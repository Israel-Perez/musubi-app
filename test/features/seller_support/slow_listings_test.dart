import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/core/theme/app_theme.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/listings/presentation/sell_done_screen.dart';
import 'package:musubi_app/features/listings/presentation/sell_draft.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';
import 'package:musubi_app/features/seller_support/data/http_seller_support_repository.dart';
import 'package:musubi_app/features/seller_support/domain/seller_support.dart';
import 'package:musubi_app/features/seller_support/presentation/seller_support_providers.dart';
import 'package:musubi_app/features/seller_support/presentation/slow_listings_panel.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_seller_support.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/fake_wanted.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 15, 18);

final _demand = ProductDemand(
  people: 3,
  alerts: 1,
  requests: [
    DemandRequest(
      id: 'r-bata',
      title: 'Bata de laboratorio talla M, manga larga',
      budgetCents: 22000,
      requesterName: 'Fernanda O.',
      expiresAt: DateTime.utc(2026, 11, 22, 18),
    ),
    DemandRequest(
      id: 'r-quimica',
      title: 'Bata para química',
      budgetCents: 21000,
      requesterName: 'Luis M.',
      expiresAt: DateTime.utc(2026, 11, 20, 18),
    ),
  ],
);

/// App con sesion y `Mis-productos` abierto (como `my_products_manage_test`),
/// con "Llevan tiempo sin venderse" del fake.
class _Harness {
  new(this.tester);

  final WidgetTester tester;
  final listings = FakeListingsRepository();
  final support = FakeSellerSupportRepository(
    slowItems: [sampleSlow()],
    demands: {'bata': _demand},
  );
  final wanted = FakeWantedRepository(board: [boardWanted()]);
  late ProviderContainer container;

  Future<void> open() async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    listings.own = [sampleSlow().listing];
    final tokens = SessionTokens(
      accessToken: 'access',
      accessExpiresAt: _now.add(const Duration(minutes: 15)),
      refreshToken: 'refresh',
      profile: const SessionProfile(
        fullName: 'Diego Hernández',
        email: 'diego.hernandez@uttt.edu.mx',
        campus: 'UTTT',
      ),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([sampleFeed]),
          ),
          listingsRepositoryProvider.overrideWithValue(listings),
          orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
          sellerSupportRepositoryProvider.overrideWithValue(support),
          wantedRepositoryProvider.overrideWithValue(wanted),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(tokens)),
          initialSessionTokensProvider.overrideWithValue(tokens),
        ],
        child: const MusubiApp(),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    final context = tester.element(find.byType(Scaffold).first);
    // ignore: unawaited_futures, la pantalla se espera con pumpAndSettle.
    GoRouter.of(context).push(AppRoutes.myProducts);
    await tester.pumpAndSettle();
  }

  Future<void> tapKey(String key) async {
    final finder = find.byKey(Key(key));
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('Llevan tiempo sin venderse (HU-36)', () {
    testWidgets('en Activos, como la maqueta, arriba de Tu inventario', (
      tester,
    ) async {
      final h = _Harness(tester);
      h.support.slowItems = [
        sampleSlow(),
        sampleSlow(id: 'calc', title: 'Calculadora científica', days: 22),
      ];
      await h.open();

      expect(find.text('Llevan tiempo sin venderse'), findsOneWidget);
      expect(find.text('2 productos con más de 3 semanas'), findsOneWidget);
      expect(find.text(r'$250 · Publicada hace 34 días'), findsOneWidget);
      expect(find.text('96 vistas'), findsNWidgets(2));
      expect(find.text('0 mensajes'), findsNWidgets(2));
      expect(find.text('3 estudiantes la buscan'), findsNWidgets(2));
      expect(find.text('Ofrécesela'), findsNWidgets(2));
      // El panel va antes del inventario.
      expect(
        tester.getTopLeft(find.byKey(const Key('slow-listings'))).dy,
        lessThan(tester.getTopLeft(find.text('Tu inventario')).dy),
      );
    });

    testWidgets('una sola, sin nadie que la busque y con una vista', (
      tester,
    ) async {
      final h = _Harness(tester);
      h.support.slowItems = [sampleSlow(views: 1, messages: 1, people: 0)];
      await h.open();

      expect(find.text('1 producto con más de 3 semanas'), findsOneWidget);
      expect(find.text('1 vista'), findsOneWidget);
      expect(find.text('1 mensaje'), findsOneWidget);
      expect(find.byKey(const Key('slow-demand-bata')), findsNothing);
    });

    testWidgets('con mas de 3, "Ver los N" muestra el resto', (tester) async {
      final h = _Harness(tester);
      h.support.slowItems = [
        for (final id in ['a', 'b', 'c', 'd']) sampleSlow(id: id),
      ];
      await h.open();

      expect(find.byKey(const Key('slow-d')), findsNothing);
      await h.tapKey('slow-listings-all');

      expect(find.byKey(const Key('slow-d')), findsOneWidget);
      expect(find.byKey(const Key('slow-listings-all')), findsNothing);
    });

    testWidgets('sin nada, o si falla, la pantalla sigue sin el panel', (
      tester,
    ) async {
      final h = _Harness(tester);
      h.support.slowFailure = const ApiFailure(
        code: ApiFailure.serverError,
        message: 'El servidor no responde.',
      );
      await h.open();

      expect(find.byKey(const Key('slow-listings')), findsNothing);
      expect(find.text('Tu inventario'), findsOneWidget);
    });

    testWidgets('no sale en Vendidos', (tester) async {
      final h = _Harness(tester);
      await h.open();

      await tester.tap(find.textContaining('Vendidos ('));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('slow-listings')), findsNothing);
    });
  });

  group('Ideas para vender más rápido (HU-37)', () {
    testWidgets('al tocar la tarjeta, las tres ideas y "Editar publicación"', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open();

      await h.tapKey('slow-bata');

      expect(find.text('Ideas para vender más rápido'), findsOneWidget);
      expect(
        find.text(
          '«Bata de laboratorio blanca, talla M» lleva 34 días publicada sin '
          'venderse.',
        ),
        findsOneWidget,
      );
      expect(find.text('Revisa el precio'), findsOneWidget);
      expect(
        find.text(
          r'Quienes buscan algo así ofrecen hasta $220 y tú pides $250.',
        ),
        findsOneWidget,
      );
      expect(find.text('Mejora la descripción'), findsOneWidget);
      expect(find.text('Actualiza las fotos'), findsOneWidget);
      // RN-38: solo orientan.
      expect(find.textContaining('tú decides qué cambiar'), findsOneWidget);

      await h.tapKey('slow-tips-edit');

      expect(h.container.read(sellEditDraftProvider).editingId, 'bata');
      expect(find.byKey(const Key('slow-tips')), findsNothing);
    });
  });

  group('Quienes la buscan (HU-38)', () {
    testWidgets('las solicitudes y cuantas alertas, sin decir de quien', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open();

      await h.tapKey('slow-demand-bata');

      expect(find.text('Quienes la buscan'), findsOneWidget);
      expect(
        find.text('Bata de laboratorio talla M, manga larga'),
        findsOneWidget,
      );
      expect(
        find.text(r'Fernanda O. · Hasta $220 · Vence el 22 nov'),
        findsOneWidget,
      );
      expect(find.text(r'Luis M. · Hasta $210 · Vence el 20 nov'), findsOne);
      expect(
        find.text(
          'Y 1 persona más tiene una alerta que coincide con tu producto. Por '
          'privacidad, no te decimos quiénes.',
        ),
        findsOneWidget,
      );
      expect(h.support.demandCalls, ['bata']);
    });

    testWidgets('"Yo tengo este producto" abre la oferta de esa solicitud', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open();
      await h.tapKey('slow-demand-bata');

      await h.tapKey('demand-offer-r-bata');

      expect(h.wanted.gets, ['r-bata']);
      expect(find.byKey(const Key('offer-send')), findsOneWidget);
    });

    testWidgets('una solicitud que ya no esta activa lo dice', (tester) async {
      final h = _Harness(tester);
      await h.open();
      await h.tapKey('slow-demand-bata');

      await h.tapKey('demand-offer-r-quimica');

      expect(find.text('Esta solicitud ya no está activa.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('solo alertas: lo dice sin solicitudes', (tester) async {
      final h = _Harness(tester);
      h.support.demands['bata'] = const ProductDemand(people: 2, alerts: 2);
      await h.open();
      await h.tapKey('slow-demand-bata');

      expect(
        find.text(
          '2 personas tienen una alerta que coincide con tu producto. Por '
          'privacidad, no te decimos quiénes.',
        ),
        findsOneWidget,
      );
    });
  });

  group('Vender-listo (HU-38)', () {
    Future<void> openDone(
      WidgetTester tester,
      FakeSellerSupportRepository support,
    ) async {
      tester.view
        ..physicalSize = const Size(1170, 2532)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sellerSupportRepositoryProvider.overrideWithValue(support),
          ],
          child: MaterialApp(
            theme: AppTheme.light(),
            home: SellDoneScreen(
              published: PublishedListing(
                product: sampleSlow().listing.product,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('"2 estudiantes buscan algo similar" con Ver solicitudes', (
      tester,
    ) async {
      final support = FakeSellerSupportRepository(
        demands: {'bata': ProductDemand(people: 2, requests: _demand.requests)},
      );
      await openDone(tester, support);

      expect(find.text('2 estudiantes buscan algo similar'), findsOneWidget);
      expect(
        find.text(
          'Ofréceles tu bata directo con “Yo tengo este producto” y vende más '
          'rápido.',
        ),
        findsOneWidget,
      );
      expect(find.text('Ver solicitudes'), findsOneWidget);
    });

    testWidgets('sin solicitudes no hay tarjeta', (tester) async {
      final support = FakeSellerSupportRepository(
        demands: {'bata': const ProductDemand(people: 1, alerts: 1)},
      );
      await openDone(tester, support);

      expect(find.byKey(const Key('published-demand')), findsNothing);
    });
  });

  test('el nombre corto se lee como el aviso de la API', () {
    expect(shortName('Bata de laboratorio blanca, talla M'), 'bata');
    expect(shortName('Calculadora, casi nueva'), 'calculadora');
    expect(shortName('iPad de 9a generación'), 'iPad');
    expect(shortName('USB de 64 GB'), 'USB');
    expect(shortName('TI-84 Plus'), isNull);
    expect(shortName('2 libros'), isNull);
  });

  test('el aviso "lleva N días sin venderse" abre Mis productos', () {
    expect(
      NotificationTarget.parse('my_products'),
      NotificationTarget.myProducts,
    );
    expect(
      routeFor(NotificationTarget.myProducts, 'bata'),
      AppRoutes.myProducts,
    );
  });

  group('HttpSellerSupportRepository', () {
    late FakeHttpAdapter adapter;
    late HttpSellerSupportRepository repository;

    void serve(ResponseBody Function(RequestOptions options) response) {
      adapter = FakeHttpAdapter((options) async => response(options));
      repository = HttpSellerSupportRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
        Uri.parse('https://api.musubi.example'),
      );
    }

    test('"Llevan tiempo sin venderse" con su demanda y sus ideas', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'thresholdDays': 21,
          'items': [
            {
              'product': {
                'id': 'bata',
                'title': 'Bata de laboratorio blanca, talla M',
                'description': 'Bata corta.',
                'category': 'laboratorio',
                'priceCents': 25000,
                'condition': 'used',
                'conditionDetail': 'good',
                'stock': 1,
                'status': 'active',
                'photos': ['/media/products/u1/a.webp'],
                'seller': {'name': 'Diego H.'},
                'publishedAt': '2026-10-12T18:00:00Z',
                'soldAt': null,
              },
              'daysListed': 34,
              'views': 96,
              'messages': 0,
              'demand': {'people': 3, 'requests': 2},
              'tips': [
                {
                  'kind': 'photos',
                  'title': 'Actualiza las fotos',
                  'body': 'Tiene 1 foto.',
                  'applies': true,
                },
              ],
            },
          ],
        }),
      );

      final slow = await repository.slow();

      expect(adapter.requests.single.path, ApiPaths.slowProducts);
      final item = slow.items.single;
      expect(
        (item.listing.product.id, item.daysListed, item.views, item.people),
        ('bata', 34, 96, 3),
      );
      expect(
        (item.tips.single.kind, item.tips.single.applies),
        (SalesTipKind.photos, true),
      );
      expect(slow.thresholdDays, 21);
    });

    test('"Quienes la buscan"', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'people': 2,
          'alerts': 1,
          'requests': [
            {
              'id': 'r1',
              'title': 'Bata talla M',
              'budgetCents': 22000,
              'requesterName': 'Fernanda O.',
              'expiresAt': '2026-11-22T18:00:00Z',
            },
          ],
        }),
      );

      final demand = await repository.demand('bata');

      expect(adapter.requests.single.path, ApiPaths.productDemand('bata'));
      expect((demand.people, demand.alerts), (2, 1));
      expect(demand.requests.single.expiresAt, DateTime.utc(2026, 11, 22, 18));
    });

    test('un 404 llega como ApiFailure con su code', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'code': 'listings.product_not_found',
          'title': 'No encontramos esta publicación.',
        }, status: 404),
      );

      await expectLater(
        repository.demand('ajena'),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'listings.product_not_found',
          ),
        ),
      );
    });
  });
}
