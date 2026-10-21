import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/session/auth_interceptor.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/in_memory_token_store.dart';

/// Arma un Dio con el interceptor y un servidor falso.
class Harness {
  new({
    required Future<ResponseBody> Function(RequestOptions) server,
    SessionTokens? tokens,
    this.renewed,
  }) : current = tokens {
    adapter = FakeHttpAdapter((options) {
      sentAuth.add(options.headers['Authorization'] as String?);
      return server(options);
    });
    final options = BaseOptions(baseUrl: 'https://api.musubi.example');
    // El reintento sale por un cliente sin el interceptor (como en la app).
    final plain = Dio(options)..httpClientAdapter = adapter;
    dio = Dio(options)..httpClientAdapter = adapter;
    dio.interceptors.add(
      AuthInterceptor(
        apiBaseUrl: Uri.parse('https://api.musubi.example'),
        readTokens: () => current,
        onRefreshed: (tokens) async => current = tokens,
        onSessionEnded: () async {
          ended++;
          current = null;
        },
        refresher: (refreshToken) async {
          refreshCalls.add(refreshToken);
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return renewed;
        },
        retry: plain.fetch,
      ),
    );
  }

  late final FakeHttpAdapter adapter;
  late final Dio dio;
  SessionTokens? current;
  final SessionTokens? renewed;
  final List<String> refreshCalls = [];
  int ended = 0;

  /// Header Authorization tal como salio en cada envio.
  final List<String?> sentAuth = [];
}

ResponseBody ok() => FakeHttpAdapter.json({'ok': true});

ResponseBody unauthorized() =>
    FakeHttpAdapter.json({'code': 'auth.unauthorized'}, status: 401);

// 02-01 / MASVS-NETWORK, L-16g: el token solo va a musubi-api y la sesion se
// renueva una sola vez ante un 401.
void main() {
  test('agrega el token a las peticiones hacia la API', () async {
    final h = Harness(server: (_) async => ok(), tokens: testTokens());

    await h.dio.get<Object?>('/api/v1/ping');

    expect(h.sentAuth, ['Bearer access-1']);
  });

  test('nunca envia el token a otro host, esquema o puerto', () async {
    final h = Harness(server: (_) async => ok(), tokens: testTokens());

    await h.dio.get<Object?>('https://otro-sitio.example/robar');
    await h.dio.get<Object?>('http://api.musubi.example/api/v1/ping');
    await h.dio.get<Object?>('https://api.musubi.example:8443/api/v1/ping');
    await h.dio.get<Object?>(
      '/api/v1/ping',
      options: Options(headers: {'Authorization': 'Bearer otro'}),
    );

    expect(h.sentAuth.take(3), everyElement(isNull));
    expect(h.sentAuth.last, 'Bearer access-1');
  });

  test('visitante: no agrega token', () async {
    final h = Harness(server: (_) async => ok());

    await h.dio.get<Object?>('/api/v1/ping');

    expect(h.sentAuth, [null]);
  });

  test('401: renueva la sesion y reintenta con el token nuevo', () async {
    final h = Harness(
      server: (o) async => o.headers['Authorization'] == 'Bearer access-2'
          ? ok()
          : unauthorized(),
      tokens: testTokens(),
      renewed: testTokens('2'),
    );

    final response = await h.dio.get<Object?>('/api/v1/privado');

    expect(response.statusCode, 200);
    expect(h.refreshCalls, ['refresh-1']);
    expect(h.current, testTokens('2'));
    expect(h.sentAuth, ['Bearer access-1', 'Bearer access-2']);
  });

  test('varios 401 a la vez: una sola renovacion', () async {
    final h = Harness(
      server: (o) async => o.headers['Authorization'] == 'Bearer access-2'
          ? ok()
          : unauthorized(),
      tokens: testTokens(),
      renewed: testTokens('2'),
    );

    final responses = await Future.wait([
      for (var i = 0; i < 4; i++) h.dio.get<Object?>('/api/v1/privado/$i'),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(h.refreshCalls, hasLength(1));
  });

  test('si la API rechaza la renovacion, la sesion termina', () async {
    final h = Harness(
      server: (_) async => unauthorized(),
      tokens: testTokens(),
    );

    await expectLater(
      h.dio.get<Object?>('/api/v1/privado'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          401,
        ),
      ),
    );
    expect(h.ended, 1);
    expect(h.current, isNull);
  });

  test('un 401 despues de renovar no provoca un bucle', () async {
    final h = Harness(
      server: (_) async => unauthorized(),
      tokens: testTokens(),
      renewed: testTokens('2'),
    );

    await expectLater(
      h.dio.get<Object?>('/api/v1/privado'),
      throwsA(isA<DioException>()),
    );
    expect(h.refreshCalls, hasLength(1));
    expect(h.adapter.requests, hasLength(2));
  });
}
