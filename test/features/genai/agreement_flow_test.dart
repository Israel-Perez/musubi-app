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
import 'package:musubi_app/features/genai/domain/agreement_models.dart';
import 'package:musubi_app/features/genai/presentation/agreement_providers.dart';
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

import '../../helpers/fake_agreements.dart';
import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_orders.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 6, 21);

/// La app con el chat `c1` de Ana con Valeria, la IA y los pedidos falsos.
class _Harness {
  new(
    this.tester, {
    FakeChatRepository? chat,
    FakeAgreementRepository? agreements,
    bool noticeSeen = true,
  }) : chat = chat ?? FakeChatRepository(),
       agreements = agreements ?? FakeAgreementRepository(),
       notice = FakeAiNoticeStore(wasSeen: noticeSeen);

  final WidgetTester tester;
  final FakeChatRepository chat;
  final FakeAgreementRepository agreements;
  final FakeAiNoticeStore notice;
  final orders = FakeOrderRepository();
  final realtime = FakeChatRealtime();
  late ProviderContainer container;

  Future<void> open() async {
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
          chatRealtimeProvider.overrideWithValue(realtime),
          orderRepositoryProvider.overrideWithValue(orders),
          agreementRepositoryProvider.overrideWithValue(agreements),
          aiNoticeStoreProvider.overrideWithValue(notice),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    container.read(routerProvider).go(AppRoutes.conversation('c1'));
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> summarize() => tap(find.byKey(const Key('chat-summarize')));

  bool enabled(String key) =>
      (tester.widget(find.byKey(Key(key))) as dynamic).onPressed != null;
}

/// Valeria vende y Ana compra.
FakeChatRepository _asSeller() => FakeChatRepository(
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
);

void main() {
  group('Resumir acuerdo con IA (HU-32)', () {
    testWidgets('la primera vez avisa que la IA leera el chat; cancelar no '
        'manda nada', (tester) async {
      final h = _Harness(tester, noticeSeen: false);
      await h.open();

      await h.summarize();

      expect(find.text('Resumir con IA'), findsOneWidget);
      expect(
        find.textContaining('Se envían sin sus nombres ni datos de contacto'),
        findsOneWidget,
      );
      await h.tap(find.text('Cancelar'));
      expect(h.agreements.requested, isEmpty);
      expect(h.notice.wasSeen, isFalse);

      await h.summarize();
      await h.tap(find.byKey(const Key('ai-notice-continue')));
      expect(h.agreements.requested, ['c1']);
      expect(h.notice.wasSeen, isTrue);
    });

    testWidgets('despues del aviso ya no lo vuelve a pedir', (tester) async {
      final h = _Harness(tester);
      await h.open();

      await h.summarize();

      expect(find.text('Resumir con IA'), findsNothing);
      expect(h.agreements.requested, ['c1']);
    });

    testWidgets('mientras la IA lee el chat se ve que esta trabajando', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open();

      await h.tester.tap(find.byKey(const Key('chat-summarize')));
      await h.tester.pump();
      await h.tester.pump(const Duration(milliseconds: 50));

      // El fake responde en el siguiente microtask: antes, la hoja lee.
      expect(find.byKey(const Key('agreement-sheet')), findsOneWidget);
      await h.tester.pumpAndSettle();
      expect(find.byKey(const Key('agreement-reading')), findsNothing);
      expect(
        find.text('Propuesta generada con IA, revísala antes de confirmar'),
        findsOneWidget,
      );
    });

    testWidgets('sin IA, quien compra llena el resumen a mano (RNF-15)', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        agreements: FakeAgreementRepository()..requestFailure = aiUnavailable,
      );
      await h.open();

      await h.summarize();

      expect(
        find.text('La IA no está disponible ahora. Llena el resumen a mano.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('order-summary')), findsOneWidget);
    });

    testWidgets('otro error de la API se avisa y el chat sigue', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        agreements: FakeAgreementRepository()
          ..requestFailure = const ApiFailure(
            code: 'agreements.nothing_to_summarize',
            message:
                'Todavía no hay mensajes que resumir. Platiquen primero el '
                'trato.',
          ),
      );
      await h.open();

      await h.summarize();

      expect(find.byKey(const Key('agreement-sheet')), findsNothing);
      expect(
        find.text(
          'Todavía no hay mensajes que resumir. Platiquen primero el trato.',
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-summarize')), findsOneWidget);
    });

    testWidgets('el aviso del chat se ve centrado, no como burbuja', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        chat: FakeChatRepository(
          messages: [
            ChatMessage(
              id: 'm9',
              conversationId: 'c1',
              senderId: myId,
              text: 'Ana pidió un resumen con IA',
              sentAt: _now,
              notice: true,
            ),
          ],
        ),
      );
      await h.open();

      expect(
        find.descendant(
          of: find.byKey(const Key('chat-notice')),
          matching: find.text('Ana pidió un resumen con IA'),
        ),
        findsOneWidget,
      );
    });
  });

  group('La propuesta de la IA (HU-33)', () {
    testWidgets('lo que no se dijo queda No identificado y no se confirma '
        'hasta completarlo', (tester) async {
      final h = _Harness(tester);
      await h.open();

      await h.summarize();

      expect(find.text('Calculadora Casio fx-991ES Plus'), findsWidgets);
      expect(find.text(r'$400'), findsOneWidget);
      expect(find.text('Campus universitario · Biblioteca'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('agreement-when')),
          matching: find.text('No identificado'),
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'No encontramos una fecha en la conversación. Agrégala o '
          'pregúntale a Valeria en el chat.',
        ),
        findsOneWidget,
      );
      expect(find.text('0 de 2'), findsOneWidget);

      // Como la maqueta, el boton se ve activo; al tocarlo dice que falta.
      await h.tap(find.byKey(const Key('agreement-confirm')));
      expect(
        find.text('Completa los datos que faltan antes de confirmar.'),
        findsOneWidget,
      );
      expect(h.agreements.confirmed, isEmpty);
    });
  });

  group('Revisar y confirmar (HU-34)', () {
    testWidgets('Agregar la fecha la guarda y deja confirmar', (tester) async {
      final h = _Harness(tester);
      await h.open();
      await h.summarize();

      await h.tap(
        find.descendant(
          of: find.byKey(const Key('agreement-when')),
          matching: find.text('Agregar'),
        ),
      );
      await h.tap(find.text('Mañana'));
      await h.tap(find.byKey(const Key('order-hour-13')));
      await h.tap(find.byKey(const Key('order-when-done')));

      expect(h.agreements.edits.single.deliveryAt, DateTime(2026, 11, 7, 13));
      expect(find.text('No identificado'), findsNothing);
      await h.tap(find.byKey(const Key('agreement-confirm')));
      expect(h.agreements.confirmed, [2]);
    });

    testWidgets('corregir el precio manda los pesos en centavos', (
      tester,
    ) async {
      final h = _Harness(tester);
      await h.open();
      await h.summarize();

      await h.tap(find.bySemanticsLabel('Editar precio'));
      await h.tester.enterText(
        find.byKey(const Key('agreement-price-field')),
        '380',
      );
      await h.tap(find.byKey(const Key('agreement-text-done')));

      expect(h.agreements.edits.single.priceCents, 38000);
      expect(find.text(r'$380'), findsOneWidget);
    });

    testWidgets('confirmar deja 1 de 2 y espera a la otra persona', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        agreements: FakeAgreementRepository(
          proposal: sampleAgreement(deliveryAt: DateTime.utc(2026, 11, 7, 19)),
        ),
      );
      await h.open();
      await h.summarize();

      await h.tap(find.byKey(const Key('agreement-confirm')));

      expect(h.agreements.confirmed, [1]);
      expect(find.text('1 de 2'), findsOneWidget);
      expect(find.text('Esperando a Valeria'), findsOneWidget);
      expect(h.enabled('agreement-confirm'), isFalse);
    });

    testWidgets(
      'si la otra persona lo cambio antes, avisa y lo vuelve a leer',
      (tester) async {
        final h = _Harness(
          tester,
          agreements:
              FakeAgreementRepository(
                  proposal: sampleAgreement(
                    deliveryAt: DateTime.utc(2026, 11, 7, 19),
                  ),
                )
                ..confirmFailure = const ApiFailure(
                  code: 'agreements.changed',
                  message:
                      'El acuerdo cambió. Revísalo de nuevo antes de '
                      'confirmarlo.',
                ),
        );
        await h.open();
        await h.summarize();

        await h.tap(find.byKey(const Key('agreement-confirm')));

        expect(
          find.text(
            'El acuerdo cambió. Revísalo de nuevo antes de confirmarlo.',
          ),
          findsOneWidget,
        );
        expect(find.text('0 de 2'), findsOneWidget);
      },
    );

    testWidgets('cuando la otra persona confirma, la hoja abierta pasa a '
        'Acuerdo confirmado', (tester) async {
      final h = _Harness(
        tester,
        agreements: FakeAgreementRepository(
          proposal: sampleAgreement(deliveryAt: DateTime.utc(2026, 11, 7, 19)),
        ),
      );
      await h.open();
      await h.summarize();
      await h.tap(find.byKey(const Key('agreement-confirm')));

      h.agreements.current = sampleAgreement(
        status: AgreementStatus.confirmed,
        deliveryAt: DateTime.utc(2026, 11, 7, 19),
        buyerConfirmedAt: _now,
        sellerConfirmedAt: _now,
      );
      h.realtime.agreementChanged('c1');
      await tester.pumpAndSettle();

      expect(find.text('Acuerdo confirmado'), findsOneWidget);
      expect(find.text('Agregada'), findsOneWidget);
      expect(
        find.text('Si algo cambia, ambos deben confirmar de nuevo.'),
        findsOneWidget,
      );
    });

    testWidgets('con el acuerdo confirmado, Crear pedido abre Tu pedido', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        agreements: FakeAgreementRepository(
          current: sampleAgreement(
            status: AgreementStatus.confirmed,
            deliveryAt: DateTime.utc(2026, 11, 7, 19),
            buyerConfirmedAt: _now,
            sellerConfirmedAt: _now,
          ),
        ),
      );
      await h.open();

      expect(
        find.text('Acuerdo confirmado · Falta crear el pedido'),
        findsOneWidget,
      );
      await h.tap(find.byKey(const Key('chat-open-agreement')));
      await h.tap(find.byKey(const Key('agreement-create-order')));

      expect(h.orders.fromAgreements, ['a1']);
      expect(find.text('Tu pedido'), findsOneWidget);
    });

    testWidgets('quien vende ve el acuerdo confirmado pero el pedido lo crea '
        'quien compra', (tester) async {
      final h = _Harness(
        tester,
        chat: _asSeller(),
        agreements: FakeAgreementRepository(
          current: sampleAgreement(
            isBuyer: false,
            status: AgreementStatus.confirmed,
            deliveryAt: DateTime.utc(2026, 11, 7, 19),
            buyerConfirmedAt: _now,
            sellerConfirmedAt: _now,
          ),
        ),
      );
      await h.open();

      await h.tap(find.byKey(const Key('chat-open-agreement')));

      expect(find.byKey(const Key('agreement-create-order')), findsNothing);
      expect(find.text('Ana crea el pedido con estos datos.'), findsOneWidget);
    });

    testWidgets('el aviso del chat cuenta las confirmaciones', (tester) async {
      final h = _Harness(
        tester,
        agreements: FakeAgreementRepository(
          current: sampleAgreement(sellerConfirmedAt: _now),
        ),
      );
      await h.open();

      expect(
        find.text('Acuerdo · Esperando confirmación (1 de 2)'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('chat-summarize')), findsNothing);
    });

    testWidgets('descartar lo borra para los dos y vuelve Resumir acuerdo', (
      tester,
    ) async {
      final h = _Harness(
        tester,
        agreements: FakeAgreementRepository(current: sampleAgreement()),
      );
      await h.open();

      await h.tap(find.byKey(const Key('chat-open-agreement')));
      await h.tap(find.byKey(const Key('agreement-discard')));
      await h.tap(find.byKey(const Key('agreement-discard-confirm')));

      expect(h.agreements.discarded, ['a1']);
      expect(find.byKey(const Key('agreement-sheet')), findsNothing);
      expect(find.byKey(const Key('chat-summarize')), findsOneWidget);
    });
  });
}
