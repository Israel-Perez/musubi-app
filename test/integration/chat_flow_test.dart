@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_providers.dart';
import 'package:musubi_app/features/genai/domain/agreement_models.dart';
import 'package:musubi_app/features/genai/presentation/agreement_providers.dart';
import 'package:musubi_app/features/orders/domain/order_models.dart';
import 'package:musubi_app/features/orders/presentation/order_providers.dart';

import 'support/live_api.dart';
import 'support/live_flows.dart';

/// Pantallas `Mensajes`, `Chat-Valeria` y `Acuerdo-esperando` /
/// `Acuerdo-confirmado` contra la API real, con el tiempo real por el hub
/// (HU-20, HU-22, HU-32, HU-33, HU-34).
void main() {
  group('Chat contra la API real', skip: liveSkip, () {
    test('abrir el chat, escribir, bandeja, historial y leido', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Lámpara LED');

      final conversation = await openChat(ana, product.id);
      final again = await openChat(ana, product.id);
      await ana
          .read(chatRepositoryProvider)
          .send(conversation.id, 'Hola, ¿sigue disponible?');
      final inbox = await valeria.read(chatRepositoryProvider).inbox();
      final sales = await valeria
          .read(chatRepositoryProvider)
          .inbox(filter: InboxFilter.sales);
      final history = await valeria
          .read(chatRepositoryProvider)
          .messages(conversation.id);
      await valeria.read(chatRepositoryProvider).markRead(conversation.id);
      final asSeller = await valeria
          .read(chatRepositoryProvider)
          .conversation(conversation.id);

      expect(again.id, conversation.id);
      expect(inbox.items.map((e) => e.id), contains(conversation.id));
      expect(sales.items, isNotEmpty);
      expect(history.items.last.text, 'Hola, ¿sigue disponible?');
      expect(asSeller.role, ChatRole.seller);
    });

    test('el mensaje llega en tiempo real por el hub', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Termo de acero');
      final conversation = await openChat(ana, product.id);
      final realtime = valeria.read(chatRealtimeProvider);
      final received = realtime.messages
          .firstWhere((m) => m.conversationId == conversation.id)
          .timeout(const Duration(seconds: 20));
      realtime.start();
      recordCoverage('WS', '/hubs/chat');
      // Da tiempo a que el WebSocket termine el saludo de SignalR.
      await Future<void>.delayed(const Duration(seconds: 2));

      await ana.read(chatRepositoryProvider).send(conversation.id, '¿Mañana?');

      expect((await received).text, '¿Mañana?');
      await realtime.stop();
    });

    test('un mensaje inapropiado no se envia', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(
        valeria,
        title: 'Kit de resistencias',
      );
      final conversation = await openChat(ana, product.id);

      await expectLater(
        ana
            .read(chatRepositoryProvider)
            .send(conversation.id, 'Te vendo esto [[inapropiado]]'),
        throwsA(
          isA<ApiFailure>().having(
            (f) => f.code,
            'code',
            'moderation.text_rejected',
          ),
        ),
      );
    });

    test('acuerdo con IA: proponer, ajustar, confirmar y pedir', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Calculadora Casio');
      final conversation = await openChat(ana, product.id);
      final chat = ana.read(chatRepositoryProvider);
      await chat.send(
        conversation.id,
        'Te la compro en 450 pesos, ¿nos vemos mañana en la biblioteca?',
      );
      await valeria
          .read(chatRepositoryProvider)
          .send(conversation.id, 'Sí, mañana a la 1 en la biblioteca.');
      final buyerAgreements = ana.read(agreementRepositoryProvider);
      final sellerAgreements = valeria.read(agreementRepositoryProvider);

      final proposed = await buyerAgreements.request(conversation.id);
      final points = await ana.read(orderRepositoryProvider).meetingPoints();
      final adjusted = await buyerAgreements.update(
        proposed,
        AgreementEdit(
          title: 'Calculadora Casio',
          priceCents: 45000,
          quantity: 1,
          meetingPoint: points.first.slug,
          deliveryAt: tomorrowAtOne(),
        ),
      );
      final byBuyer = await buyerAgreements.confirm(adjusted);
      final seen = await sellerAgreements.byConversation(conversation.id);
      final both = await sellerAgreements.confirm(seen!);
      final order = await ana
          .read(orderRepositoryProvider)
          .createFromAgreement(both.id);

      expect(byBuyer.buyerConfirmedAt, isNotNull);
      expect(both.status, AgreementStatus.confirmed);
      expect((order.status, order.isBuyer), (OrderStatus.pending, true));
    });

    test('descartar un acuerdo', () async {
      final valeria = await liveUser(name: 'Valeria Integración');
      final ana = await liveUser();
      addTearDown(valeria.dispose);
      addTearDown(ana.dispose);
      final product = await publishProduct(valeria, title: 'Bata talla M');
      final conversation = await openChat(ana, product.id);
      await ana
          .read(chatRepositoryProvider)
          .send(conversation.id, 'Te la compro, ¿mañana en la cafetería?');
      final agreements = ana.read(agreementRepositoryProvider);

      final proposed = await agreements.request(conversation.id);
      await agreements.discard(proposed.id);

      expect(await agreements.byConversation(conversation.id), isNull);
    });
  });
}
