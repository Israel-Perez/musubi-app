import 'dart:async';

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
import 'package:musubi_app/features/marketplace/domain/home_feed.dart';
import 'package:musubi_app/features/marketplace/presentation/home_providers.dart';

import '../../helpers/fake_catalog_repository.dart';
import '../../helpers/fake_chat.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

final _now = DateTime.utc(2026, 11, 6, 21);

/// Inicio con la calculadora de Valeria.
final _feed = HomeFeed(
  popular: [
    ProductSummary(
      id: 'p1',
      title: 'Calculadora Casio fx-991ES Plus',
      priceCents: 45000,
      stock: 1,
      views: 12,
      condition: 'Usado',
      sellerName: 'Valeria C.',
      publishedAt: _now.subtract(const Duration(hours: 1)),
    ),
  ],
);

ChatMessage _message(String id, String text, String sender, int minute) =>
    ChatMessage(
      id: id,
      conversationId: 'c1',
      senderId: sender,
      text: text,
      sentAt: DateTime.utc(2026, 11, 6, 20, minute),
    );

/// App completa con el router real, la sesion abierta y el chat falso.
class ChatHarness {
  new(this.tester, {FakeChatRepository? chat})
    : chat = chat ?? FakeChatRepository();

  final WidgetTester tester;
  final FakeChatRepository chat;
  final realtime = FakeChatRealtime();
  late ProviderContainer container;

  Future<void> open(String location, {Object? extra}) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final session = chatTokens(_now);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brandSplashEnabledProvider.overrideWithValue(false),
          catalogRepositoryProvider.overrideWithValue(
            FakeCatalogRepository([_feed]),
          ),
          sessionApiProvider.overrideWithValue(FakeSessionApi()),
          clockProvider.overrideWithValue(() => _now),
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(session)),
          initialSessionTokensProvider.overrideWithValue(session),
          chatRepositoryProvider.overrideWithValue(chat),
          chatRealtimeProvider.overrideWithValue(realtime),
        ],
        child: const MusubiApp(),
      ),
    );
    container = ProviderScope.containerOf(
      tester.element(find.byType(MusubiApp)),
    );
    if (extra == null) {
      container.read(routerProvider).go(location);
    } else {
      container.read(routerProvider).go(AppRoutes.home);
      await tester.pumpAndSettle();
      // push termina al cerrar la pantalla: no se espera.
      unawaited(container.read(routerProvider).push(location, extra: extra));
    }
    await tester.pumpAndSettle();
  }

  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}

