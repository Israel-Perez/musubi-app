import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/notifications/data/http_notification_repository.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';

import '../../helpers/fake_http_adapter.dart';

/// `NotificationPage` como el fixture `notification-page.json` de musubi-api.
Map<String, Object?> pageJson() => {
  'items': [
    {
      'id': '6716a00000000000000000d1',
      'type': 'order_created',
      'category': 'orders',
      'title': 'Tienes un pedido nuevo',
      'body': 'Ana pidió 1 × Calculadora Casio fx-991ES Plus. Pedido #MS-1001.',
      'target': {'type': 'order', 'id': '6716a00000000000000000a1'},
      'read': false,
      'createdAt': '2026-11-11T18:00:00Z',
    },
  ],
  'unread': 1,
  'nextCursor': null,
};

// HU-31: el repositorio habla las filas "M-09" de musubi-api.
void main() {
  late FakeHttpAdapter adapter;
  late HttpNotificationRepository repository;

  void serve(ResponseBody Function(RequestOptions options) response) {
    adapter = FakeHttpAdapter((options) async => response(options));
    repository = HttpNotificationRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );
  }

  test('la lista pide la pestana y mapea el aviso', () async {
    serve((_) => FakeHttpAdapter.json(pageJson()));

    final page = await repository.list(NotificationTab.orders);

    final sent = adapter.requests.single;
    expect((sent.method, sent.path), ('GET', ApiPaths.notifications));
    expect(sent.queryParameters, {'category': 'orders'});
    expect(page.unread, 1);
    final n = page.items.single;
    expect((n.type, n.category, n.read), ('order_created', 'orders', false));
    expect(
      (n.target, n.targetId),
      (NotificationTarget.order, '6716a00000000000000000a1'),
    );
    expect(n.createdAt, DateTime.utc(2026, 11, 11, 18));
  });

  test('"Todas" no manda categoria', () async {
    serve((_) => FakeHttpAdapter.json(pageJson()));

    await repository.list(NotificationTab.all);

    expect(adapter.requests.single.queryParameters, isEmpty);
  });

  test('marcar uno, marcar todos y registrar el telefono', () async {
    serve((_) => ResponseBody.fromString('', 204));

    await repository.markRead('n1');
    await repository.markAllRead();
    await repository.registerDevice('fid-telefono');

    expect(adapter.requests.map((r) => (r.method, r.path)), [
      ('POST', ApiPaths.notificationRead('n1')),
      ('POST', ApiPaths.notificationsRead),
      ('PUT', ApiPaths.notificationDevices),
    ]);
    expect(adapter.requests.last.data, {'token': 'fid-telefono'});
  });

  test('los datos de un push dicen que abrir', () {
    final push = PushOpen.fromData(
      const {
        'type': 'message',
        'targetType': 'conversation',
        'targetId': 'c1',
        'notificationId': 'n9',
      },
      title: 'Ana',
      body: 'Hola',
    );

    expect(
      (push.type, push.target, push.targetId, push.notificationId),
      ('message', NotificationTarget.conversation, 'c1', 'n9'),
    );
    expect(routeFor(push.target, push.targetId), AppRoutes.conversation('c1'));
    expect(routeFor(NotificationTarget.order, 'o1'), AppRoutes.order('o1'));
    // HU-30 y HU-19: la solicitud del aviso.
    expect(
      routeFor(NotificationTarget.wanted, 'w1'),
      '/mis-solicitudes?solicitud=w1',
    );
    expect(routeFor(NotificationTarget.wanted, ''), AppRoutes.myWanted);
    expect(
      routeFor(NotificationTarget.wantedBoard, 'w1'),
      '/se-busca?ofrecer=w1',
    );
    expect(routeFor(NotificationTarget.wantedBoard, ''), isNull);
    expect(
      NotificationTarget.parse('wanted_board'),
      NotificationTarget.wantedBoard,
    );
    expect(NotificationTarget.parse('none'), NotificationTarget.unknown);
    expect(routeFor(NotificationTarget.unknown, 'x'), isNull);
    expect(PushOpen.fromData(const {}).target, NotificationTarget.unknown);
  });
}
