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
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/marketplace/domain/product_detail.dart';
import 'package:musubi_app/features/marketplace/presentation/comparison_providers.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/notifications/domain/notification_models.dart';
import 'package:musubi_app/features/notifications/presentation/notification_providers.dart';
import 'package:musubi_app/features/orders/data/http_reservation_repository.dart';
import 'package:musubi_app/features/orders/domain/reservation_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';
import 'package:musubi_app/features/orders/presentation/verify_buyer_screen.dart';
import 'package:musubi_app/features/profile/presentation/profile_providers.dart';
import 'package:musubi_app/features/recommendations/presentation/recommendation_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_comparison.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_profile_repository.dart';
import '../../helpers/fake_recommendations.dart';
import '../../helpers/fake_reservations.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 15, 18);

/// La camara de las pruebas: un boton por QR que "lee" la camara.
final _scans = <String>[];

Widget _camera({required ValueChanged<String> onCode, required bool torch}) =>
    Column(
      children: [
        for (final raw in _scans)
          TextButton(
            key: Key('scan-$raw'),
            onPressed: () => onCode(raw),
            child: Text(raw),
          ),
      ],
    );

ProductDetail _casio() => ProductDetail(
  id: 'p1',
  title: 'Calculadora Casio fx-991ES Plus',
  description: 'La usé un semestre.',
  categoryName: 'Calculadoras',
  priceCents: 45000,
  condition: 'used',
  stock: 1,
  status: 'active',
  photoUrls: const [],
  publishedAt: _now.subtract(const Duration(days: 2)),
  sellerId: '6716a0000000000000000001',
  sellerName: 'Valeria Cruz',
);

/// App completa con el router real, la sesion de Ana y los apartados falsos.
class _Harness {
  new(this.tester, {List<Reservation>? reservations})
    : reservations = FakeReservationRepository(reservations: reservations);

  final WidgetTester tester;
  final FakeReservationRepository reservations;
  final catalog = FakeCatalogRepository();
  late ProviderContainer container;

  Future<void> open(String location) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    catalog.details['p1'] = _casio();
    final profiles = FakeProfileRepository();
    profiles.publicProfiles['6716a0000000000000000001'] =
        FakeProfileRepository.publicSample;
    final session = chatTokens(_now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(catalog),
          profileRepositoryProvider.overrideWithValue(profiles),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          recommendationRepositoryProvider.overrideWithValue(
            FakeRecommendationRepository(),
          ),
          comparisonRepositoryProvider.overrideWithValue(
            FakeComparisonRepository(),
          ),
          orderRepositoryProvider.overrideWithValue(FakeOrderRepository()),
          reservationRepositoryProvider.overrideWithValue(reservations),
          qrCameraProvider.overrideWithValue(_camera),
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
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.tap(finder.first);
    await tester.pumpAndSettle();
  }

  String get path => currentPath(container.read(routerProvider));
}

