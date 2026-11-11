import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/chat/data/http_chat_repository.dart';
import 'package:musubi_app/features/chat/data/signalr_chat_realtime.dart';
import 'package:musubi_app/features/genai/data/http_agreement_repository.dart';
import 'package:musubi_app/features/genai/domain/agreement_models.dart';

import '../../helpers/fake_http_adapter.dart';

/// `AgreementResponse` como el fixture `agreement.json` de musubi-api.
Map<String, Object?> agreementJson({
  String status = 'proposed',
  Object? deliveryAt = '2026-11-11T19:00:00Z',
  List<String> notIdentified = const [],
  List<String> missing = const [],
  Map<String, Object?>? proposal,
}) => {
  'id': '6716a00000000000000000b1',
  'conversationId': '6716a00000000000000000c1',
  'revision': 2,
  'status': status,
  'role': 'seller',
  'requestedBy': 'buyer',
  'buyer': {'id': '6716a0000000000000000002', 'name': 'Ana Sofía Ramírez'},
  'seller': {'id': '6716a0000000000000000001', 'name': 'Diego Hernández'},
  'proposal':
      proposal ??
      {
        'title': 'Calculadora científica Casio fx-991ES Plus',
        'priceCents': 45000,
        'quantity': 1,
        'meetingPoint': 'biblioteca',
        'pointName': 'Biblioteca',
        'meetingDetail': null,
        'deliveryAt': deliveryAt,
        'conditions': null,
      },
  'notIdentified': notIdentified,
  'missing': missing,
  'maxQuantity': 2,
  'buyerConfirmedAt': '2026-11-10T18:01:00Z',
  'sellerConfirmedAt': null,
  'createdAt': '2026-11-10T18:00:00Z',
  'updatedAt': '2026-11-10T18:01:00Z',
  'expiresAt': '2026-12-10T18:00:00Z',
};

