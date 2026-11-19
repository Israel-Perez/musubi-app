@Tags(['security'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/session/auth_interceptor.dart';

import '../helpers/in_memory_token_store.dart';

/// Archivos de `lib/` que pueden tocar los tokens de la sesion (MASVS-STORAGE).
/// Un archivo nuevo que los lea o los guarde tiene que pasar por revision:
/// agregarlo aqui es esa decision.
const _tokenFiles = {
  'lib/core/session/auth_interceptor.dart',
  'lib/core/session/session_api.dart',
  'lib/core/session/session_controller.dart',
  'lib/core/session/session_tokens.dart',
  // El hub de SignalR lleva el access token en ?access_token= (API HU-20).
  'lib/features/chat/presentation/chat_providers.dart',
};

Iterable<File> _libFiles() =>
    Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

String _posix(String path) => path.replaceAll(r'\', '/');

/// Seguridad de la sesion en el telefono (02-10, OWASP MASVS-STORAGE,
/// MASVS-NETWORK y MASVS-AUTH). Complementa `test/core/session/` (renovacion
/// y logout) y los flujos de seguridad contra la API real de
/// `test/integration/security_flow_test.dart`.
void main() {
  group('Los tokens no salen de donde deben', () {
    test('solo los archivos de sesion leen o guardan tokens', () {
      final touching = {
        for (final file in _libFiles())
          if (RegExp('accessToken|refreshToken')
              .hasMatch(file.readAsStringSync()))
            _posix(file.path),
      };

      expect(touching.difference(_tokenFiles), isEmpty);
    });

    test('nada guarda la sesion fuera del almacen seguro', () {
      final offenders = [
        for (final file in _libFiles())
          // El uso en el codigo (no una mencion en un comentario).
          if (RegExp(
            r'package:shared_preferences|SharedPreferences\.getInstance|'
            r'getApplicationDocumentsDirectory\(|\.writeAsString(Sync)?\(',
          ).hasMatch(file.readAsStringSync()))
            _posix(file.path),
      ];

      expect(offenders, isEmpty);
    });

    test('nadie registra peticiones HTTP (encabezados con el token)', () {
      final offenders = [
        for (final file in _libFiles())
          if (file.readAsStringSync().contains('LogInterceptor'))
            _posix(file.path),
      ];

      expect(offenders, isEmpty);
    });

    test('un error de red nunca muestra el token de la peticion', () {
      final request = RequestOptions(
        path: '/api/v1/profiles/me',
        headers: {'Authorization': 'Bearer secreto-del-token'},
      );
      final failures = [
        ApiFailure.fromDio(
          DioException.connectionError(
            requestOptions: request,
            reason: 'sin red',
          ),
        ),
        ApiFailure.fromDio(
          DioException.badResponse(
            statusCode: 500,
            requestOptions: request,
            response: Response(requestOptions: request, statusCode: 500),
          ),
        ),
      ];

      for (final failure in failures) {
        expect(failure.message, isNot(contains('secreto-del-token')));
        expect(failure.toString(), isNot(contains('secreto-del-token')));
      }
    });
  });

  group('El token solo viaja a la API', () {
    final interceptor = AuthInterceptor(
      apiBaseUrl: Uri.parse('https://api.musubiapp.com.mx'),
      readTokens: testTokens,
      onRefreshed: (_) async {},
      onSessionEnded: () async {},
      refresher: (_) async => null,
      retry: (options) async => Response(requestOptions: options),
    );

    RequestOptions send(String url, {Map<String, Object?>? headers}) {
      final options = RequestOptions(path: url, headers: headers);
      interceptor.onRequest(options, RequestInterceptorHandler());
      return options;
    }

    test('un Authorization puesto a mano se quita hacia otro host', () {
      final options = send(
        'https://evil.example/robar',
        headers: {'Authorization': 'Bearer access-1'},
      );

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('ni por HTTP en claro hacia el mismo host', () {
      expect(
        send('http://api.musubiapp.com.mx/api/v1/profiles/me').headers,
        isNot(contains('Authorization')),
      );
    });

    test('hacia la API si lo lleva', () {
      expect(
        send('https://api.musubiapp.com.mx/api/v1/profiles/me')
            .headers['Authorization'],
        'Bearer access-1',
      );
    });
  });

  group('Ambientes publicados', () {
    test('prod y staging usan HTTPS y nunca la PC de desarrollo', () {
      for (final name in ['prod', 'staging']) {
        final json = jsonDecode(
          File('config/$name.example.json').readAsStringSync(),
        ) as Map<String, dynamic>;
        final config = AppConfig.parse(
          environment: json['ENV'] as String,
          apiBaseUrl: json['API_BASE_URL'] as String,
        );

        expect(config.apiBaseUrl.scheme, 'https', reason: name);
        expect(
          AppConfig.localDevHosts,
          isNot(contains(config.apiBaseUrl.host)),
        );
      }
    });

    test('fuera de dev, HTTP se rechaza al arrancar', () {
      expect(
        () => AppConfig.parse(
          environment: 'prod',
          apiBaseUrl: 'http://api.musubiapp.com.mx',
        ),
        throwsA(isA<AppConfigException>()),
      );
    });
  });
}
