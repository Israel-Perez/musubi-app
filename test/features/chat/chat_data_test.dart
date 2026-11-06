import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/chat/data/http_chat_repository.dart';
import 'package:musubi_app/features/chat/data/signalr_chat_realtime.dart';
import 'package:musubi_app/features/chat/domain/chat_models.dart';
import 'package:musubi_app/features/chat/presentation/chat_format.dart';

import '../../helpers/fake_chat.dart';
import '../../helpers/fake_http_adapter.dart';

/// `ConversationResponse` (fixture `conversation.json` de musubi-api).
const Map<String, Object> conversationJson = {
  'id': 'c1',
  'role': 'buyer',
  'counterpart': {'id': '6716a0000000000000000001', 'name': 'Valeria Cruz'},
  'context': {
    'type': 'product',
    'id': 'p1',
    'title': 'Calculadora Casio fx-991ES Plus',
    'priceCents': 45000,
    'condition': 'used',
    'conditionDetail': 'fair',
    'photo': '/media/products/u1/foto.webp',
    'available': true,
  },
  'createdAt': '2026-11-06T20:00:00Z',
};

/// `MessageResponse` (fixture `message.json`; tambien `messageCreated`).
Map<String, Object> messageJson(
  String id,
  String text, {
  String sender = myId,
}) => {
  'id': id,
  'conversationId': 'c1',
  'senderId': sender,
  'text': text,
  'sentAt': '2026-11-06T20:01:00Z',
};

