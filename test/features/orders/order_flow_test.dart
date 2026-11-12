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
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/genai/presentation/agreement_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

import '../../helpers/fake_agreements.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 6, 21);

ProductDetail _detail({int stock = 1}) => ProductDetail(
  id: 'p1',
  title: 'Calculadora Casio fx-991ES Plus',
  description: 'La usé un semestre para Cálculo y Física.',
  categoryName: 'Calculadoras',
  priceCents: 45000,
  condition: 'used',
  conditionDetail: 'fair',
  stock: stock,
  status: 'active',
  photoUrls: const [],
  publishedAt: _now.subtract(const Duration(days: 2)),
  sellerId: valeria.id,
  sellerName: 'Valeria C.',
);

/// App completa con el router real, la sesion abierta, el chat y los pedidos
/// falsos.
class _Harness {
  new(this.tester, {FakeChatRepository? chat, FakeOrderRepository? orders})
    : chat = chat ?? FakeChatRepository(),
      orders = orders ?? FakeOrderRepository();

  final WidgetTester tester;
  final FakeChatRepository chat;
  final FakeOrderRepository orders;
  late ProviderContainer container;

  Future<void> open(String location, {int stock = 1}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(_now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([const HomeFeed()])
              ..details['p1'] = _detail(stock: stock),
          ),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(chat),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          orderRepositoryProvider.overrideWithValue(orders),
          // Sin IA (RNF-15): "Resumir acuerdo" abre el resumen a mano.
          agreementRepositoryProvider.overrideWithValue(
            FakeAgreementRepository()..requestFailure = aiUnavailable,
          ),
          aiNoticeStoreProvider.overrideWithValue(
            FakeAiNoticeStore(wasSeen: true),
          ),
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

  /// Una opcion de una hoja (`MusubiOptions` la elige 160 ms despues).
  Future<void> pick(String label) async {
    await tester.tap(find.text(label));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
  }

  /// "Agregar" de una fila del resumen.
  Future<void> add(String row) => tap(
    find.descendant(of: find.byKey(Key(row)), matching: find.text('Agregar')),
  );

  /// Biblioteca, mañana a la 1:00 p. m.
  Future<void> fillIn({String? detail}) async {
    await add('order-place');
    await tap(find.byKey(const Key('order-point-biblioteca')));
    if (detail != null) {
      await tester.enterText(find.byKey(const Key('order-detail')), detail);
    }
    await tap(find.byKey(const Key('order-place-done')));
    await add('order-when');
    await tap(find.text('Mañana'));
    await tap(find.byKey(const Key('order-hour-13')));
    await tap(find.byKey(const Key('order-when-done')));
  }
}

MusubiButtonState _button(WidgetTester tester, String key) =>
    MusubiButtonState(tester, key);

/// Lee si un `MusubiButton` se puede tocar.
class MusubiButtonState {
  new(this.tester, this.key);

  final WidgetTester tester;
  final String key;

  bool get enabled {
    final widget = tester.widget(find.byKey(Key(key)));
    return (widget as dynamic).onPressed != null;
  }
}

void main() {
  group('Resumen del acuerdo (HU-23)', () {
    testWidgets('Resumir acuerdo abre el resumen con el producto y el precio, '
        'sin entrega ni fecha', (tester) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.conversation('c1'));

      await h.tap(find.byKey(const Key('chat-summarize')));

      expect(find.text('Resumen del acuerdo'), findsOneWidget);
      expect(find.text('Con base en tu chat con Valeria'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('order-summary')),
          matching: find.text('Calculadora Casio fx-991ES Plus'),
        ),
        findsOneWidget,
      );
      expect(find.text(r'$450'), findsOneWidget);
      expect(find.text('No identificado'), findsNWidgets(2));
      expect(_button(tester, 'order-create').enabled, isFalse);
      // Con 1 pieza no hay lapiz en "Cantidad".
      expect(
        find.descendant(
          of: find.byKey(const Key('order-quantity')),
          matching: find.bySemanticsLabel('Editar cantidad'),
        ),
        findsNothing,
      );
    });

    testWidgets('el edificio de mi carrera sale primero', (tester) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.conversation('c1'));
      await h.tap(find.byKey(const Key('chat-summarize')));

      await h.add('order-place');

