import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/platform/device_calendar.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/genai/presentation/agreement_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/delivery_actions.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

import '../../helpers/fake_agreements.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_device_calendar.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

// La entrega de `sampleOrder` es el 7-Nov a las 19:00 UTC.
final _delivery = DateTime.utc(2026, 11, 7, 19);
final DateTime _oneHourBefore = _delivery.subtract(const Duration(hours: 1));
final DateTime _threeHoursBefore = _delivery.subtract(const Duration(hours: 3));

/// La app completa con el router real, la sesion abierta y los pedidos falsos.
class _Harness {
  new(this.tester, {required this.orders, required this.now});

  final WidgetTester tester;
  final FakeOrderRepository orders;
  final DateTime now;
  final calendar = FakeDeviceCalendar();

  Future<void> open(String location) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([const HomeFeed()]),
          ),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          orderRepositoryProvider.overrideWithValue(orders),
          deviceCalendarProvider.overrideWithValue(calendar),
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
    ProviderScope.containerOf(tester.element(find.byType(MusubiApp)))
        .read(routerProvider)
        .go(location);
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}

Order _confirmed({bool isBuyer = true, bool buyerArrived = false}) =>
    sampleOrder(
      isBuyer: isBuyer,
      paysCash: true,
      status: OrderStatus.confirmed,
      buyerArrived: buyerArrived,
    );

