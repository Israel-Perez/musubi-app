import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';

DioException badResponse(int status, Object? data) {
  final options = RequestOptions(path: '/api/v1/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(
      requestOptions: options,
      statusCode: status,
      data: data,
    ),
  );
}

// 02-01 / RNF-18: la app entiende el problem+json de musubi-api:02-03 y
// traduce los errores de red; decide por code, no por el texto.
void main() {
  test('problem+json: usa code y title de la API', () {
    final failure = ApiFailure.fromDio(
      badResponse(401, {
        'title': 'El correo o la contraseña no coinciden.',
        'status': 401,
        'code': 'auth.invalid_credentials',
        'traceId': 'x',
      }),
    );

    expect(failure.code, 'auth.invalid_credentials');
    expect(failure.message, 'El correo o la contraseña no coinciden.');
    expect(failure.status, 401);
    expect(failure.isNetwork, isFalse);
  });

  test('validacion: errores por campo con la clave en minusculas', () {
    final failure = ApiFailure.fromDio(
      badResponse(400, {
        'title': 'Revisa los datos enviados.',
        'code': 'validation.failed',
        'errors': {
          'Email': ['El correo no es válido.'],
          'Password': ['Muy corta.', 'Sin números.'],
        },
      }),
    );

    expect(failure.code, ApiFailure.validationFailed);
    expect(failure.fieldError('email'), 'El correo no es válido.');
    expect(failure.fieldError('Password'), 'Muy corta.');
    expect(failure.fieldError('nombre'), isNull);
  });

  test('respuesta sin code: generico por estado, sin datos del servidor', () {
    final failure = ApiFailure.fromDio(badResponse(502, '<html>proxy</html>'));

    expect(failure.code, ApiFailure.serverError);
    expect(failure.message, isNot(contains('html')));
  });

  test('errores de red: codigo propio y mensaje en espanol', () {
    final options = RequestOptions(path: '/api/v1/x');
    final cases = {
      DioExceptionType.connectionTimeout: ApiFailure.networkTimeout,
      DioExceptionType.connectionError: ApiFailure.networkOffline,
      DioExceptionType.badCertificate: ApiFailure.networkInsecure,
      DioExceptionType.cancel: ApiFailure.networkCancelled,
      DioExceptionType.unknown: ApiFailure.networkUnknown,
    };
    for (final MapEntry(key: type, value: code) in cases.entries) {
      final failure = ApiFailure.fromDio(
        DioException(requestOptions: options, type: type),
      );
      expect(failure.code, code);
      expect(failure.isNetwork, isTrue);
      expect(failure.message, isNotEmpty);
    }
  });
}