// HU-32/33/34: el repositorio habla las filas "M-10" de musubi-api.
void main() {
  late FakeHttpAdapter adapter;
  late HttpAgreementRepository repository;

  void serve(ResponseBody Function(RequestOptions options) response) {
    adapter = FakeHttpAdapter((options) async => response(options));
    repository = HttpAgreementRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );
  }

  test('pedir el resumen manda la conversacion, espera a la IA y mapea la '
      'propuesta', () async {
    serve((_) => FakeHttpAdapter.json(agreementJson(), status: 201));

    final a = await repository.request('c1');

    final sent = adapter.requests.single;
    expect((sent.method, sent.path), ('POST', ApiPaths.agreements));
    expect(sent.data, {'conversationId': 'c1'});
    expect(sent.receiveTimeout, agreementReceiveTimeout);
    expect(a.id, '6716a00000000000000000b1');
    expect(a.revision, 2);
    expect(a.status, AgreementStatus.proposed);
    expect(a.isBuyer, isFalse);
    expect(a.requestedByBuyer, isTrue);
    expect(
      (a.buyerName, a.sellerName),
      ('Ana Sofía Ramírez', 'Diego Hernández'),
    );
    expect(a.counterpartName, 'Ana Sofía Ramírez');
    expect(a.proposal.priceCents, 45000);
    expect(a.proposal.pointName, 'Biblioteca');
    expect(a.proposal.detail, isNull);
    expect(a.proposal.deliveryAt, DateTime.utc(2026, 11, 11, 19));
    expect(a.maxQuantity, 2);
    expect(a.confirmations, 1);
    expect(a.confirmedByMe, isFalse);
    expect(a.complete, isTrue);
  });

  test('lo que falta y lo que agrego una persona', () async {
    serve(
      (_) => FakeHttpAdapter.json({
        'items': [
          agreementJson(
            deliveryAt: null,
            notIdentified: ['priceCents', 'deliveryAt'],
            missing: ['deliveryAt'],
          ),
        ],
      }),
    );

    final a = (await repository.byConversation('c1'))!;

    expect(adapter.requests.single.queryParameters, {'conversationId': 'c1'});
    expect(a.proposal.deliveryAt, isNull);
    expect(a.complete, isFalse);
    expect(a.added(AgreementField.price), isTrue);
    expect(a.added(AgreementField.deliveryAt), isFalse);
  });

  test('sin acuerdo vigente es null', () async {
    serve((_) => FakeHttpAdapter.json({'items': <Object>[]}));

    expect(await repository.byConversation('c1'), isNull);
  });

  test('una respuesta sin la forma del acuerdo no se muestra (HU-33 R4)', () {
    serve(
      (_) => FakeHttpAdapter.json(
        agreementJson(proposal: {'title': 'Calculadora', 'priceCents': '450'}),
        status: 201,
      ),
    );

    expect(
      repository.request('c1'),
      throwsA(
        isA<ApiFailure>().having(
          (f) => f.code,
          'code',
          'agreements.invalid_response',
        ),
      ),
    );
  });

  test('sin IA llega genai.unavailable con su mensaje', () {
    serve(
      (_) => FakeHttpAdapter.json({
        'code': 'genai.unavailable',
        'title':
            'La IA no está disponible ahora. Llena el resumen a mano o '
            'inténtalo más tarde.',
        'status': 503,
      }, status: 503),
    );

    expect(
      repository.request('c1'),
      throwsA(
        isA<ApiFailure>().having((f) => f.code, 'code', 'genai.unavailable'),
      ),
    );
  });

  test('corregir manda la version y solo lo que cambia', () async {
    serve((_) => FakeHttpAdapter.json(agreementJson()));
    final current = agreementFromJson(agreementJson());

    await repository.update(
      current,
      AgreementEdit(
        priceCents: 38000,
        deliveryAt: DateTime.utc(2026, 11, 11, 20),
        conditions: '',
      ),
    );

    final sent = adapter.requests.single;
    expect(
      (sent.method, sent.path),
      ('PUT', ApiPaths.agreement('6716a00000000000000000b1')),
    );
    expect(sent.data, {
      'revision': 2,
      'priceCents': 38000,
      'deliveryAt': '2026-11-11T20:00:00.000Z',
      'conditions': '',
    });
  });

  test('confirmar manda la version que se ve', () async {
    serve((_) => FakeHttpAdapter.json(agreementJson(status: 'confirmed')));

    final a = await repository.confirm(agreementFromJson(agreementJson()));

    final sent = adapter.requests.single;
    expect(
      (sent.method, sent.path),
      ('POST', ApiPaths.agreementConfirm('6716a00000000000000000b1')),
    );
    expect(sent.data, {'revision': 2});
    expect(a.confirmed, isTrue);
  });

  test('descartar es DELETE', () async {
    serve((_) => ResponseBody.fromString('', 204));

    await repository.discard('a1');

    final sent = adapter.requests.single;
    expect((sent.method, sent.path), ('DELETE', ApiPaths.agreement('a1')));
  });

  test('un mensaje kind notice es un aviso del chat', () {
    final notice = messageFromJson({
      'id': 'm1',
      'conversationId': 'c1',
      'senderId': 'u1',
      'text': 'Ana pidió un resumen con IA',
      'sentAt': '2026-11-10T18:00:00Z',
      'kind': 'notice',
    });
    final text = messageFromJson({
      'id': 'm2',
      'conversationId': 'c1',
      'senderId': 'u1',
      'text': 'Hola',
      'sentAt': '2026-11-10T18:00:00Z',
      'kind': 'text',
    });

    expect((notice.notice, text.notice), (true, false));
  });

  test('el hub entrega agreementChanged con la conversacion', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      final socket = await WebSocketTransformer.upgrade(request);
      var greeted = false;
      socket.listen((_) {
        if (greeted) return;
        greeted = true;
        final changed = jsonEncode({
          'type': 1,
          'target': 'agreementChanged',
          'arguments': [
            {'conversationId': 'c1'},
          ],
        });
        socket
          ..add('{}${SignalRChatRealtime.recordSeparator}')
          ..add('$changed${SignalRChatRealtime.recordSeparator}');
      });
    });
    final realtime = SignalRChatRealtime(
      apiBaseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
      readToken: () async => 'tok-123',
    );
    addTearDown(realtime.stop);

    final first = realtime.agreementChanges.first;
    realtime.start();

    expect(await first.timeout(const Duration(seconds: 5)), 'c1');
  });
}
