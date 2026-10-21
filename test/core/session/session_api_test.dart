import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_api.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

import '../../helpers/fake_http_adapter.dart';
import '../../helpers/fake_session_api.dart';
import '../../helpers/in_memory_token_store.dart';

// HU-02: renovar y revocar la sesion contra musubi-api (contrato de 02-03).
void main() {
  late FakeHttpAdapter adapter;

  HttpSessionApi api(Future<ResponseBody> Function(RequestOptions) handler) {
    adapter = FakeHttpAdapter(handler);
    return HttpSessionApi(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );
  }

  group('HttpSessionApi.refresh', () {
    test('rota: devuelve los tokens nuevos', () async {
      final tokens = await api(
        (_) async => FakeHttpAdapter.json({
          'accessToken': 'a2',
          'accessTokenExpiresAt': '2026-10-21T18:15:00Z',
          'refreshToken': 'r2',
          'refreshTokenExpiresAt': '2026-12-20T18:00:00Z',
          'user': <String, Object>{},
        }),
      ).refresh('r1');

      expect(
        tokens,
        SessionTokens(
          accessToken: 'a2',
          accessExpiresAt: DateTime.utc(2026, 10, 21, 18, 15),
          refreshToken: 'r2',
        ),
      );
      expect(adapter.requests.single.path, ApiPaths.authRefresh);
      expect(adapter.requests.single.data, {'refreshToken': 'r1'});
    });

    test('sesion terminada (401): null, la app pasa a visitante', () async {
      final tokens = await api(
        (_) async => FakeHttpAdapter.json({
          'code': 'auth.session_expired',
          'title': 'Tu sesión terminó. Inicia sesión de nuevo.',
        }, status: 401),
      ).refresh('r1');

      expect(tokens, isNull);
    });

    test('sin red: lanza DioException y la sesion se conserva', () {
      final sessionApi = api(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'sin red',
        ),
      );

      expect(() => sessionApi.refresh('r1'), throwsA(isA<DioException>()));
    });

    test('error del servidor (500): no termina la sesion', () {
      final sessionApi = api(
        (_) async =>
            FakeHttpAdapter.json({'code': 'server.error'}, status: 500),
      );

      expect(() => sessionApi.refresh('r1'), throwsA(isA<DioException>()));
    });
  });

  group('HttpSessionApi.revoke', () {
    test('204: avisa a la API con el refresh token', () async {
      final revoked = await api((_) async => ResponseBody.fromString('', 204))
          .revoke('r1');

      expect(revoked, isTrue);
      expect(adapter.requests.single.path, ApiPaths.authLogout);
      expect(adapter.requests.single.data, {'refreshToken': 'r1'});
    });

    test('sin red: false, sin lanzar', () async {
      final revoked = await api(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'sin red',
        ),
      ).revoke('r1');

      expect(revoked, isFalse);
    });
  });

  group('SessionController.logOut', () {
    ProviderContainer containerWith(FakeSessionApi sessionApi) {
      final tokens = testTokens();
      return ProviderContainer.test(
        overrides: [
          tokenStoreProvider.overrideWithValue(InMemoryTokenStore(tokens)),
          initialSessionTokensProvider.overrideWithValue(tokens),
          sessionApiProvider.overrideWithValue(sessionApi),
        ],
      );
    }

    test('revoca en la API y borra la sesion del dispositivo', () async {
      final sessionApi = FakeSessionApi();
      final container = containerWith(sessionApi);

      await container.read(sessionControllerProvider.notifier).logOut();

      expect(sessionApi.revoked, ['refresh-1']);
      expect(container.read(sessionControllerProvider), const Visitor());
      expect(await container.read(tokenStoreProvider).read(), isNull);
    });

    test('sin red: igual cierra la sesion en el dispositivo', () async {
      final container = containerWith(FakeSessionApi(online: false));

      await container.read(sessionControllerProvider.notifier).logOut();

      expect(container.read(sessionControllerProvider), const Visitor());
      expect(await container.read(tokenStoreProvider).read(), isNull);
    });
  });
}
