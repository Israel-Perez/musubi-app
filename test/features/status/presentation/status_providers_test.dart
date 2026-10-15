import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/features/status/data/http_status_repository.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/presentation/status_providers.dart';

import '../../../helpers/fake_status_repository.dart';

// 01-03: estado de la API con Riverpod; el repositorio se inyecta
// por provider.
void main() {
  test('apiStatusProvider expone el resultado del repositorio', () async {
    final fake = FakeStatusRepository([const ApiOnline(version: 'v1')]);
    final container = ProviderContainer.test(
      overrides: [statusRepositoryProvider.overrideWithValue(fake)],
    )..listen(apiStatusProvider, (_, _) {});

    final status = await container.read(apiStatusProvider.future);

    expect(status, const ApiOnline(version: 'v1'));
    expect(fake.calls, 1);
  });

  test('invalidar el provider vuelve a consultar (reintentar)', () async {
    final fake = FakeStatusRepository([
      const ApiOffline(message: 'sin red'),
      const ApiOnline(version: 'v1'),
    ]);
    final container = ProviderContainer.test(
      overrides: [statusRepositoryProvider.overrideWithValue(fake)],
    )..listen(apiStatusProvider, (_, _) {});

    expect(await container.read(apiStatusProvider.future), isA<ApiOffline>());
    container.invalidate(apiStatusProvider);
    expect(await container.read(apiStatusProvider.future), isA<ApiOnline>());
    expect(fake.calls, 2);
  });

  test('sin override, el repositorio real usa la URL de AppConfig', () {
    final config = AppConfig.parse(
      environment: 'dev',
      apiBaseUrl: 'http://10.0.2.2:5080',
    );
    final container = ProviderContainer.test(
      overrides: [appConfigProvider.overrideWithValue(config)],
    );

    expect(
      container.read(statusRepositoryProvider),
      isA<HttpStatusRepository>(),
    );
    expect(container.read(dioProvider).options.baseUrl, 'http://10.0.2.2:5080');
  });
}