// HU-20 / HU-22: el repositorio habla el contrato de musubi-api (filas "M-07"),
// el cliente de SignalR y los formatos de hora del chat.
void main() {
  group('SessionTokens.userId', () {
    test('lee el sub del access token', () {
      expect(SessionTokens.subjectOf(jwtFor('abc123')), 'abc123');
    });

    test('un token que no es JWT no tiene id', () {
      expect(SessionTokens.subjectOf('access-1'), isNull);
      expect(SessionTokens.subjectOf('a.%%%.c'), isNull);
    });
  });

  group('HttpChatRepository', () {
    late FakeHttpAdapter adapter;
    late HttpChatRepository repository;

    void serve(Object? Function(RequestOptions) body, {int status = 200}) {
      adapter = FakeHttpAdapter((options) async {
        final data = body(options);
        return data == null
            ? ResponseBody.fromString('', status)
            : FakeHttpAdapter.json(data, status: status);
      });
      repository = HttpChatRepository(
        Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
          ..httpClientAdapter = adapter,
        Uri.parse('https://api.musubi.example'),
      );
    }

    test(
      'start: POST con productId y la tarjeta con la foto completa',
      () async {
        serve((_) => conversationJson, status: 201);

        final conversation = await repository.start('p1');

        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect(request.path, ApiPaths.conversations);
        expect(request.data, {'productId': 'p1'});
        expect(conversation.counterpart.name, 'Valeria Cruz');
        expect(conversation.counterpart.initials, 'VC');
        expect(conversation.context.priceCents, 45000);
        expect(conversation.context.conditionLabel, 'Usado · con detalles');
        expect(
          conversation.context.photoUrl,
          'https://api.musubi.example/media/products/u1/foto.webp',
        );
      },
    );

    test('messages y send usan las rutas de la conversacion', () async {
      serve(
        (o) => o.method == 'GET'
            ? {
                'items': [
                  messageJson('m2', 'Claro'),
                  messageJson('m1', 'Hola'),
                ],
                'nextCursor': 'm1',
              }
            : messageJson('m3', 'Gracias'),
      );

      final page = await repository.messages('c1', cursor: 'm9');
      final sent = await repository.send('c1', 'Gracias');

      expect(adapter.requests[0].path, ApiPaths.conversationMessages('c1'));
      expect(adapter.requests[0].queryParameters, {'cursor': 'm9'});
      expect(page.items.map((m) => m.text), ['Claro', 'Hola']);
      expect(page.nextCursor, 'm1');
      expect(adapter.requests[1].data, {'text': 'Gracias'});
      expect(sent.id, 'm3');
    });

    test('inbox filtra por role y markRead llama a /read', () async {
      serve(
        (o) => o.method == 'GET'
            ? {
                'items': [
                  {
                    'id': 'c1',
                    'role': 'seller',
                    'counterpart': {'id': 'u2', 'name': 'Diego Hernández'},
                    'context': {
                      'type': 'product',
                      'id': 'p1',
                      'title': 'Calculadora Casio',
                      'photo': null,
                    },
                    'lastMessage': {
                      'senderId': 'u2',
                      'text': '¿Sigue disponible?',
                      'sentAt': '2026-11-06T20:31:00Z',
                    },
                    'unread': 2,
                  },
                ],
                'nextCursor': null,
              }
            : null,
      );

      final page = await repository.inbox(filter: InboxFilter.sales);
      await repository.markRead('c1');

      expect(adapter.requests[0].queryParameters, {'role': 'seller'});
      final entry = page.items.single;
      expect(entry.contextLine, 'Venta · Calculadora Casio');
      expect(entry.unread, 2);
      expect(adapter.requests[1].method, 'POST');
      expect(adapter.requests[1].path, ApiPaths.conversationRead('c1'));
    });

    test('un error de la API llega como ApiFailure con su codigo', () async {
      serve(
        (_) => {
          'code': 'chat.own_product',
          'title': 'Es tu publicación: aquí te escribirán los compradores.',
        },
        status: 400,
      );

      await expectLater(
        repository.start('p1'),
        throwsA(
          isA<ApiFailure>().having((f) => f.code, 'code', 'chat.own_product'),
        ),
      );
    });
  });

  group('SignalRChatRealtime', () {
    test('la URL del hub usa wss con https y lleva el token', () {
      final uri = SignalRChatRealtime.hubUri(
        Uri.parse('https://api.musubiapp.com.mx'),
        'tok',
      );
      expect(
        uri.toString(),
        'wss://api.musubiapp.com.mx/hubs/chat?access_token=tok',
      );
      expect(
        SignalRChatRealtime.hubUri(
          Uri.parse('http://10.0.2.2:5080'),
          't',
        ).scheme,
        'ws',
      );
    });

    test('separa varios mensajes de un bloque', () {
      final frames = SignalRChatRealtime.parseFrames(
        '{}\u001e{"type":6}\u001e',
      );
      expect(frames, [
        <String, dynamic>{},
        {'type': 6},
      ]);
    });

    test('se conecta a un hub real, saluda y entrega messageCreated', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final handshake = Completer<String>();
      String? token;
      server.listen((request) async {
        token = request.uri.queryParameters['access_token'];
        final socket = await WebSocketTransformer.upgrade(request);
        socket.listen((data) {
          if (!handshake.isCompleted) {
            handshake.complete(data as String);
            final created = jsonEncode({
              'type': 1,
              'target': 'messageCreated',
              'arguments': [
                messageJson('m1', '¿Sigue disponible?', sender: 'u2'),
              ],
            });
            socket
              ..add('{}')
              ..add('$created');
          }
        });
      });
      final realtime = SignalRChatRealtime(
        apiBaseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        readToken: () async => 'tok-123',
      );
      addTearDown(realtime.stop);

      final first = realtime.messages.first;
      realtime.start();

      expect(
        await handshake.future.timeout(const Duration(seconds: 5)),
        '{"protocol":"json","version":1}\u001e',
      );
      final message = await first.timeout(const Duration(seconds: 5));
      expect(token, 'tok-123');
      expect(message.text, '¿Sigue disponible?');
      expect(message.senderId, 'u2');
    });

    test('sin sesion no se conecta', () async {
      var connects = 0;
      final realtime = SignalRChatRealtime(
        apiBaseUrl: Uri.parse('http://127.0.0.1:1'),
        readToken: () async => null,
        connect: (_) async {
          connects++;
          throw const SocketException('no');
        },
      )..start();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await realtime.stop();
      expect(connects, 0);
    });
  });

  group('formatos de hora', () {
    final now = DateTime(2026, 11, 6, 21);

    test('hora de 12 horas como la maqueta', () {
      expect(clockTime(DateTime(2026, 11, 6, 18, 40)), '6:40 p. m.');
      expect(clockTime(DateTime(2026, 11, 6, 0, 5)), '12:05 a. m.');
    });

    test('hora de los mensajes: hoy, ayer y antes', () {
      expect(messageStamp(DateTime(2026, 11, 6, 20, 31), now), '8:31 p. m.');
      expect(
        messageStamp(DateTime(2026, 11, 5, 18, 40), now),
        'Ayer, 6:40 p. m.',
      );
      expect(messageStamp(DateTime(2026, 10, 28, 9), now), '28/10, 9:00 a. m.');
    });

    test('hora de la bandeja: hoy, ayer, dia de la semana y fecha', () {
      expect(inboxStamp(DateTime(2026, 11, 6, 20, 31), now), '8:31 p. m.');
      expect(inboxStamp(DateTime(2026, 11, 5, 10), now), 'Ayer');
      expect(inboxStamp(DateTime(2026, 11, 2, 10), now), 'lun');
      expect(inboxStamp(DateTime(2026, 10, 20, 10), now), '20/10');
    });
  });
}