// HU-20 / HU-22: el chat de la maqueta (`Chat-Valeria`) y la bandeja
// (`Mensajes`) contra el repositorio y el tiempo real falsos.
void main() {
  group('Chat (HU-20)', () {
    testWidgets('tocar un producto en Inicio abre el chat con quien lo vende', (
      tester,
    ) async {
      final harness = ChatHarness(tester);
      await harness.open(AppRoutes.home);

      await harness.tap(find.text('Calculadora Casio fx-991ES Plus').first);

      expect(harness.chat.started, ['p1']);
      expect(find.text('Valeria Cruz'), findsOneWidget);
      expect(find.text('PUBLICACIÓN DE VALERIA'), findsOneWidget);
      expect(
        find.textContaining('Usado · con detalles', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Escribe un mensaje…'), findsOneWidget);
      expect(harness.chat.read, ['c1']);
    });

    testWidgets(
      'muestra el historial: lo mio a la derecha, lo suyo a la izquierda',
      (tester) async {
        final harness = ChatHarness(
          tester,
          chat: FakeChatRepository(
            messages: [
              _message('m1', '¡Hola, Valeria! ¿Sigue disponible?', myId, 1),
              _message('m2', 'Claro, sigue disponible.', valeria.id, 3),
            ],
          ),
        );
        await harness.open(AppRoutes.conversation('c1'));

        final mine = tester.getCenter(
          find.text('¡Hola, Valeria! ¿Sigue disponible?'),
        );
        final theirs = tester.getCenter(find.text('Claro, sigue disponible.'));
        expect(mine.dx, greaterThan(195));
        expect(theirs.dx, lessThan(195));
        expect(
          find.textContaining('Conversación sobre su publicación'),
          findsOneWidget,
        );
      },
    );

    testWidgets('enviar agrega el mensaje y limpia la caja', (tester) async {
      final harness = ChatHarness(tester);
      await harness.open(AppRoutes.conversation('c1'));

      await tester.enterText(
        find.byKey(const Key('chat-input')),
        '  ¿Me la dejas en 400?  ',
      );
      await harness.tap(find.bySemanticsLabel('Enviar'));

      expect(harness.chat.sent, ['¿Me la dejas en 400?']);
      expect(find.text('¿Me la dejas en 400?'), findsOneWidget);
      final input = tester.widget<TextField>(
        find.byKey(const Key('chat-input')),
      );
      expect(input.controller!.text, isEmpty);
    });

    testWidgets('un mensaje rechazado avisa y no se borra lo escrito', (
      tester,
    ) async {
      final harness = ChatHarness(
        tester,
        chat: FakeChatRepository(
          sendFailure: const ApiFailure(
            code: 'moderation.text_rejected',
            message: 'Revisa el mensaje: no cumple las reglas de la comunidad.',
            status: 422,
          ),
        ),
      );
      await harness.open(AppRoutes.conversation('c1'));

      await tester.enterText(find.byKey(const Key('chat-input')), 'texto feo');
      await harness.tap(find.bySemanticsLabel('Enviar'));

      expect(
        find.text('Revisa el mensaje: no cumple las reglas de la comunidad.'),
        findsOneWidget,
      );
      final input = tester.widget<TextField>(
        find.byKey(const Key('chat-input')),
      );
      expect(input.controller!.text, 'texto feo');
    });

    testWidgets('lo que llega en tiempo real aparece y se marca leido', (
      tester,
    ) async {
      final harness = ChatHarness(tester);
      await harness.open(AppRoutes.conversation('c1'));
      expect(harness.realtime.starts, greaterThan(0));

      harness.realtime
        ..push(_message('m9', 'Va, nos vemos en la biblioteca.', valeria.id, 9))
        // De otra conversacion: no se muestra aqui.
        ..push(
          ChatMessage(
            id: 'x1',
            conversationId: 'c2',
            senderId: 'u9',
            text: 'Otro chat',
            sentAt: DateTime.utc(2026, 11, 6, 20, 10),
          ),
        );
      await tester.pumpAndSettle();

      expect(find.text('Va, nos vemos en la biblioteca.'), findsOneWidget);
      expect(find.text('Otro chat'), findsNothing);
      expect(harness.chat.read, ['c1', 'c1']);
    });

    testWidgets('en mi propia publicacion lo explica en vez de abrir el chat', (
      tester,
    ) async {
      final harness = ChatHarness(
        tester,
        chat: FakeChatRepository(
          startFailure: const ApiFailure(
            code: 'chat.own_product',
            message: 'Es tu publicación: aquí te escribirán los compradores.',
            status: 400,
          ),
        ),
      );
      await harness.open(AppRoutes.chat, extra: _feed.popular.first);

      expect(
        find.text('Es tu publicación: aquí te escribirán los compradores.'),
        findsOneWidget,
      );
      expect(find.text('Escribe un mensaje…'), findsNothing);
    });

    testWidgets('sin sesion, un enlace al chat lleva a iniciar sesion', (
      tester,
    ) async {
      expect(
        sessionRedirect(signedIn: false, location: Uri.parse('/chat/c1')),
        startsWith(AppRoutes.signIn),
      );
      expect(
        sessionRedirect(signedIn: true, location: Uri.parse('/chat/c1')),
        isNull,
      );
    });
  });

  group('Mensajes (HU-22)', () {
    InboxEntry entry(
      String id,
      ChatRole role,
      String name,
      String text,
      int unread,
    ) => InboxEntry(
      id: id,
      role: role,
      counterpart: ChatCounterpart(id: 'u-$id', name: name),
      contextTitle: 'Calculadora Casio',
      lastSenderId: 'u-$id',
      lastText: text,
      lastAt: DateTime.utc(2026, 11, 6, 20, 31),
      unread: unread,
    );

    testWidgets('lista las conversaciones con sus no leidos y filtra Ventas', (
      tester,
    ) async {
      final harness = ChatHarness(
        tester,
        chat: FakeChatRepository(
          inboxEntries: [
            entry(
              'c1',
              ChatRole.seller,
              'Diego Hernández',
              'Perfecto, en la biblioteca.',
              2,
            ),
            entry(
              'c2',
              ChatRole.buyer,
              'Valeria Cruz',
              'Claro, sigue disponible.',
              0,
            ),
          ],
        ),
      );
      await harness.open(AppRoutes.messages);

      expect(find.text('Mensajes'), findsWidgets);
      expect(find.text('Diego Hernández'), findsOneWidget);
      expect(find.text('Valeria Cruz'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Venta · Calculadora Casio'), findsOneWidget);
      expect(find.text('Compra · Calculadora Casio'), findsOneWidget);

      await harness.tap(find.text('Ventas'));

      expect(harness.chat.inboxCalls.last, InboxFilter.sales);
      expect(find.text('Diego Hernández'), findsOneWidget);
      expect(find.text('Valeria Cruz'), findsNothing);
    });

    testWidgets('tocar una conversacion la abre', (tester) async {
      final harness = ChatHarness(
        tester,
        chat: FakeChatRepository(
          inboxEntries: [
            entry('c1', ChatRole.buyer, 'Valeria Cruz', 'Claro', 1),
          ],
        ),
      );
      await harness.open(AppRoutes.messages);

      await harness.tap(find.text('Valeria Cruz'));

      expect(find.text('Escribe un mensaje…'), findsOneWidget);
      expect(harness.chat.read, ['c1']);
    });

    testWidgets('sin conversaciones explica como empezar', (tester) async {
      final harness = ChatHarness(tester);
      await harness.open(AppRoutes.messages);

      expect(find.text('Aún no tienes conversaciones'), findsOneWidget);
    });

    testWidgets('un mensaje nuevo en tiempo real vuelve a pedir la bandeja', (
      tester,
    ) async {
      final harness = ChatHarness(tester);
      await harness.open(AppRoutes.messages);
      final before = harness.chat.inboxCalls.length;

      harness.realtime.push(_message('m5', 'Hola', valeria.id, 5));
      await tester.pumpAndSettle();

      expect(harness.chat.inboxCalls.length, greaterThan(before));
    });
  });
}
