import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/app/musubi_app.dart';
import 'package:musubi_app/app/router.dart';
import 'package:musubi_app/app/splash/brand_splash.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/widgets/musubi_snack.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/listings/presentation/listings_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/purchase_requests/presentation/wanted_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_listings_repository.dart';
import '../../helpers/fake_notifications.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/fake_wanted.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 6, 21);

/// La app con sesion, el chat `c1`, el pedido `o1` y los avisos falsos.
class _Harness {
  new(
    this.tester, {
    List<AppNotification>? items,
    FakePushService? push,
    bool asked = false,
    FakeWantedRepository? wanted,
  }) : notifications = FakeNotificationRepository(items: items),
       wanted = wanted ?? FakeWantedRepository(),
       push = push ?? FakePushService(),
       ask = FakePushAskStore(wasAsked: asked);

  final WidgetTester tester;
  final FakeNotificationRepository notifications;
  final FakePushService push;
  final FakePushAskStore ask;
  final FakeWantedRepository wanted;
  final chat = FakeChatRepository();
  late ProviderContainer container;

  Future<void> open(String location) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
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
          chatRepositoryProvider.overrideWithValue(chat),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          orderRepositoryProvider.overrideWithValue(
            FakeOrderRepository(orders: [sampleOrder()]),
          ),
          notificationRepositoryProvider.overrideWithValue(notifications),
          pushServiceProvider.overrideWithValue(push),
          pushAskStoreProvider.overrideWithValue(ask),
          wantedRepositoryProvider.overrideWithValue(wanted),
          listingsRepositoryProvider.overrideWithValue(
            FakeListingsRepository(),
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

  String get here => currentPath(container.read(routerProvider));
}

void main() {
  group('Notificaciones (HU-31)', () {
    testWidgets('agrupa en Hoy y Ayer, marca los no leidos y filtra por '
        'pestana', (tester) async {
      final h = _Harness(
        tester,
        items: [
          sampleNotification(),
          sampleNotification(
            id: 'n2',
            type: 'request_expiring',
            category: 'requests',
            title: 'Tu solicitud vence mañana',
            body: 'Física Universitaria. ¿Quieres extender la fecha?',
            target: NotificationTarget.wanted,
            targetId: 'w1',
            read: true,
            createdAt: DateTime.utc(2026, 11, 5, 18),
          ),
        ],
      );
      await h.open(AppRoutes.notifications);

      expect(find.text('HOY'), findsOneWidget);
      expect(find.text('AYER'), findsOneWidget);
      expect(find.text('Tienes un pedido nuevo'), findsOneWidget);
      expect(find.text('ayer'), findsOneWidget);
      expect(find.byKey(const Key('notification-unread')), findsOneWidget);

      await h.tap(find.byKey(const Key('notifications-tab-requests')));

      expect(h.notifications.listed.last, NotificationTab.requests);
      expect(find.text('Tienes un pedido nuevo'), findsNothing);
      expect(find.text('Tu solicitud vence mañana'), findsOneWidget);
    });

    testWidgets('tocar un aviso lo marca leido y abre el pedido', (
      tester,
    ) async {
      final h = _Harness(tester, items: [sampleNotification()]);
      await h.open(AppRoutes.notifications);

      await h.tap(find.byKey(const Key('notification-n1')));

      expect(h.notifications.read, ['n1']);
      expect(h.here, AppRoutes.order('o1'));
    });

    // HU-30: el aviso de una oferta abre esa solicitud con sus ofertas.
    testWidgets('una oferta abre esa solicitud en Mis solicitudes', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        items: [
          sampleNotification(
            type: 'offer_received',
            category: 'requests',
            title: 'Alguien tiene lo que buscas',
            target: NotificationTarget.wanted,
            targetId: 'w2',
          ),
        ],
        wanted: FakeWantedRepository(
          mine: [
            sampleWanted(),
            sampleWanted(id: 'w2', title: 'Bata de laboratorio', offers: 1),
          ],
        ),
      );
      await h.open(AppRoutes.notifications);

      await h.tap(find.byKey(const Key('notification-n1')));

      expect(h.here, AppRoutes.myWanted);
      expect(find.text('Bata de laboratorio'), findsWidgets);
      expect(find.text('Calculadora Casio fx-991ES Plus'), findsNothing);
    });

    // HU-19: el aviso de una solicitud compatible abre "Yo tengo este
    // producto".
    testWidgets('una solicitud compatible abre Yo tengo este producto', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        items: [
          sampleNotification(
            type: 'wanted_match',
            category: 'matches',
            title: 'Hay una solicitud compatible con tu producto',
            body:
                'Fernanda busca Bata de laboratorio talla M. Tu publicación '
                '«Bata blanca» coincide.',
            target: NotificationTarget.wantedBoard,
            targetId: 'r-bata',
          ),
        ],
        wanted: FakeWantedRepository(board: [boardWanted()]),
      );
      await h.open(AppRoutes.notifications);

      await h.tap(find.byKey(const Key('notification-n1')));

      expect(h.here, AppRoutes.wanted);
      expect(h.wanted.gets, ['r-bata']);
      expect(find.byKey(const Key('offer-send')), findsOneWidget);
    });

    testWidgets('si la solicitud ya no esta activa, lo dice', (tester) async {
      final h = _Harness(
        tester,
        items: [
          sampleNotification(
            type: 'wanted_match',
            category: 'matches',
            target: NotificationTarget.wantedBoard,
            targetId: 'cerrada',
          ),
        ],
      );
      await h.open(AppRoutes.notifications);

      await h.tap(find.byKey(const Key('notification-n1')));

      expect(h.here, AppRoutes.wanted);
      expect(find.text('Esta solicitud ya no está activa.'), findsOneWidget);
      expect(find.byKey(const Key('offer-send')), findsNothing);
    });

    // HU-30: "Esta solicitud ya no está activa" no abre nada.
    testWidgets('un aviso sin destino se queda en Notificaciones', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        items: [
          sampleNotification(
            type: 'offer_closed',
            category: 'requests',
            title: 'Esta solicitud ya no está activa',
            target: NotificationTarget.unknown,
            targetId: '',
          ),
        ],
      );
      await h.open(AppRoutes.notifications);

      await h.tap(find.byKey(const Key('notification-n1')));

      expect(h.here, AppRoutes.notifications);
      expect(h.notifications.read, ['n1']);
    });

    testWidgets('Marcar leidas las marca todas', (tester) async {
      final h = _Harness(
        tester,
        items: [
          sampleNotification(),
          sampleNotification(id: 'n2'),
        ],
      );
      await h.open(AppRoutes.notifications);

      await h.tap(find.byKey(const Key('notifications-read-all')));

      expect(h.notifications.readAll, 1);
      expect(find.byKey(const Key('notification-unread')), findsNothing);
    });

    testWidgets('sin avisos lo dice', (tester) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.notifications);

      expect(find.text('Sin avisos por ahora'), findsOneWidget);
    });

    testWidgets('la campana de Inicio cuenta los no leidos', (tester) async {
      final h = _Harness(
        tester,
        items: [
          sampleNotification(),
          sampleNotification(id: 'n2'),
          sampleNotification(id: 'n3', read: true),
        ],
      );
      await h.open(AppRoutes.home);

      expect(
        find.descendant(
          of: find.byKey(const Key('home-bell-count')),
          matching: find.text('2'),
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Notificaciones, 2 nuevas'), findsOneWidget);
    });
  });

  group('Avisos push (HU-31)', () {
    testWidgets('con permiso, al abrir la app registra el telefono', (
      tester,
    ) async {
      final h = _Harness(tester, push: FakePushService(allowed: true));
      await h.open(AppRoutes.home);

      expect(h.push.registers, 1);
      expect(h.notifications.devices, ['fid-telefono']);

      h.push.installation('fid-nuevo');
      await tester.pumpAndSettle();
      expect(h.notifications.devices.last, 'fid-nuevo');
    });

    testWidgets('sin permiso no registra ni pregunta al abrir la app', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.home);

      expect(h.push.registers, 0);
      expect(h.push.permissionRequests, 0);
      expect(find.text('¿Te avisamos?'), findsNothing);
    });

    testWidgets('sin Firebase la app sigue igual', (tester) async {
      final h = _Harness(tester, push: FakePushService(available: false));
      await h.open(AppRoutes.conversation('c1'));

      await tester.enterText(find.byType(TextField), 'Hola');
      await h.tap(find.bySemanticsLabel('Enviar'));

      expect(h.chat.sent, ['Hola']);
      expect(find.text('¿Te avisamos?'), findsNothing);
    });

    testWidgets('al mandar el primer mensaje pregunta una vez; si acepta, '
        'pide el permiso y registra', (tester) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.conversation('c1'));

      await tester.enterText(find.byType(TextField), 'Hola');
      await h.tap(find.bySemanticsLabel('Enviar'));

      expect(find.text('¿Te avisamos?'), findsOneWidget);
      await h.tap(find.byKey(const Key('push-ask-yes')));
      expect(h.push.permissionRequests, 1);
      expect(h.notifications.devices, ['fid-telefono']);
      expect(h.ask.wasAsked, isTrue);

      await tester.enterText(find.byType(TextField), 'Otro');
      await h.tap(find.bySemanticsLabel('Enviar'));
      expect(find.text('¿Te avisamos?'), findsNothing);
    });

    testWidgets('"Ahora no" no pide el permiso ni vuelve a preguntar', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.conversation('c1'));

      await tester.enterText(find.byType(TextField), 'Hola');
      await h.tap(find.bySemanticsLabel('Enviar'));
      await h.tap(find.text('Ahora no'));

      expect(h.push.permissionRequests, 0);
      expect(h.ask.wasAsked, isTrue);
    });

    testWidgets('tocar un push abre el chat y marca leido el aviso', (
      tester,
    ) async {
      final h = _Harness(tester, push: FakePushService(allowed: true));
      await h.open(AppRoutes.home);

      h.push.tap(
        const PushOpen(
          type: 'offer_accepted',
          target: NotificationTarget.conversation,
          targetId: 'c1',
          notificationId: 'n7',
        ),
      );
      await tester.pumpAndSettle();

      expect(h.here, AppRoutes.conversation('c1'));
      expect(h.notifications.read, ['n7']);
    });

    testWidgets('con la app abierta el push sale como aviso con Ver, salvo en '
        'ese mismo chat', (tester) async {
      final h = _Harness(tester, push: FakePushService(allowed: true));
      await h.open(AppRoutes.home);

      h.push.arrive(
        const PushOpen(
          type: 'order_created',
          target: NotificationTarget.order,
          targetId: 'o1',
          title: 'Tienes un pedido nuevo',
          body: 'Ana pidió 1 × Calculadora.',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Tienes un pedido nuevo: Ana pidió 1 × Calculadora.'),
        findsOneWidget,
      );
      // El snack vive en el Scaffold del shell, debajo del de Inicio en la
      // prueba de toques: se usa su accion directamente.
      final snack = tester.widget<MusubiSnack>(find.byType(MusubiSnack));
      expect(snack.actionLabel, 'Ver');
      snack.onAction!();
      await tester.pumpAndSettle();
      expect(h.here, AppRoutes.order('o1'));

      h.container.read(routerProvider).go(AppRoutes.conversation('c1'));
      await tester.pumpAndSettle();
      h.push.arrive(
        const PushOpen(
          type: 'message',
          target: NotificationTarget.conversation,
          targetId: 'c1',
          title: 'Valeria',
          body: 'Sí, sigue disponible',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Valeria: Sí, sigue disponible'), findsNothing);
    });

    testWidgets('al cerrar sesion da de baja el telefono', (tester) async {
      final h = _Harness(tester, push: FakePushService(allowed: true));
      await h.open(AppRoutes.home);

      await h.container.read(sessionControllerProvider.notifier).signOut();
      await tester.pumpAndSettle();

      expect(h.push.unregisters, 1);
    });
  });
}