void main() {
  setUp(_scans.clear);

  group('Las horas de "¿Cuándo pasas?"', () {
    String label(PickupSlot slot, DateTime now) =>
        '${DateUtils.isSameDay(slot.at, now) ? 'Hoy' : 'Mañana'} '
        '${slot.at.hour}:${slot.at.minute.toString().padLeft(2, '0')}';

    test('a las 9:41: hoy 13:00 y 17:00, y mañana antes de las 24 h', () {
      final now = DateTime(2026, 11, 15, 9, 41);

      expect(PickupSlots.around(now).map((s) => label(s, now)), [
        'Hoy 13:00',
        'Hoy 17:00',
        'Mañana 9:00',
      ]);
    });

    test('siempre dentro de las 24 h y de 7:00 a 21:00', () {
      for (var minutes = 0; minutes < 24 * 60; minutes += 17) {
        final now = DateTime(2026, 11, 15).add(Duration(minutes: minutes));
        final slots = PickupSlots.around(now);

        expect(slots, hasLength(3), reason: '$now');
        for (final slot in slots) {
          expect(slot.at.isAfter(now), isTrue, reason: '$now');
          expect(
            slot.at.difference(now),
            lessThanOrEqualTo(const Duration(hours: 24)),
            reason: '$now',
          );
          expect(slot.at.hour, inInclusiveRange(7, 21), reason: '$now');
        }
        expect(
          slots.map((s) => s.at).toList(),
          orderedEquals([...slots.map((s) => s.at)]..sort()),
        );
      }
    });
  });

  group('El QR y los nombres', () {
    test('solo se acepta el QR de este apartado', () {
      const id = casioReservationId;

      expect(codeFromQr('musubi:apartado:$id:482173', id), '482173');
      expect(codeFromQr(' musubi:apartado:$id:482173 ', id), '482173');
      expect(
        codeFromQr('musubi:apartado:6716a0000000000000000a09:482173', id),
        isNull,
      );
      expect(codeFromQr('musubi:apartado:$id:48217', id), isNull);
      expect(codeFromQr('https://example.com', id), isNull);
      expect(codeFromQr(null, id), isNull);
    });

    test('"Valeria C." y "482 173"', () {
      expect(shortPersonName('Valeria Cruz'), 'Valeria C.');
      expect(shortPersonName('Luis'), 'Luis');
      expect(sampleReservation().spacedCode, '482 173');
    });
  });

  group('HttpReservationRepository', () {
    final base = Uri.parse('https://api.musubi.example');
    Dio dio(FakeHttpAdapter adapter) =>
        Dio(BaseOptions(baseUrl: base.toString()))..httpClientAdapter = adapter;
    final json = {
      'id': casioReservationId,
      'number': 'AP-4821',
      'status': 'active',
      'role': 'buyer',
      'productId': 'p1',
      'title': 'Calculadora Casio fx-991ES Plus',
      'photo': '/media/products/p1/a.webp',
      'priceCents': 45000,
      'buyer': {'id': 'u1', 'name': 'Ana Sofía Ramírez'},
      'seller': {'id': 'u2', 'name': 'Valeria Cruz'},
      'pointSlug': 'biblioteca',
      'pointName': 'Biblioteca',
      'pickupAt': '2026-11-15T19:00:00Z',
      'expiresAt': '2026-11-16T18:00:00Z',
      'createdAt': '2026-11-15T18:00:00Z',
      'code': '482173',
      'qrPayload': 'musubi:apartado:$casioReservationId:482173',
      'codeAttemptsLeft': null,
      'verifiedAt': null,
      'orderId': null,
      'conversationId': 'c1',
      'cancelledBy': null,
    };

    test('lee el apartado (fixture `reservation.json`)', () {
      final r = reservationFromJson(json, base);

      expect(r.isBuyer, isTrue);
      expect(r.active, isTrue);
      expect(r.code, '482173');
      expect(r.photoUrl, 'https://api.musubi.example/media/products/p1/a.webp');
      expect(r.pickupAt, DateTime.utc(2026, 11, 15, 19));
      expect(r.sellerName, 'Valeria Cruz');
    });

    test('cada accion va a su ruta y la pestana en `?tab=`', () async {
      final adapter = FakeHttpAdapter((options) async {
        if (options.path == ApiPaths.myReservations) {
          return FakeHttpAdapter.json({
            'items': [json],
            'counts': {'bought': 2, 'sold': 1},
          });
        }
        return FakeHttpAdapter.json(json);
      });
      final repository = HttpReservationRepository(dio(adapter), base);

      await repository.create(
        productId: 'p1',
        meetingPoint: 'biblioteca',
        pickupAt: DateTime.utc(2026, 11, 15, 19),
      );
      final page = await repository.mine(ReservationTab.seller);
      await repository.get('r1');
      await repository.cancel('r1');
      await repository.verify('r1', '482173');
      await repository.complete('r1');

      expect((page.bought, page.sold, page.items.length), (2, 1, 1));
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST ${ApiPaths.reservations}',
        'GET ${ApiPaths.myReservations}',
        'GET ${ApiPaths.reservation('r1')}',
        'POST ${ApiPaths.reservationCancel('r1')}',
        'POST ${ApiPaths.reservationVerify('r1')}',
        'POST ${ApiPaths.reservationComplete('r1')}',
      ]);
      expect(adapter.requests[0].data, {
        'productId': 'p1',
        'meetingPoint': 'biblioteca',
        'pickupAt': '2026-11-15T19:00:00.000Z',
      });
      expect(adapter.requests[1].queryParameters, {'tab': 'seller'});
      expect(adapter.requests[4].data, {'code': '482173'});
    });

    test('un error de la API llega como ApiFailure con su codigo', () async {
      final adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.json({
          'code': 'reservations.limit_reached',
          'title':
              'Ya tienes un apartado activo. Recógelo o cancélalo para '
              'apartar otro.',
        }, status: 409),
      );
      final repository = HttpReservationRepository(dio(adapter), base);

      await expectLater(
        repository.create(
          productId: 'p1',
          meetingPoint: 'biblioteca',
          pickupAt: _now,
        ),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'reservations.limit_reached',
          ),
        ),
      );
    });
  });

  group('Apartar (HU-52)', () {
    testWidgets('"Apartar" del producto elige hora y punto y abre el QR', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.product('p1'));

      await h.tap(find.text('Apartar'));

      expect(find.text('Te lo guarda 24 h · Pagas al recoger'), findsOneWidget);
      expect(find.text(r'$450 · Valeria C.'), findsOneWidget);
      expect(
        find.text('Recibirás un QR y un código para recogerlo'),
        findsOneWidget,
      );

      await h.tap(find.byKey(const Key('reserve-slot-1')));
      await h.tap(find.byKey(const Key('reserve-point-cafeteria')));
      await h.tap(find.byKey(const Key('reserve-confirm')));

      final slots = PickupSlots.around(_now.toLocal());
      expect(h.reservations.created, [('p1', 'cafeteria', slots[1].at)]);
      expect(h.path, AppRoutes.reservation(casioReservationId));
      expect(find.text('482 173'), findsOneWidget);
      expect(find.byKey(const Key('reservation-qr')), findsOneWidget);
      expect(find.text('Valeria te lo guarda'), findsOneWidget);
    });

    testWidgets('con otro apartado activo dice por que no se puede', (
      tester,
    ) async {
      final h = _Harness(tester);
      h.reservations.createFailure = const ApiFailure(
        code: 'reservations.limit_reached',
        message:
            'Ya tienes un apartado activo. Recógelo o cancélalo para apartar '
            'otro.',
      );
      await h.open(AppRoutes.product('p1'));

      await h.tap(find.text('Apartar'));
      await h.tap(find.byKey(const Key('reserve-confirm')));

      expect(
        find.text(
          'Ya tienes un apartado activo. Recógelo o cancélalo para apartar '
          'otro.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('reserve-confirm')), findsOneWidget);
    });

    testWidgets('"Cancelar apartado" pide confirmar y quita el QR', (
      tester,
    ) async {
      final h = _Harness(tester, reservations: [sampleReservation()]);
      await h.open(AppRoutes.reservation(casioReservationId));

      await h.tap(find.byKey(const Key('reservation-cancel')));
      expect(find.text('¿Cancelar el apartado?'), findsOneWidget);
      expect(
        find.text('Valeria podrá venderlo a alguien más.'),
        findsOneWidget,
      );

      await h.tap(find.byKey(const Key('reservation-cancel-confirm')));

      expect(h.reservations.cancelled, [casioReservationId]);
      expect(find.text('Apartado cancelado'), findsOneWidget);
      expect(find.byKey(const Key('reservation-qr')), findsNothing);
      expect(find.text('482 173'), findsNothing);
    });
  });

  group('Mis apartados (HU-52)', () {
    testWidgets('"Yo aparté" muestra mi QR y "Me apartaron" verifica', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        reservations: [sampleReservation(), sampleSellerReservation()],
      );
      await h.open(AppRoutes.myReservations);

      expect(find.text('Yo aparté (1)'), findsOneWidget);
      expect(find.text('Me apartaron (1)'), findsOneWidget);
      expect(find.text('Mostrar mi QR'), findsOneWidget);
      expect(find.text(r'$450 · Valeria C.'), findsOneWidget);

      await h.tap(find.byKey(const Key('my-reservations-tab-seller')));

      expect(find.text(r'Luis M. · $180'), findsOneWidget);
      expect(find.text('Entrega solo después de verificar'), findsOneWidget);

      await h.tap(find.byKey(const Key('reservation-verify')));

      expect(h.path, AppRoutes.verifyBuyer(squaresReservationId));
      expect(find.text('Apunta al QR de Luis'), findsOneWidget);
    });

    testWidgets('la tarjeta de Perfil cuenta lo que falta recoger', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        reservations: [sampleReservation(), sampleSellerReservation()],
      );
      await h.open(AppRoutes.profile);

      expect(find.text('Mis apartados'), findsOneWidget);
      expect(
        find.textContaining('1 por recoger', findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('1 te apartaron', findRichText: true),
        findsOneWidget,
      );

      await h.tap(find.byKey(const Key('profile-reservations')));
      expect(h.path, AppRoutes.myReservations);
    });
  });

  group('Verificar comprador y entregar (HU-52)', () {
    testWidgets('el QR de otro apartado no se acepta y el correcto verifica', (
      tester,
    ) async {
      _scans.addAll([
        'musubi:apartado:6716a0000000000000000a09:482173',
        'musubi:apartado:$squaresReservationId:482173',
      ]);
      final h = _Harness(tester, reservations: [sampleSellerReservation()]);
      await h.open(AppRoutes.verifyBuyer(squaresReservationId));

      await h.tap(find.byKey(Key('scan-${_scans[0]}')));

      expect(find.text('Ese QR no es de este apartado'), findsOneWidget);
      expect(h.reservations.verifiedCodes, isEmpty);

      await h.tap(find.byKey(Key('scan-${_scans[1]}')));

      expect(h.reservations.verifiedCodes, ['482173']);
      expect(h.path, AppRoutes.buyerVerified(squaresReservationId));
      expect(find.text('Comprador verificado'), findsOneWidget);
    });

    testWidgets('"Escribir código": uno equivocado gasta un intento', (
      tester,
    ) async {
      final h = _Harness(tester, reservations: [sampleSellerReservation()]);
      await h.open(AppRoutes.verifyBuyer(squaresReservationId));

      await h.tap(find.byKey(const Key('verify-mode-code')));
      expect(find.text('Son 6 números que Luis ve en su app'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('verify-code')), '111111');
      await h.tap(find.byKey(const Key('verify-submit')));

      expect(
        find.text('Ese código no coincide · te quedan 4 intentos'),
        findsOneWidget,
      );
      expect(h.path, AppRoutes.verifyBuyer(squaresReservationId));

      await tester.enterText(find.byKey(const Key('verify-code')), '482173');
      await h.tap(find.byKey(const Key('verify-submit')));

      expect(h.reservations.verifiedCodes, ['111111', '482173']);
      expect(h.path, AppRoutes.buyerVerified(squaresReservationId));
    });

    testWidgets('"Confirmar entrega" crea la venta y dice "¡Entregado!"', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        reservations: [sampleSellerReservation(verifiedAt: _now)],
      );
      await h.open(AppRoutes.buyerVerified(squaresReservationId));

      expect(find.text('Es quien apartó tu producto.'), findsOneWidget);
      expect(find.text('Cobra en efectivo'), findsOneWidget);

      await h.tap(find.byKey(const Key('verified-deliver')));

      expect(h.reservations.completed, [squaresReservationId]);
      expect(find.text('¡Entregado!'), findsOneWidget);
      expect(
        find.text('Entrega confirmada. Luis ya puede calificarte'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('verified-done')), findsOneWidget);
    });

    testWidgets('sin verificar, "Confirmar entrega" no responde', (
      tester,
    ) async {
      final h = _Harness(tester, reservations: [sampleSellerReservation()]);
      await h.open(AppRoutes.buyerVerified(squaresReservationId));

      await h.tap(find.byKey(const Key('verified-deliver')));

      expect(h.reservations.completed, isEmpty);
    });
  });

  test('un aviso de apartado abre el apartado', () {
    expect(
      NotificationTarget.parse('reservation'),
      NotificationTarget.reservation,
    );
    expect(
      routeFor(NotificationTarget.reservation, 'r1'),
      AppRoutes.reservation('r1'),
    );
    expect(routeFor(NotificationTarget.reservation, ''), isNull);
  });

  test('los apartados piden sesion', () {
    for (final path in [
      AppRoutes.myReservations,
      AppRoutes.reservation('r1'),
      AppRoutes.verifyBuyer('r1'),
    ]) {
      expect(
        sessionRedirect(signedIn: false, location: Uri.parse(path)),
        startsWith(AppRoutes.signIn),
        reason: path,
      );
    }
  });
}
