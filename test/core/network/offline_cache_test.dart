import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/network/offline_cache.dart';
import 'package:musubi_app/core/storage/local_store.dart';

import '../../helpers/fake_http_adapter.dart';

/// HU-63: stale-while-revalidate en SQLite. Al abrir, lo guardado al instante
/// y lo nuevo en segundo plano; sin red, lo guardado con "Sin conexión"; lo
/// sensible nunca se escribe y cada cuenta tiene sus copias.
void main() {
  final base = Uri.parse('https://api.musubi.test');

  late InMemoryLocalStore store;
  late List<bool> flags;
  late List<String> refreshed;
  late bool online;
  late Map<String, Object?> body;
  var user = 'u1';
  var now = DateTime.utc(2026, 11, 23, 18);

  ({Dio dio, FakeHttpAdapter adapter}) client() {
    final adapter = FakeHttpAdapter((options) async {
      if (!online) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'sin red',
        );
      }
      return FakeHttpAdapter.json(body);
    });
    final dio = Dio(BaseOptions(baseUrl: base.toString()))
      ..httpClientAdapter = adapter;
    final interceptor = OfflineCacheInterceptor(
      store,
      identity: () => user,
      onOffline: ({required offline}) => flags.add(offline),
      onRefreshed: refreshed.add,
      clock: () => now,
    )..fetch = dio.fetch;
    dio.interceptors.add(interceptor);
    return (dio: dio, adapter: adapter);
  }

  setUp(() {
    store = InMemoryLocalStore();
    flags = [];
    refreshed = [];
    online = true;
    user = 'u1';
    now = DateTime.utc(2026, 11, 23, 18);
    body = {
      'items': [
        {
          'id': 'o1',
          'payment': {'method': 'cash', 'deliveryCode': '7319'},
        },
      ],
    };
  });

  Map<String, dynamic> firstItem(Object? data) =>
      ((data! as Map<String, dynamic>)['items'] as List<dynamic>).first
          as Map<String, dynamic>;

  Map<String, dynamic> payment(Object? data) =>
      firstItem(data)['payment'] as Map<String, dynamic>;

  Future<Response<dynamic>> get(Dio dio, {bool cache = true}) =>
      dio.get<dynamic>(
        '/api/v1/orders/mine',
        options: cache ? OfflineCache.options : null,
      );

  test('con red guarda la respuesta sin el codigo de entrega', () async {
    final (:dio, :adapter) = client();

    final response = await get(dio);

    expect(payment(response.data)['deliveryCode'], '7319');
    final saved = jsonDecode((await store.read('u1|/api/v1/orders/mine'))!);
    expect(payment(saved), {'method': 'cash'});
    expect(adapter.requests, hasLength(1));
    expect(flags, [false]);
  });

  test('sin red entrega lo guardado y dice "Sin conexión"', () async {
    final (:dio, adapter: _) = client();
    await get(dio);
    // Despues de los 30 s de la copia fresca, ya va a la red primero.
    now = now.add(const Duration(minutes: 1));
    online = false;

    final response = await get(dio);

    expect(response.extra[OfflineCache.fromCacheKey], isTrue);
    expect(firstItem(response.data)['id'], 'o1');
    expect(flags.last, isTrue);
  });

  test('al abrir la app entrega lo guardado al instante y lo actualiza en '
      'segundo plano', () async {
    await store.write('u1|/api/v1/orders/mine', '{"items":[]}');
    final (:dio, :adapter) = client();

    final first = await get(dio);
    await pumpEventQueue();
    final again = await get(dio);

    expect(first.data, {'items': <Object>[]});
    expect(first.extra[OfflineCache.fromCacheKey], isTrue);
    expect(refreshed, ['/api/v1/orders/mine']);
    expect(adapter.requests, hasLength(1));
    // La pantalla se vuelve a leer: entrega la copia recien llegada sin otra
    // peticion.
    expect(firstItem(again.data)['id'], 'o1');
    expect(adapter.requests, hasLength(1));
  });

  test('sin red y sin copia, el error llega como siempre', () async {
    online = false;
    final (:dio, adapter: _) = client();

    await expectLater(
      get(dio),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    expect(flags, [true]);
  });

  test('otra cuenta nunca ve la copia de la primera', () async {
    final (:dio, adapter: _) = client();
    await get(dio);
    user = 'u2';
    online = false;

    await expectLater(get(dio), throwsA(isA<DioException>()));
  });

  test('lo que no lo pide no se guarda', () async {
    final (:dio, adapter: _) = client();

    await get(dio, cache: false);

    expect(store.responses, isEmpty);
  });

  test('quita lo sensible en cualquier nivel', () {
    expect(
      OfflineCache.sanitize({
        'accessToken': 'x',
        'items': [
          {'reference': 'ABC', 'title': 'Calculadora'},
        ],
      }),
      {
        'items': [
          {'title': 'Calculadora'},
        ],
      },
    );
  });
}