void main() {
  group('deliveryWhen (HU-62)', () {
    final now = DateTime(2026, 11, 7, 9);

    test('hoy, mañana u otro día, con "la" para la 1', () {
      expect(
        deliveryWhen(DateTime(2026, 11, 7, 13), now),
        'Hoy a la 1:00 p. m.',
      );
      expect(
        deliveryWhen(DateTime(2026, 11, 8, 9, 30), now),
        'Mañana a las 9:30 a. m.',
      );
      expect(
        deliveryWhen(DateTime(2026, 11, 10, 18), now),
        'mar 10 nov a las 6:00 p. m.',
      );
    });

    test('el evento del calendario dura 30 minutos en el punto', () {
      final event = deliveryEvent(sampleOrder());

      expect(
        event.title,
        'Entrega de Calculadora Casio fx-991ES Plus · Musubi',
      );
      expect(
        (event.start, event.end),
        (_delivery, _delivery.add(const Duration(minutes: 30))),
      );
      expect(event.location, 'Biblioteca, Planta baja');
      expect(event.description, contains('#MS-1001 con Valeria'));
    });

    test('Ya llegué solo confirmado, sin avisar y desde 2 horas antes', () {
      final order = _confirmed();
      final early = _delivery.subtract(const Duration(hours: 2, minutes: 1));

      expect(order.canSayArrived(_oneHourBefore), isTrue);
      expect(
        order.canSayArrived(_delivery.subtract(Order.arrivalLead)),
        isTrue,
      );
      expect(order.canSayArrived(early), isFalse);
      expect(sampleOrder().canSayArrived(_oneHourBefore), isFalse);
      expect(
        _confirmed(buyerArrived: true).canSayArrived(_oneHourBefore),
        isFalse,
      );
    });
  });

  group('PlatformDeviceCalendar (HU-62)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('musubi/calendar');

    test('manda el evento al canal y sin app regresa false', () async {
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return false;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final opened = await const PlatformDeviceCalendar().add(
        deliveryEvent(sampleOrder()),
      );

      expect(opened, isFalse);
      expect(calls.single.method, 'addEvent');
      expect(calls.single.arguments, {
        'title': 'Entrega de Calculadora Casio fx-991ES Plus · Musubi',
        'begin': _delivery.millisecondsSinceEpoch,
        'end': _delivery
            .add(const Duration(minutes: 30))
            .millisecondsSinceEpoch,
        'location': 'Biblioteca, Planta baja',
        'description':
            'Pedido #MS-1001 con Valeria. Ábrelo en Musubi para '
            'ver los detalles.',
      });
    });

    test('sin el canal (pruebas o iOS) regresa false', () async {
      expect(
        await const PlatformDeviceCalendar().add(deliveryEvent(sampleOrder())),
        isFalse,
      );
    });
  });

  group('Tu pedido: entrega (HU-62)', () {
    testWidgets('una hora antes, Ya llegué avisa y queda el estado', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [_confirmed()]),
        now: _oneHourBefore,
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.byKey(const Key('order-delivery-card')), findsOneWidget);
      expect(find.text('En Biblioteca con Valeria'), findsOneWidget);
      await h.tap(find.byKey(const Key('order-arrived')));

      expect(h.orders.arrivals, ['o1']);
      expect(
        find.text('Le avisamos a Valeria que ya llegaste.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-arrived')), findsNothing);
      expect(
        find.text('Ya le avisaste a Valeria que llegaste.'),
        findsOneWidget,
      );
    });

    testWidgets('tres horas antes no hay Ya llegué, pero sí el calendario', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [_confirmed()]),
        now: _threeHoursBefore,
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.byKey(const Key('order-arrived')), findsNothing);
      await h.tap(find.byKey(const Key('order-add-calendar')));

      final event = h.calendar.events.single;
      expect(event.start, _delivery);
      expect(event.location, 'Biblioteca, Planta baja');
    });

    testWidgets('sin app de calendario, lo avisa', (tester) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [_confirmed()]),
        now: _threeHoursBefore,
      );
      h.calendar.result = false;
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-add-calendar')));

      expect(
        find.text('No encontramos una app de calendario en tu teléfono.'),
        findsOneWidget,
      );
    });

    testWidgets('quien vende ve que Ana ya llegó', (tester) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(
          orders: [_confirmed(isBuyer: false, buyerArrived: true)],
        ),
        now: _oneHourBefore,
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.text('Ana ya llegó a Biblioteca.'), findsOneWidget);
      expect(find.byKey(const Key('order-arrived')), findsOneWidget);
    });

    testWidgets('si la API lo rechaza, avisa y el botón sigue', (tester) async {
      final orders = FakeOrderRepository(orders: [_confirmed()])
        ..actionFailure = const ApiFailure(
          code: 'orders.arrival_too_early',
          message:
              'Todavía falta para la entrega. Avisa cuando ya estés en '
              'el punto.',
        );
      final h = _Harness(tester, orders: orders, now: _oneHourBefore);
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-arrived')));

      expect(
        find.text(
          'Todavía falta para la entrega. Avisa cuando ya estés en el punto.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-arrived')), findsOneWidget);
    });

    testWidgets('un pedido pendiente no tiene la tarjeta de entrega', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [sampleOrder()]),
        now: _oneHourBefore,
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.byKey(const Key('order-delivery-card')), findsNothing);
    });
  });

  group('chat: Ya llegué (HU-62)', () {
    testWidgets('desde 2 horas antes sale la franja y avisa', (tester) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [_confirmed()]),
        now: _oneHourBefore,
      );
      await h.open(AppRoutes.conversation('c1'));

      expect(find.byKey(const Key('chat-arrival-bar')), findsOneWidget);
      await h.tap(find.byKey(const Key('chat-arrived')));

      expect(h.orders.arrivals, ['o1']);
      expect(find.byKey(const Key('chat-arrived')), findsNothing);
      expect(
        find.text('Ya avisaste que llegaste a Biblioteca.'),
        findsOneWidget,
      );
    });

    testWidgets('tres horas antes no sale', (tester) async {
      final h = _Harness(
        tester,
        orders: FakeOrderRepository(orders: [_confirmed()]),
        now: _threeHoursBefore,
      );
      await h.open(AppRoutes.conversation('c1'));

      expect(find.byKey(const Key('chat-arrival-bar')), findsNothing);
    });
  });
}
