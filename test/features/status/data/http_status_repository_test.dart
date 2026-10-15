import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/status/data/http_status_repository.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';

import '../../../helpers/fake_http_adapter.dart';

// 01-03: el repositorio consume GET /api/v1/ping (fila de musubi-api
// docs/endpoints.md) y nunca lanza por fallas de red.
void main() {
  late FakeHttpAdapter adapter;

  HttpStatusRepository repositoryWith(
    Future<ResponseBody> Function(RequestOptions options) handler,
  ) {
    adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'http://10.0.2.2:5080'))
      ..httpClientAdapter = adapter;
    return HttpStatusRepository(dio);
  }

  test(
    'pong con version -> ApiOnline y consulta la ruta del catalogo',
    () async {
      final repository = repositoryWith(
        (_) async => FakeHttpAdapter.json({'status': 'pong', 'version': 'v1'}),
      );

      final status = await repository.check();

      expect(status, const ApiOnline(version: 'v1'));
      expect(adapter.requests.single.path, ApiPaths.ping);
      expect(adapter.requests.single.method, 'GET');
    },
  );

  test('respuesta con otra forma -> ApiOffline', () async {
    final repository = repositoryWith(
      (_) async => FakeHttpAdapter.json({'estado': 'ok'}),
    );

    final status = await repository.check();

    expect(status, isA<ApiOffline>());
  });

  test('HTTP 500 -> ApiOffline con mensaje de problema del servidor', () async {
    final repository = repositoryWith(
      (_) async => FakeHttpAdapter.json({'title': 'error'}, status: 500),
    );

    final status = await repository.check();

    expect(
      status,
      const ApiOffline(
        message: 'El servidor tuvo un problema. Intenta más tarde.',
      ),
    );
  });

  test('sin conexion -> ApiOffline, sin lanzar', () async {
    final repository = repositoryWith(
      (options) => throw DioException.connectionError(
        requestOptions: options,
        reason: 'Connection refused',
      ),
    );

    final status = await repository.check();

    expect(
      status,
      const ApiOffline(message: 'No hay conexión con el servidor.'),
    );
  });

  test('timeout -> ApiOffline con mensaje de demora', () async {
    final repository = repositoryWith(
      (options) => throw DioException.connectionTimeout(
        timeout: const Duration(seconds: 5),
        requestOptions: options,
      ),
    );

    final status = await repository.check();

    expect(
      status,
      const ApiOffline(message: 'El servidor tardó demasiado en responder.'),
    );
  });
}
