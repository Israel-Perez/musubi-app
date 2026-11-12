import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/favorites_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/my_orders_widgets.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../helpers/fake_favorites_repository.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_status_repository.dart';
import '../../helpers/in_memory_token_store.dart';

const _cash = true;

/// Mis compras de la maqueta (`Perfil` → "Mis pedidos"), de la mas vieja a la
/// mas nueva: el fake las regresa al reves.
List<Order> _sample() => [
  sampleOrder(
    id: 'arduino',
    title: 'Kit Arduino UNO con sensores',
    priceCents: 42000,
    status: OrderStatus.completed,
    paysCash: _cash,
    updatedAt: DateTime(2026, 9, 26, 13),
  ),
  sampleOrder(
    id: 'algebra',
    title: 'Álgebra lineal, Grossman',
    priceCents: 29000,
  ),
  sampleOrder(
    id: 'casio',
    priceCents: 50000,
    status: OrderStatus.confirmed,
    paysCash: _cash,
  ),
];

/// App completa con el router real, la sesion abierta y los pedidos falsos.
class _Harness {
  new(this.tester, {List<Order>? orders})
    : orders = FakeOrderRepository(orders: orders ?? _sample());

  final WidgetTester tester;
  final FakeOrderRepository orders;
  late ProviderContainer container;

