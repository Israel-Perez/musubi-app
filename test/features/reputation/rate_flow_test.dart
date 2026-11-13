import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/reputation/domain/reputation_models.dart';
import 'package:musubi_app/features/reputation/presentation/reputation_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_reputation.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 12, 18);

/// Un pedido completado de Ana a Valeria, con plazo para calificar.
Order _completed({
  String id = 'o1',
  bool isBuyer = true,
  bool rated = false,
  DateTime? until,
}) =>
    sampleOrder(
      id: id,
      isBuyer: isBuyer,
      paysCash: true,
      status: OrderStatus.completed,
      buyerConfirmed: true,
      sellerConfirmed: true,
    ).copyWith(
      ratedByMe: rated,
      rateUntil: until ?? _now.add(const Duration(days: 6)),
    );

/// App completa con el router real, la sesion abierta y los pedidos y la
/// reputacion falsos.
class _Harness {
  new(this.tester, {required List<Order> orders})
    : orders = FakeOrderRepository(orders: orders);

  final WidgetTester tester;
  final FakeOrderRepository orders;
  final reputation = FakeReputationRepository();
  late ProviderContainer container;

  Future<void> open(
    String location, {
    Size size = const Size(1170, 2532),
  }) async {
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(_now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([const HomeFeed()]),
          ),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          orderRepositoryProvider.overrideWithValue(orders),
          reputationRepositoryProvider.overrideWithValue(reputation),
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

  String get path => container.read(routerProvider).state.uri.path;

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('un pedido completado ofrece "Calificar a Valeria"', (
    tester,
  ) async {
    final h = _Harness(tester, orders: [_completed()]);
    await h.open(AppRoutes.order('o1'));

    await h.tap(find.byKey(const Key('order-rate')));

    expect(h.path, AppRoutes.rate('o1'));
    expect(find.text('¿Cómo te fue con Valeria?'), findsOneWidget);
    expect(find.text('Pedido completado'), findsOneWidget);
    expect(find.text('¡Excelente!'), findsOneWidget);
    expect(find.text('Como se describió'), findsOneWidget);
    expect(find.text('Pagó lo acordado'), findsNothing);
    expect(
      find.text('Tu calificación aparecerá en el perfil de Valeria.'),
      findsOneWidget,
    );
  });

  testWidgets('elegir estrellas, chips y comentario y enviar', (tester) async {
    final h = _Harness(tester, orders: [_completed()]);
    await h.open(AppRoutes.rate('o1'));

    await h.tap(find.byKey(const Key('rate-star-4')));
    expect(find.text('Muy buena'), findsOneWidget);
    // Se tocan al reves: se mandan en el orden de la lista.
    await h.tap(find.byKey(const Key('rate-tag-as_described')));
    await h.tap(find.byKey(const Key('rate-tag-on_time')));
    await tester.enterText(
      find.byKey(const Key('rate-comment')),
      '  Muy puntual en la biblioteca.  ',
    );
    await h.tap(find.byKey(const Key('rate-send')));

    final (orderId, rating) = h.reputation.rated.single;
    expect(orderId, 'o1');
    expect(rating.stars, 4);
    expect(rating.tags, [RatingTag.onTime, RatingTag.asDescribed]);
    expect(rating.comment, 'Muy puntual en la biblioteca.');
    expect(h.path, AppRoutes.home);
    expect(
      find.text('¡Gracias! Tu calificación ya está en el perfil de Valeria.'),
      findsOneWidget,
    );
  });

  testWidgets('quien vende califica con los chips de quien compra', (
    tester,
  ) async {
    final h = _Harness(tester, orders: [_completed(isBuyer: false)]);
    await h.open(AppRoutes.rate('o1'));

    expect(find.text('¿Cómo te fue con Ana?'), findsOneWidget);
    expect(find.text('Pagó lo acordado'), findsOneWidget);
    expect(find.text('Como se describió'), findsNothing);
    expect(find.text('Precio justo'), findsNothing);
  });

  testWidgets('"Ahora no" regresa al pedido sin calificar', (tester) async {
    final h = _Harness(tester, orders: [_completed()]);
    await h.open(AppRoutes.order('o1'));
    await h.tap(find.byKey(const Key('order-rate')));

    await h.tap(find.byKey(const Key('rate-later')));

    expect(h.path, AppRoutes.order('o1'));
    expect(h.reputation.rated, isEmpty);
  });

  testWidgets('ya calificado: lo dice y no ofrece calificar', (tester) async {
    final h = _Harness(tester, orders: [_completed(rated: true)]);
    await h.open(AppRoutes.order('o1'));

    expect(find.byKey(const Key('order-rate')), findsNothing);
    expect(
      find.text('Pedido completado. Ya calificaste a Valeria.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('order-back-to-chat')), findsOneWidget);
  });

  testWidgets('fuera de plazo no ofrece calificar', (tester) async {
    final late = _completed(until: _now.subtract(const Duration(minutes: 1)));
    final h = _Harness(tester, orders: [late]);
    await h.open(AppRoutes.order('o1'));

    expect(find.byKey(const Key('order-rate')), findsNothing);
    expect(find.byKey(const Key('order-back-to-chat')), findsOneWidget);
  });

  testWidgets('la entrega que completa el pedido abre Calificar', (
    tester,
  ) async {
    final confirmed = sampleOrder(
      paysCash: true,
      status: OrderStatus.confirmed,
      sellerConfirmed: true,
    );
    final h = _Harness(tester, orders: [confirmed]);
    await h.open(AppRoutes.order('o1'));

    await h.tap(find.byKey(const Key('order-handover')));

    expect(h.path, AppRoutes.rate('o1'));
    expect(find.text('¿Cómo te fue con Valeria?'), findsOneWidget);
  });

  testWidgets('si falla al enviar, se queda y lo explica', (tester) async {
    final h = _Harness(tester, orders: [_completed()]);
    h.reputation.rateFailure = const ApiFailure(
      code: ApiFailure.serverError,
      message: 'Algo salió mal. Intenta de nuevo.',
    );
    await h.open(AppRoutes.rate('o1'));

    await h.tap(find.byKey(const Key('rate-send')));

    expect(h.path, AppRoutes.rate('o1'));
    expect(find.text('Algo salió mal. Intenta de nuevo.'), findsOneWidget);
    expect(h.reputation.rated, isEmpty);
  });

  testWidgets('accesibilidad y 360x640 sin overflow', (tester) async {
    final h = _Harness(tester, orders: [_completed()]);
    await h.open(AppRoutes.rate('o1'), size: const Size(360 * 3, 640 * 3));

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
}
