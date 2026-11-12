import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/orders/data/http_order_repository.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';

import '../../helpers/fake_http_adapter.dart';

/// `OrderResponse` como el fixture `order.json` de musubi-api.
Map<String, Object?> orderJson({
  Map<String, Object?>? payment,
  String role = 'buyer',
  String status = 'pending',
  Map<String, Object?> handover = const {
    'buyerConfirmedAt': null,
    'sellerConfirmedAt': null,
  },
  Map<String, Object?>? cancellation,
}) => {
  'id': '6716a00000000000000000a1',
  'number': 'MS-1001',
  'status': status,
  'role': role,
  'conversationId': '6716a00000000000000000c1',
  'item': {
    'source': 'product',
    'sourceId': '6716a0000000000000000099',
    'productId': '6716a0000000000000000099',
    'title': 'Calculadora científica Casio fx-991ES Plus',
    'photo':
        '/media/products/6716a0000000000000000001/'
        '0123456789abcdef0123456789abcdef.webp',
    'priceCents': 50000,
    'quantity': 2,
    'totalCents': 100000,
  },
  'buyer': {'id': '6716a0000000000000000002', 'name': 'Ana Sofía Ramírez'},
  'seller': {'id': '6716a0000000000000000001', 'name': 'Diego Hernández'},
  'delivery': {
    'point': 'biblioteca',
    'pointName': 'Biblioteca',
    'detail': 'Planta baja, junto a la entrada',
    'at': '2026-11-11T19:00:00Z',
  },
  'payment': payment,
  'transferAvailable': false,
  'createdAt': '2026-11-10T18:00:00Z',
  'handover': handover,
  'cancellation': cancellation,
  'updatedAt': '2026-11-10T18:05:00Z',
};