  Future<void> open(
    String location, {
    Size size = const Size(1170, 2532),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final tokens = testTokens();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          profileRepositoryProvider.overrideWithValue(FakeProfileRepository()),
          listingsRepositoryProvider.overrideWithValue(
            FakeListingsRepository(),
          ),
          favoritesRepositoryProvider.overrideWithValue(
            FakeFavoritesRepository(),
          ),
          statusRepositoryProvider.overrideWithValue(
            FakeStatusRepository([const ApiOnline(version: 'v1')]),
          ),
          orderRepositoryProvider.overrideWithValue(orders),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(tokens)),
          initialSessionTokensProvider.overrideWithValue(tokens),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    container.read(routerProvider).go(location);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}

void main() {
  group('la linea y el estado de cada pedido (HU-25)', () {
    test('sin pago, por aceptar, con entrega y ya cerrados', () {
      final at = DateTime(2026, 10, 3, 12);
      expect(
        orderLine(sampleOrder(priceCents: 29000)),
        r'Falta tu pago · $290',
      );
      expect(
        orderLine(sampleOrder(paysCash: true, priceCents: 29000)),
        r'Por aceptar · $290',
      );
      expect(
        orderLine(sampleOrder(status: OrderStatus.confirmed, paysCash: true)),
        startsWith('Entrega sáb 7 nov'),
      );
      expect(
        orderLine(
          sampleOrder(
            status: OrderStatus.completed,
            priceCents: 42000,
            updatedAt: at,
          ),
        ),
        r'3 oct · $420',
      );
      expect(
        orderLine(
          sampleOrder(
            status: OrderStatus.cancelled,
            quantity: 2,
            updatedAt: at,
          ),
        ),
        r'3 oct · $900',
      );
    });
  });

  group('Mis pedidos en Perfil (HU-25)', () {
    testWidgets('muestra mis tres compras mas nuevas con su estado', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.profile);

      final section = find.byKey(const Key('profile-orders'));
      await tester.ensureVisible(section);
      await tester.pumpAndSettle();

      expect(find.text('Mis pedidos'), findsOneWidget);
      expect(find.text('Ver todos'), findsOneWidget);
      final titles = tester
          .widgetList<OrderRow>(find.byType(OrderRow))
          .map((r) => r.order.item.title)
          .toList();
      expect(titles, [
        'Calculadora Casio fx-991ES Plus',
        'Álgebra lineal, Grossman',
        'Kit Arduino UNO con sensores',
      ]);
      expect(find.textContaining(r'Entrega sáb 7 nov · $500'), findsOneWidget);
      expect(find.text(r'Falta tu pago · $290'), findsOneWidget);
      expect(find.text(r'26 sep · $420'), findsOneWidget);
      expect(find.text('Confirmado'), findsOneWidget);
      expect(find.text('Pendiente'), findsOneWidget);
      expect(find.text('Completado'), findsOneWidget);
      expect(h.orders.mineCalls.single, (null, null, 3));
    });

    testWidgets('sin compras lo explica', (tester) async {
      final h = _Harness(tester, orders: []);
      await h.open(AppRoutes.profile);
      await tester.ensureVisible(find.byKey(const Key('profile-orders')));

      expect(find.byKey(const Key('profile-orders-empty')), findsOneWidget);
      expect(find.byType(OrderRow), findsNothing);
    });

    testWidgets('si falla, el Perfil sigue y se puede reintentar', (
      tester,
    ) async {
      final h = _Harness(tester);
      h.orders.mineFailure = const ApiFailure(
        code: ApiFailure.networkOffline,
        message: 'Sin conexión. Revisa tu internet.',
      );
      await h.open(AppRoutes.profile);
      await tester.ensureVisible(find.byKey(const Key('profile-orders')));

      expect(find.text('Sin conexión. Revisa tu internet.'), findsOneWidget);
      expect(find.byKey(const Key('profile-stats')), findsOneWidget);

      await h.tap(find.text('Reintentar'));

      expect(find.byType(OrderRow), findsNWidgets(3));
    });

    testWidgets('tocar un pedido abre Tu pedido', (tester) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.profile);

      await h.tap(find.byKey(const Key('my-order-casio')));

      expect(
        h.container.read(routerProvider).state.uri.path,
        AppRoutes.order('casio'),
      );
    });
  });

  group('Ver todos (HU-25)', () {
    testWidgets('abre las pestanas con sus numeros y empieza en Activos', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.profile);

      await h.tap(find.byKey(const Key('profile-orders-all')));

      expect(find.text('Activos (2)'), findsOneWidget);
      expect(find.text('Completados (1)'), findsOneWidget);
      expect(find.text('Cancelados (0)'), findsOneWidget);
      expect(find.byType(OrderRow), findsNWidgets(2));
      expect(h.orders.mineCalls.last, (MyOrdersTab.active, null, null));
    });

    testWidgets('cada pestana muestra lo suyo y su mensaje si esta vacia', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.myOrders);

      await h.tap(find.byKey(const Key('my-orders-tab-completed')));
      expect(find.text('Kit Arduino UNO con sensores'), findsOneWidget);
      expect(find.byType(OrderRow), findsOneWidget);

      await h.tap(find.byKey(const Key('my-orders-tab-cancelled')));
      expect(find.text('Sin pedidos cancelados'), findsOneWidget);
      expect(find.byType(OrderRow), findsNothing);
    });

    testWidgets('sin pedidos en curso lleva a ver productos', (tester) async {
      final h = _Harness(tester, orders: []);
      await h.open(AppRoutes.myOrders);

      expect(find.text('Sin pedidos en curso'), findsOneWidget);
      expect(find.text('Ver productos'), findsOneWidget);
    });

    testWidgets('"Ver más" agrega la siguiente pagina', (tester) async {
      final many = [
        for (var i = 0; i < 22; i++)
          sampleOrder(id: 'o$i', title: 'Pedido $i', paysCash: true),
      ];
      final h = _Harness(tester, orders: many);
      await h.open(AppRoutes.myOrders);

      // La lista se arma al desplazarse: la mas vieja de la primera pagina es
      // `o2` y "Ver más" trae `o1` y `o0`.
      final list = find.byType(Scrollable).last;
      await tester.scrollUntilVisible(
        find.text('Pedido 2'),
        300,
        scrollable: list,
      );
      expect(find.text('Pedido 1'), findsNothing);

      await h.tap(find.byKey(const Key('my-orders-more')));
      await tester.scrollUntilVisible(
        find.text('Pedido 0'),
        300,
        scrollable: list,
      );

      expect(find.text('Pedido 1'), findsOneWidget);
      expect(find.byKey(const Key('my-orders-more')), findsNothing);
      expect(h.orders.mineCalls.last, (MyOrdersTab.active, 'o2', null));
    });

    testWidgets('un error se reintenta', (tester) async {
      final h = _Harness(tester);
      h.orders.mineFailure = const ApiFailure(
        code: ApiFailure.serverError,
        message: 'Algo salió mal. Intenta de nuevo.',
      );
      await h.open(AppRoutes.myOrders);

      expect(find.text('Algo salió mal. Intenta de nuevo.'), findsOneWidget);

      await h.tap(find.text('Reintentar'));

      expect(find.byType(OrderRow), findsNWidgets(2));
    });

    testWidgets('al volver de un pedido, la lista se recarga', (tester) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.profile);
      await h.tap(find.byKey(const Key('profile-orders-all')));
      final before = h.orders.mineCalls.length;

      await h.tap(find.byKey(const Key('my-order-casio')));
      h.container.read(routerProvider).pop();
      await tester.pumpAndSettle();

      expect(h.orders.mineCalls.length, greaterThan(before));
      expect(find.text('Activos (2)'), findsOneWidget);
    });

    testWidgets('accesibilidad y 360x640 sin overflow', (tester) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.myOrders, size: const Size(360 * 3, 640 * 3));

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

    testWidgets('sin sesion pide iniciarla', (tester) async {
      expect(AppRoutes.requiresSession, contains(AppRoutes.myOrders));
    });
  });
}
