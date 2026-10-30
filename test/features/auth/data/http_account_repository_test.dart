import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/auth/data/http_account_repository.dart';

import '../../../helpers/fake_http_adapter.dart';

// HU-46: el repositorio habla la fila `POST /api/v1/account/delete` de
// musubi-api y traduce `auth.wrong_password`.
void main() {
  late FakeHttpAdapter adapter;
  late HttpAccountRepository repository;

  void serve(ResponseBody Function() response) {
    adapter = FakeHttpAdapter((_) async => response());
    repository = HttpAccountRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );
  }

  test('eliminar: POST con la contrasena actual', () async {
    serve(() => ResponseBody.fromString('', 204));

    await repository.deleteAccount('musubi2026');

    expect(adapter.requests.single.method, 'POST');
    expect(adapter.requests.single.path, ApiPaths.accountDelete);
    expect(adapter.requests.single.data, {'password': 'musubi2026'});
  });

  test('contrasena equivocada: ApiFailure con su codigo y mensaje', () async {
    serve(
      () => FakeHttpAdapter.json({
        'code': 'auth.wrong_password',
        'title': 'La contraseña no es correcta.',
        'status': 400,
      }, status: 400),
    );

    await expectLater(
      repository.deleteAccount('otra'),
      throwsA(
        isA<ApiFailure>()
            .having((f) => f.code, 'code', 'auth.wrong_password')
            .having(
              (f) => f.message,
              'message',
              'La contraseña no es correcta.',
            ),
      ),
    );
  });
}
