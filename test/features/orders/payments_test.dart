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
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/orders/data/http_order_repository.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/domain/payment_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_payouts.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 15, 21, 30);

/// CLABE de BBVA México con su digito verificador (012 180 0154 8821 482 + 9).
const _clabe = '012180015488214829';

/// App completa con el router real, la sesion de Ana y los pedidos y la cuenta
/// falsos (HU-55).
class _Harness {
  new(this.tester, {List<Order>? orders, FakePayoutRepository? payouts})
    : orders = FakeOrderRepository(orders: orders),
      payouts = payouts ?? FakePayoutRepository();

  final WidgetTester tester;
  final FakeOrderRepository orders;
  final FakePayoutRepository payouts;
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
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
          chatRealtimeProvider.overrideWithValue(FakeChatRealtime()),
          orderRepositoryProvider.overrideWithValue(orders),
          payoutRepositoryProvider.overrideWithValue(payouts),
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

  bool enabled(String key) =>
      (tester.widget(find.byKey(Key(key))) as dynamic).onPressed != null;
}

void main() {
  group('Pedido-pago y Pago-transferencia (HU-55)', () {
    testWidgets('con la cuenta de quien vende, la transferencia sale elegida y '
        'cambia "Así funciona"', (tester) async {
      final h = _Harness(
        tester,
        orders: [sampleOrder(transferAvailable: true)],
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.text('Valeria tiene su cuenta registrada'), findsOneWidget);
      expect(find.text('Transfieres y capturas la referencia'), findsOneWidget);
      expect(find.byKey(const Key('order-pay-transfer-go')), findsOneWidget);

      await h.tap(find.byKey(const Key('order-pay-cash')));

      expect(
        find.text('Le das tu código de entrega y se completa tu pedido'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-pay-cash-confirm')), findsOneWidget);
      expect(h.orders.transfersChosen, isEmpty);
    });

    testWidgets('"Ver datos para transferir" la registra y muestra la cuenta; '
        'la referencia se envia y queda "validando"', (tester) async {
      final h = _Harness(
        tester,
        orders: [sampleOrder(transferAvailable: true)],
      );
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-pay-transfer-go')));

      expect(h.orders.transfersChosen, ['o1']);
      expect(find.text('Paga por transferencia'), findsOneWidget);
      expect(find.text(r'$450.00'), findsOneWidget);
      expect(find.text('012 180 0154 2378 9134'), findsOneWidget);
      expect(find.text('VALERIA CRUZ HERNÁNDEZ'), findsOneWidget);
      expect(find.text('MS-1001'), findsOneWidget);
      expect(h.enabled('transfer-send'), isFalse);

      await tester.enterText(find.byKey(const Key('transfer-reference')), '48');
      await tester.pump();
      expect(h.enabled('transfer-send'), isFalse);
      await tester.enterText(
        find.byKey(const Key('transfer-reference')),
        '4829 173',
      );
      await tester.pump();
      await h.tap(find.byKey(const Key('transfer-send')));

      expect(h.orders.references, [('o1', '4829173')]);
      expect(find.byKey(const Key('order-validating')), findsOneWidget);
      expect(find.text('Valeria está validando tu pago'), findsOneWidget);
      expect(find.text('Pendiente · Validando pago'), findsOneWidget);
      expect(find.byKey(const Key('order-chat')), findsOneWidget);
    });

    testWidgets('si quien vende dice que no le llega, quien compra lo ve', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: [
          sampleOrder(
            paysTransfer: true,
            transferReference: '4829173',
            transferReportedAt: DateTime.utc(2026, 11, 15, 21, 14),
            transferNotReceivedAt: DateTime.utc(2026, 11, 15, 22),
          ),
        ],
      );
      await h.open(AppRoutes.order('o1'));

      expect(find.text('Valeria todavía no ve tu pago'), findsOneWidget);
      expect(find.text('Pendiente · No le ha llegado'), findsOneWidget);
      expect(find.text('Cancelar pedido'), findsOneWidget);
    });
  });

  group('Pago-vendedor (HU-55)', () {
    Order reported() => sampleOrder(
      isBuyer: false,
      paysTransfer: true,
      transferReference: '4829173',
      transferReportedAt: DateTime.utc(2026, 11, 15, 21, 14),
    );

    testWidgets('quien vende ve lo que debe llegarle y su cuenta enmascarada', (
      tester,
    ) async {
      final h = _Harness(tester, orders: [reported()]);
      await h.open(AppRoutes.order('o1'));

      expect(find.text('Ana dice que ya te transfirió'), findsOneWidget);
      expect(find.text(r'$450.00'), findsOneWidget);
      expect(find.text('Por validar'), findsOneWidget);
      expect(find.text('4829173'), findsOneWidget);
      expect(find.text('BBVA •••• 9134'), findsOneWidget);
      expect(find.text('Cancelar pedido'), findsNothing);
    });

    testWidgets('"Todavía no me llega" avisa y "Sí, me llegó el pago" '
        'confirma el pedido', (tester) async {
      final h = _Harness(tester, orders: [reported()]);
      await h.open(AppRoutes.order('o1'));

      await h.tap(find.byKey(const Key('order-transfer-not-received')));
      expect(h.orders.notReceived, ['o1']);
      expect(find.textContaining('Le avisaste a Ana'), findsOneWidget);

      await h.tap(find.byKey(const Key('order-transfer-received')));

      expect(h.orders.accepted, ['o1']);
      expect(find.bySemanticsLabel('Estado del pedido: Confirmado'), findsOne);
      expect(find.text(r'Pago validado · $450'), findsOneWidget);
    });
  });

  group('Pedido-efectivo (HU-55)', () {
    testWidgets('quien compra ve su codigo, que solo el ve, y como entregar', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        orders: [
          sampleOrder(
            paysCash: true,
            status: OrderStatus.confirmed,
            deliveryCode: '7319',
          ),
        ],
      );
      await h.open(AppRoutes.order('o1'));

      expect(
        find.bySemanticsLabel('Tu código de entrega: 7 3 1 9'),
        findsOneWidget,
      );
      expect(find.text('Solo tú lo ves'), findsOneWidget);
      expect(find.text('Pagas en efectivo al recibir'), findsOneWidget);
      expect(find.text('Al momento de la entrega'), findsOneWidget);
      expect(find.byKey(const Key('order-chat')), findsOneWidget);
      expect(find.byKey(const Key('order-handover')), findsNothing);
    });

    testWidgets('quien vende escribe el codigo: uno equivocado gasta un '
        'intento y el correcto completa el pedido', (tester) async {
      final h = _Harness(
        tester,
        orders: [
          sampleOrder(
            isBuyer: false,
            paysCash: true,
            status: OrderStatus.confirmed,
            codeAttemptsLeft: 5,
          ),
        ],
      );
      await h.open(AppRoutes.order('o1'));
      final field = find.descendant(
        of: find.byKey(const Key('order-code-field')),
        matching: find.byType(EditableText),
      );

      await tester.enterText(field, '1111');
      await tester.pumpAndSettle();
      expect(h.orders.codes, [('o1', '1111')]);
      expect(find.text('Te quedan 4 intentos.'), findsOneWidget);

      await tester.enterText(field, '7319');
      await tester.pumpAndSettle();

      expect(h.orders.codes.last, ('o1', '7319'));
      // Como al confirmar la entrega: completado, abre `Calificar`.
      expect(
        h.container.read(routerProvider).state.uri.path,
        AppRoutes.rate('o1'),
      );
    });
  });

  group('Cuenta para recibir pagos (Cuenta-pagos, HU-55)', () {
    testWidgets('el banco sale de la CLABE y se guarda a mi nombre', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.settingsPayouts);

      expect(find.text('Cuenta para recibir pagos'), findsOneWidget);
      expect(find.text('Se llena con tu CLABE'), findsOneWidget);
      expect(h.enabled('payout-save'), isFalse);

      await tester.enterText(
        find.byKey(const Key('payout-clabe')),
        '01218001548821482',
      );
      await tester.pump();
      expect(find.text('BBVA México'), findsNWidgets(2)); // campo y tarjeta
      await tester.enterText(find.byKey(const Key('payout-clabe')), _clabe);
      await tester.pump();
      expect(find.text('•••• •••• •••• 4829'), findsOneWidget);
      expect(find.text('ANA SOFÍA RAMÍREZ'), findsOneWidget);

      await h.tap(find.byKey(const Key('payout-save')));

      expect(h.payouts.saved, [('Ana Sofía Ramírez', _clabe)]);
      expect(h.payouts.account?.short, 'BBVA ···· 4829');
    });

    testWidgets('una CLABE con otro digito verificador no se puede guardar', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open(AppRoutes.settingsPayouts);

      await tester.enterText(
        find.byKey(const Key('payout-clabe')),
        '012180015488214820',
      );
      await tester.pump();

      expect(
        find.text('Revisa tu CLABE: un dígito no coincide.'),
        findsOneWidget,
      );
      expect(h.enabled('payout-save'), isFalse);
    });

    testWidgets('el error de la API se muestra y la cuenta guardada se puede '
        'quitar', (tester) async {
      final h = _Harness(
        tester,
        payouts: FakePayoutRepository(account: sampleAccount)
          ..saveFailure = const ApiFailure(
            code: 'payouts.holder_mismatch',
            message:
                'El titular debe coincidir con tu nombre verificado. Usa una '
                'cuenta a tu nombre.',
            status: 422,
          ),
      );
      await h.open(AppRoutes.settingsPayouts);
      await tester.enterText(find.byKey(const Key('payout-clabe')), _clabe);
      await tester.pump();

      await h.tap(find.byKey(const Key('payout-save')));
      expect(find.textContaining('El titular debe coincidir'), findsOneWidget);

      await h.tap(find.byKey(const Key('payout-remove')));
      expect(h.payouts.removed, 1);
      expect(
        find.text('Quitaste tu cuenta. Te pagarán en efectivo.'),
        findsOneWidget,
      );
    });

    testWidgets('sin llave en la API no se pueden guardar cuentas', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        payouts: FakePayoutRepository(available: false),
      );
      await h.open(AppRoutes.settingsPayouts);
      await tester.enterText(find.byKey(const Key('payout-clabe')), _clabe);
      await tester.pump();

      expect(
        find.textContaining('Por ahora no podemos guardar'),
        findsOneWidget,
      );
      expect(h.enabled('payout-save'), isFalse);
    });
  });

  group('La CLABE en la app', () {
    test('digito verificador y grupos como la maqueta', () {
      expect(Clabe.isValid(_clabe), isTrue);
      expect(Clabe.isValid('012180015488214820'), isFalse);
      expect(Clabe.isValid('0121800154882148'), isFalse);
      expect(Clabe.format(_clabe), '012 180 0154 8821 4829');
      expect(Clabe.format('01218'), '012 18');
    });
  });

  group('HttpOrderRepository y HttpPayoutRepository (HU-55)', () {
    final base = Uri.parse('https://api.musubi.example');
    Dio dio(FakeHttpAdapter adapter) =>
        Dio(BaseOptions(baseUrl: base.toString()))..httpClientAdapter = adapter;

    test('el pago trae la referencia, el codigo y los intentos', () {
      final order = orderFromJson({
        'id': 'o1',
        'number': 'MS-1001',
        'status': 'confirmed',
        'role': 'buyer',
        'conversationId': 'c1',
        'item': {'title': 'Calculadora', 'totalCents': 45000},
        'delivery': {'pointName': 'Biblioteca', 'at': '2026-11-16T19:00:00Z'},
        'payment': {
          'method': 'cash',
          'chosenAt': '2026-11-15T18:00:00Z',
          'reference': null,
          'reportedAt': null,
          'notReceivedAt': null,
          'validatedAt': null,
          'deliveryCode': '7319',
          'codeAttemptsLeft': null,
        },
        'transferAvailable': false,
      }, base);

      expect((order.paysCash, order.deliveryCode), (true, '7319'));
      expect(order.transferReported, isFalse);
    });

    test(
      'la transferencia, la referencia y el codigo van a sus rutas',
      () async {
        final adapter = FakeHttpAdapter((options) async {
          if (options.path == ApiPaths.orderTransfer('o1') &&
              options.method == 'GET') {
            return FakeHttpAdapter.json({
              'amountCents': 50000,
              'bankName': 'BBVA México',
              'holderName': 'Diego Hernández',
              'clabe': '012 180 0154 8821 4829',
              'clabeLast4': '4829',
              'concept': 'MS-2481',
              'reference': null,
              'reportedAt': null,
              'notReceivedAt': null,
              'validatedAt': null,
            });
          }
          return FakeHttpAdapter.json({
            'id': 'o1',
            'number': 'MS-2481',
            'status': 'pending',
            'role': 'buyer',
            'conversationId': 'c1',
            'item': {'title': 'Calculadora', 'totalCents': 50000},
            'delivery': {
              'pointName': 'Biblioteca',
              'at': '2026-11-16T19:00:00Z',
            },
            'payment': {
              'method': 'transfer',
              'chosenAt': '2026-11-15T18:00:00Z',
              'reference': '4829173',
              'reportedAt': '2026-11-15T21:14:00Z',
            },
            'transferAvailable': true,
          });
        });
        final repository = HttpOrderRepository(dio(adapter), base);

        final details = await repository.transfer('o1');
        final reported = await repository.reportTransfer('o1', '4829173');
        await repository.payTransfer('o1');
        await repository.transferNotReceived('o1');
        await repository.deliveryCode('o1', '7319');

        expect((details.clabeDigits, details.concept), (_clabe, 'MS-2481'));
        expect(reported.transferReported, isTrue);
        expect(reported.transferReference, '4829173');
        expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
          'GET ${ApiPaths.orderTransfer('o1')}',
          'POST ${ApiPaths.orderTransfer('o1')}',
          'PUT ${ApiPaths.orderPayment('o1')}',
          'POST ${ApiPaths.orderTransferNotReceived('o1')}',
          'POST ${ApiPaths.orderDeliveryCode('o1')}',
        ]);
        expect(adapter.requests[1].data, {'reference': '4829173'});
        expect(adapter.requests[2].data, {'method': 'transfer'});
        expect(adapter.requests[4].data, {'code': '7319'});
      },
    );

    test(
      'la cuenta llega enmascarada y se guarda con titular y CLABE',
      () async {
        final adapter = FakeHttpAdapter((options) async {
          if (options.method == 'PUT') {
            return FakeHttpAdapter.json({
              'holderName': 'Ana Sofía Ramírez',
              'bankCode': '012',
              'bankName': 'BBVA México',
              'clabeLast4': '4829',
              'updatedAt': '2026-11-15T18:00:00Z',
            });
          }
          if (options.path == ApiPaths.payoutBanks) {
            return FakeHttpAdapter.json({
              'items': [
                {'code': '012', 'name': 'BBVA México'},
              ],
            });
          }
          return FakeHttpAdapter.json({'available': true, 'account': null});
        });
        final repository = HttpPayoutRepository(dio(adapter));

        final status = await repository.mine();
        final banks = await repository.banks();
        final saved = await repository.save(
          holderName: 'Ana Sofía Ramírez',
          clabe: _clabe,
        );

        expect((status.available, status.account), (true, null));
        expect(banks.single.name, 'BBVA México');
        expect(saved.short, 'BBVA ···· 4829');
        expect(adapter.requests.last.data, {
          'holderName': 'Ana Sofía Ramírez',
          'clabe': _clabe,
        });
      },
    );
  });
}