      final suggested = tester.getTopLeft(
        find.byKey(const Key('order-point-tecnologias-informacion')),
      );
      final library = tester.getTopLeft(
        find.byKey(const Key('order-point-biblioteca')),
      );
      expect(
        find.text('Primero está el edificio de tu carrera.'),
        findsOneWidget,
      );
      expect(suggested.dy < library.dy || suggested.dx < library.dx, isTrue);
      expect(_button(tester, 'order-place-done').enabled, isFalse);
    });

    testWidgets('elegir entrega y fecha y crear el pedido abre Tu pedido', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.conversation('c1'));
      await h.tap(find.byKey(const Key('chat-summarize')));

      await h.fillIn(detail: 'Planta baja, junto a la entrada');

      expect(find.text('Campus universitario · Biblioteca'), findsOneWidget);
      expect(find.text('Planta baja, junto a la entrada'), findsOneWidget);
      expect(_button(tester, 'order-create').enabled, isTrue);
      await h.tap(find.byKey(const Key('order-create')));

      final created = h.orders.created.single;
      expect(created.conversationId, 'c1');
      expect(created.quantity, 1);
      expect(created.meetingPoint, 'biblioteca');
      expect(created.detail, 'Planta baja, junto a la entrada');
      expect(created.deliveryAt.toLocal(), DateTime(2026, 11, 7, 13));
      expect(find.text('Tu pedido'), findsOneWidget);
      expect(find.text('#MS-1001'), findsOneWidget);
      expect(find.text('¿Cómo quieres pagar?'), findsOneWidget);
    });

    testWidgets('con piezas, el lapiz de Cantidad sube hasta lo disponible', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.conversation('c1'), stock: 2);
      await h.tap(find.byKey(const Key('chat-summarize')));

      await h.tap(find.bySemanticsLabel('Editar cantidad'));
      await h.tap(find.byKey(const Key('need-quantity-1')));
      expect(find.text('Puedes pedir hasta 2.'), findsOneWidget);
      await h.tap(find.byKey(const Key('order-quantity-done')));
      await h.fillIn();
      await h.tap(find.byKey(const Key('order-create')));

      expect(h.orders.created.single.quantity, 2);
    });

    testWidgets('si la API rechaza el pedido, avisa y no pierde lo elegido', (
      tester,
    ) async {
      final h = _Harness(tester)
        ..orders.createFailure = const ApiFailure(
          code: 'orders.not_enough_stock',
          message:
              'No hay tantas piezas disponibles. Elige una cantidad menor.',
        );
      await h.open(AppRoutes.conversation('c1'));
      await h.tap(find.byKey(const Key('chat-summarize')));
      await h.fillIn();

      await h.tap(find.byKey(const Key('order-create')));

      expect(
        find.text(
          'No hay tantas piezas disponibles. Elige una cantidad menor.',
        ),
        findsOneWidget,
      );
      expect(find.text('Resumen del acuerdo'), findsOneWidget);
      expect(find.text('Campus universitario · Biblioteca'), findsOneWidget);
      expect(_button(tester, 'order-create').enabled, isTrue);
    });

    testWidgets('si ya habia un pedido abierto, se abre ese', (tester) async {
      final h = _Harness(tester, orders: FakeOrderRepository());
      await h.open(AppRoutes.conversation('c1'));
      await h.tap(find.byKey(const Key('chat-summarize')));
      await h.fillIn();
      // Otro dispositivo lo creo mientras tanto.
      h.orders
        ..stored.add(sampleOrder())
        ..createFailure = const ApiFailure(
          code: 'orders.already_open',
          message: 'Ya hay un pedido abierto en esta conversación.',
        );

      await h.tap(find.byKey(const Key('order-create')));

      expect(find.text('Tu pedido'), findsOneWidget);
      expect(find.text('#MS-1001'), findsOneWidget);
    });

    testWidgets('la X cierra el resumen y vuelve al chat', (tester) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.conversation('c1'));
      await h.tap(find.byKey(const Key('chat-summarize')));

      await h.tap(find.byKey(const Key('order-summary-close')));

      expect(find.text('Resumen del acuerdo'), findsNothing);
      expect(find.text('¿Ya se pusieron de acuerdo?'), findsOneWidget);
    });
  });

  group('aviso del chat (HU-23)', () {
    testWidgets(
      'con un pedido abierto muestra su numero y Ver pedido lo abre',
      (tester) async {
        final h = _Harness(
          tester,
          orders: FakeOrderRepository(orders: [sampleOrder()]),
        );
        await h.open(AppRoutes.conversation('c1'));

        expect(find.text('Pedido #MS-1001 · Pendiente'), findsOneWidget);
        expect(find.byKey(const Key('chat-summarize')), findsNothing);
        await h.tap(find.byKey(const Key('chat-open-order')));

        expect(find.text('Tu pedido'), findsOneWidget);
      },
    );

    testWidgets('un pedido cancelado no cuenta: vuelve a Resumir acuerdo', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [sampleOrder(status: OrderStatus.cancelled)],
        ),
      );
      await h.open(AppRoutes.conversation('c1'));

      expect(find.text('¿Ya se pusieron de acuerdo?'), findsOneWidget);
      expect(find.byKey(const Key('chat-summarize')), findsOneWidget);
    });

    testWidgets('sin IA, quien vende no llena el resumen: se le avisa', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        chat: FakeChatRepository(
          conversationValue: const Conversation(
            id: 'c1',
            role: ChatRole.seller,
            counterpart: ChatCounterpart(id: myId, name: 'Ana Sofía Ramírez'),
            context: ChatContext(
              id: 'p1',
              title: 'Calculadora Casio fx-991ES Plus',
              available: true,
              priceCents: 45000,
            ),
          ),
        ),
      );
      await h.open(AppRoutes.conversation('c1'));

      await h.tap(find.byKey(const Key('chat-summarize')));

      expect(find.text('Resumen del acuerdo'), findsNothing);
      expect(
        find.text('La IA no está disponible ahora. Inténtalo más tarde.'),
        findsOneWidget,
      );
    });
  });

  group('Tu pedido (Pedido-pago, HU-23)', () {
    testWidgets('pendiente, transferencia deshabilitada y efectivo elegido', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [sampleOrder()]),
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.bySemanticsLabel('Estado del pedido: Pendiente'), findsOne);
      expect(find.text('Vende Valeria Cruz'), findsOneWidget);
      expect(find.text('Valeria aún no registra su cuenta'), findsOneWidget);
      expect(find.text('Siempre disponible'), findsOneWidget);
      expect(find.text('ASÍ FUNCIONA'), findsOneWidget);
      expect(
        find.text('Los dos confirman la entrega y se completa tu pedido'),
        findsOneWidget,
      );
      final transfer = tester.widget<Opacity>(
        find.descendant(
          of: find.byKey(const Key('order-pay-transfer')),
          matching: find.byType(Opacity),
        ),
      );
      expect(transfer.opacity, 0.55);
    });

    testWidgets('Confirmar pago en efectivo lo registra', (tester) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [sampleOrder()]),
      );
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-pay-cash-confirm')));

      expect(h.orders.paid, ['o1']);
      expect(find.text('Listo: pagas en efectivo al recibir.'), findsOneWidget);
      expect(find.byKey(const Key('order-back-to-chat')), findsOneWidget);
      expect(find.byKey(const Key('order-pay-cash-confirm')), findsNothing);
    });

    testWidgets('si falla el pago, avisa y se puede intentar de nuevo', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [sampleOrder()])
          ..payFailure = const ApiFailure(
            code: 'orders.not_pending',
            message: 'Este pedido ya no está pendiente.',
          ),
      );
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-pay-cash-confirm')));

      expect(find.text('Este pedido ya no está pendiente.'), findsOneWidget);
      expect(_button(tester, 'order-pay-cash-confirm').enabled, isTrue);
    });

    testWidgets('quien vende ve Tu venta y como le pagaran', (tester) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [sampleOrder(isBuyer: false, paysCash: true)],
        ),
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.text('Tu venta'), findsOneWidget);
      expect(find.text('Compra Ana Sofía Ramírez'), findsOneWidget);
      expect(
        find.text(
          'Ana pagará en efectivo al recibir. Acepta el pedido para apartar '
          'la pieza.',
        ),
        findsOneWidget,
      );
      expect(find.text('¿Cómo quieres pagar?'), findsNothing);
    });

    testWidgets('Ayuda explica el pedido', (tester) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [sampleOrder()]),
      );
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-help-button')));

      expect(find.text('¿Cómo funciona tu pedido?'), findsOneWidget);
    });
  });

  group('Aceptar y actualizar mis pedidos (HU-24)', () {
    testWidgets('quien vende acepta un pedido con el pago elegido', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [sampleOrder(isBuyer: false, paysCash: true)],
        ),
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.text('Rechazar pedido'), findsOneWidget);
      await h.tap(find.byKey(const Key('order-accept')));

      expect(h.orders.accepted, ['o1']);
      expect(find.text('Pedido aceptado. Le avisamos a Ana.'), findsOneWidget);
      expect(find.bySemanticsLabel('Estado del pedido: Confirmado'), findsOne);
      expect(find.text('Marcar como entregado'), findsOneWidget);
      expect(find.text('Cancelar pedido'), findsOneWidget);
    });

    testWidgets('sin pago elegido, Aceptar sale deshabilitado y lo explica', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [sampleOrder(isBuyer: false)]),
      );
      await h.open(AppRoutes.order('o1'));

      expect(_button(tester, 'order-accept').enabled, isFalse);
      expect(
        find.text(
          'Ana aún no elige cómo pagar. Podrás aceptar el pedido cuando lo '
          'elija.',
        ),
        findsOneWidget,
      );
      expect(h.orders.accepted, isEmpty);
    });

    testWidgets('rechazar pide un motivo de la lista de quien vende', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [sampleOrder(isBuyer: false, paysCash: true)],
        ),
      );
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-cancel')));

      expect(find.byKey(const Key('order-cancel-reasons')), findsOneWidget);
      expect(find.text('Ya no tengo el producto'), findsOneWidget);
      expect(find.text('Ya no lo necesito'), findsNothing);
      await h.pick('Ya no tengo el producto');

      expect(h.orders.cancelled, [('o1', CancelReason.unavailable)]);
      expect(find.text('Rechazaste el pedido.'), findsOneWidget);
      expect(
        find.text('Cancelaste el pedido: Ya no tengo el producto.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-cancel')), findsNothing);
      expect(find.byKey(const Key('order-back-to-chat')), findsOneWidget);
    });

    testWidgets('quien compra cancela con su propia lista de motivos', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [sampleOrder(paysCash: true, status: OrderStatus.confirmed)],
        ),
      );
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-cancel')));

      expect(find.text('Ya no lo necesito'), findsOneWidget);
      expect(find.text('Ya no tengo el producto'), findsNothing);
      await h.pick('No puedo en la fecha acordada');

      expect(h.orders.cancelled, [('o1', CancelReason.schedule)]);
      expect(find.text('Cancelaste el pedido.'), findsOneWidget);
    });

    testWidgets('confirmar la entrega deja esperando a la otra parte', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [sampleOrder(paysCash: true, status: OrderStatus.confirmed)],
        ),
      );
      await h.open(AppRoutes.order('o1'));

      expect(
        find.text('Revisa el producto antes de confirmar la entrega.'),
        findsOneWidget,
      );
      await h.tap(find.byKey(const Key('order-handover')));

      expect(h.orders.handovers, ['o1']);
      expect(find.text('Listo: confirmaste la entrega.'), findsOneWidget);
      expect(
        find.text('Ya confirmaste la entrega. Falta que Valeria la confirme.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-handover')), findsNothing);
    });

    testWidgets('si la otra parte ya confirmo, completar cierra el pedido', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [
            sampleOrder(
              isBuyer: false,
              paysCash: true,
              status: OrderStatus.confirmed,
              buyerConfirmed: true,
            ),
          ],
        ),
      );
      await h.open(AppRoutes.order('o1'));

      expect(
        find.text('Ana confirmó que lo recibió. Confirma que lo entregaste.'),
        findsOneWidget,
      );
      await h.tap(find.byKey(const Key('order-handover')));

      expect(find.bySemanticsLabel('Estado del pedido: Completado'), findsOne);
      expect(
        find.text('Pedido completado. ¡Gracias por usar Musubi!'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-cancel')), findsNothing);
    });

    testWidgets('si la API rechaza la accion, avisa y se puede reintentar', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders:
            FakeOrderRepository(
                orders: [sampleOrder(isBuyer: false, paysCash: true)],
              )
              ..actionFailure = const ApiFailure(
                code: 'orders.not_enough_stock',
                message:
                    'No hay tantas piezas disponibles. Elige una cantidad '
                    'menor.',
              ),
      );
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-accept')));

      expect(
        find.text(
          'No hay tantas piezas disponibles. Elige una cantidad menor.',
        ),
        findsOneWidget,
      );
      expect(_button(tester, 'order-accept').enabled, isTrue);
      expect(find.bySemanticsLabel('Estado del pedido: Pendiente'), findsOne);
    });

    testWidgets('un pedido cancelado dice quien y por que', (tester) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [
            sampleOrder(
              status: OrderStatus.cancelled,
              cancellation: const OrderCancellation(
                byBuyer: false,
                reason: CancelReason.noShow,
              ),
            ),
          ],
        ),
      );
      await h.open(AppRoutes.order('o1'));

      expect(
        find.text('Valeria canceló el pedido: La otra persona no llegó.'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Estado del pedido: Cancelado'), findsOne);
      expect(find.byKey(const Key('order-cancel')), findsNothing);
    });
  });
}