// HU-23: el repositorio habla las filas "M-08" de musubi-api.
void main() {
  late FakeHttpAdapter adapter;
  late HttpOrderRepository repository;

  void serve(ResponseBody Function(RequestOptions options) response) {
    adapter = FakeHttpAdapter((options) async => response(options));
    repository = HttpOrderRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
      Uri.parse('https://api.musubi.example'),
    );
  }

  test('los puntos de entrega traen el recomendado', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'items': [
          {'slug': 'biblioteca', 'name': 'Biblioteca', 'suggested': false},
          {
            'slug': 'tecnologias-informacion',
            'name': 'Tecnologías de la Información',
            'suggested': true,
          },
        ],
      }),
    );

    final points = await repository.meetingPoints();

    expect(adapter.requests.single.path, ApiPaths.meetingPoints);
    expect(points.map((p) => p.slug), [
      'biblioteca',
      'tecnologias-informacion',
    ]);
    expect(points.map((p) => p.suggested), [false, true]);
  });

  test('crear manda el contrato y mapea el pedido', () async {
    serve((_) => FakeHttpAdapter.json(orderJson(), status: 201));

    final order = await repository.create(
      NewOrder(
        conversationId: 'c1',
        quantity: 2,
        meetingPoint: 'biblioteca',
        detail: 'Planta baja, junto a la entrada',
        // 1:00 p. m. del campus (UTC-6).
        deliveryAt: DateTime.utc(2026, 11, 11, 19),
      ),
    );

    final sent = adapter.requests.single;
    expect((sent.method, sent.path), ('POST', ApiPaths.orders));
    expect(sent.data, {
      'conversationId': 'c1',
      'quantity': 2,
      'meetingPoint': 'biblioteca',
      'meetingDetail': 'Planta baja, junto a la entrada',
      'deliveryAt': '2026-11-11T19:00:00.000Z',
    });
    expect(order.number, 'MS-1001');
    expect(order.status, OrderStatus.pending);
    expect(order.isBuyer, isTrue);
    expect(order.item.quantity, 2);
    expect(order.item.totalCents, 100000);
    expect(
      order.item.photoUrl,
      'https://api.musubi.example/media/products/6716a0000000000000000001/'
      '0123456789abcdef0123456789abcdef.webp',
    );
    expect(order.pointName, 'Biblioteca');
    expect(order.detail, 'Planta baja, junto a la entrada');
    expect(order.deliveryAt, DateTime.utc(2026, 11, 11, 19));
    expect(order.paysCash, isFalse);
    expect(order.transferAvailable, isFalse);
  });

  test('sin detalle no manda meetingDetail', () async {
    serve((_) => FakeHttpAdapter.json(orderJson(), status: 201));

    await repository.create(
      NewOrder(
        conversationId: 'c1',
        quantity: 1,
        meetingPoint: 'biblioteca',
        deliveryAt: DateTime.utc(2026, 11, 11, 19),
      ),
    );

    expect(
      (adapter.requests.single.data as Map).containsKey('meetingDetail'),
      isFalse,
    );
  });

  test(
    'un pedido abierto ya existente llega como orders.already_open',
    () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'code': 'orders.already_open',
          'title': 'Ya hay un pedido abierto en esta conversación.',
          'status': 409,
        }, status: 409),
      );

      await expectLater(
        repository.create(
          NewOrder(
            conversationId: 'c1',
            quantity: 1,
            meetingPoint: 'biblioteca',
            deliveryAt: DateTime.utc(2026, 11, 11, 19),
          ),
        ),
        throwsA(
          isA<ApiFailure>()
              .having((f) => f.code, 'code', 'orders.already_open')
              .having(
                (f) => f.message,
                'message',
                'Ya hay un pedido abierto en esta conversación.',
              ),
        ),
      );
    },
  );

  test('los de una conversacion piden por conversationId', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'items': [orderJson(role: 'seller', status: 'cancelled')],
      }),
    );

    final orders = await repository.byConversation('c1');

    expect(adapter.requests.single.path, ApiPaths.orders);
    expect(adapter.requests.single.queryParameters, {'conversationId': 'c1'});
    expect(orders.single.isBuyer, isFalse);
    expect(orders.single.status, OrderStatus.cancelled);
  });

  test('pagar en efectivo manda cash y queda registrado', () async {
    serve(
      (_) => FakeHttpAdapter.json(
        orderJson(
          payment: {'method': 'cash', 'chosenAt': '2026-11-10T18:05:00Z'},
        ),
      ),
    );

    final order = await repository.payCash('o1');

    final sent = adapter.requests.single;
    expect((sent.method, sent.path), ('PUT', ApiPaths.orderPayment('o1')));
    expect(sent.data, {'method': 'cash'});
    expect(order.paysCash, isTrue);
  });

  test(
    'los estados se leen de la API y abiertos son pendiente y confirmado',
    () {
      expect(OrderStatus.parse('confirmed'), OrderStatus.confirmed);
      expect(OrderStatus.parse('completed'), OrderStatus.completed);
      expect(OrderStatus.parse('raro'), OrderStatus.pending);
      expect(OrderStatus.values.where((s) => s.open), [
        OrderStatus.pending,
        OrderStatus.confirmed,
      ]);
    },
  );

  test('aceptar y confirmar la entrega van por POST sin cuerpo', () async {
    serve(
      (_) => FakeHttpAdapter.json(
        orderJson(
          status: 'confirmed',
          role: 'seller',
          handover: {
            'buyerConfirmedAt': null,
            'sellerConfirmedAt': '2026-11-11T19:10:00Z',
          },
        ),
      ),
    );

    await repository.accept('o1');
    final order = await repository.confirmHandover('o1');

    expect(
      [for (final r in adapter.requests) (r.method, r.path, r.data)],
      [
        ('POST', ApiPaths.orderAccept('o1'), null),
        ('POST', ApiPaths.orderHandover('o1'), null),
      ],
    );
    expect((order.sellerConfirmed, order.buyerConfirmed), (true, false));
    expect(order.iConfirmed, isTrue);
  });

  test('cancelar manda el codigo del motivo y lee quien cancelo', () async {
    serve(
      (_) => FakeHttpAdapter.json(
        orderJson(
          status: 'cancelled',
          cancellation: {
            'by': 'seller',
            'reason': 'no_show',
            'at': '2026-11-11T19:10:00Z',
          },
        ),
      ),
    );

    final order = await repository.cancel('o1', CancelReason.noShow);

    final sent = adapter.requests.single;
    expect((sent.method, sent.path), ('POST', ApiPaths.orderCancel('o1')));
    expect(sent.data, {'reason': 'no_show'});
    expect(order.status, OrderStatus.cancelled);
    expect(order.cancellation?.byBuyer, isFalse);
    expect(order.cancellation?.reason, CancelReason.noShow);
  });

  test('los motivos son los de la API y cada parte tiene los suyos', () {
    expect(CancelReason.parse('account_deleted'), CancelReason.accountDeleted);
    expect(CancelReason.parse('raro'), CancelReason.other);
    expect(CancelReason.forBuyer, contains(CancelReason.changedMind));
    expect(CancelReason.forBuyer, isNot(contains(CancelReason.unavailable)));
    expect(CancelReason.forSeller, contains(CancelReason.unavailable));
    expect(
      CancelReason.forSeller,
      isNot(contains(CancelReason.accountDeleted)),
    );
  });

  test('si la API rechaza la accion, llega el mensaje en espanol', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'code': 'orders.payment_missing',
        'title': 'Espera a que elijan cómo pagar para aceptar el pedido.',
        'status': 409,
      }, status: 409),
    );

    await expectLater(
      repository.accept('o1'),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'orders.payment_missing',
        ),
      ),
    );
  });

  group('Mis pedidos (HU-25)', () {
    test('pide la pestana, el cursor y el limite, y lee la pagina', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'items': [
            orderJson(status: 'completed'),
            orderJson(status: 'cancelled'),
          ],
          'nextCursor': '6716a00000000000000000a1',
          'total': 7,
          'counts': {'active': 2, 'completed': 7, 'cancelled': 1},
        }),
      );

      final page = await repository.mine(
        tab: MyOrdersTab.completed,
        cursor: 'abc',
        limit: 2,
      );

      expect(adapter.requests.single.path, ApiPaths.myOrders);
      expect(adapter.requests.single.queryParameters, {
        'tab': 'completed',
        'cursor': 'abc',
        'limit': 2,
      });
      expect(page.items.map((o) => o.status), [
        OrderStatus.completed,
        OrderStatus.cancelled,
      ]);
      expect(page.items.first.updatedAt, DateTime.utc(2026, 11, 10, 18, 5));
      expect(page.nextCursor, '6716a00000000000000000a1');
      expect(page.total, 7);
      expect(
        (page.counts.active, page.counts.completed, page.counts.cancelled),
        (2, 7, 1),
      );
      expect(page.counts.of(MyOrdersTab.completed), 7);
    });

    test('sin pestana no manda tab (la seccion de Perfil)', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'items': <Object?>[],
          'nextCursor': null,
          'total': 0,
          'counts': {'active': 0, 'completed': 0, 'cancelled': 0},
        }),
      );

      final page = await repository.mine(limit: 3);

      expect(adapter.requests.single.queryParameters, {'limit': 3});
      expect(page.items, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('una pestana que no existe llega como ApiFailure', () async {
      serve(
        (_) => FakeHttpAdapter.json({
          'code': 'orders.invalid_tab',
          'title': 'No pudimos cargar esa lista. Actualiza la pantalla.',
          'status': 400,
        }, status: 400),
      );

      await expectLater(
        repository.mine(tab: MyOrdersTab.active),
        throwsA(
          isA<ApiFailure>().having((f) => f.code, 'code', 'orders.invalid_tab'),
        ),
      );
    });
  });
}
