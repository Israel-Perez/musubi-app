import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/profile/data/http_theme_preference_repository.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';

import '../../helpers/fake_http_adapter.dart';

void main() {
  test('GET mapea el tema que guardó la API', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({'theme': 'dark'}),
    );
    final repository = HttpThemePreferenceRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );

    final theme = await repository.getTheme();

    expect(adapter.requests.single.path, ApiPaths.myPreferences);
    expect(theme, ThemePreference.dark);
  });

  test('PUT envía y devuelve el tema seleccionado', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({'theme': 'light'}),
    );
    final repository = HttpThemePreferenceRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );

    final theme = await repository.setTheme(ThemePreference.light);

    expect(adapter.requests.single.method, 'PUT');
    expect(adapter.requests.single.path, ApiPaths.myPreferences);
    expect(adapter.requests.single.data, {'theme': 'light'});
    expect(theme, ThemePreference.light);
  });

  test('valor ausente o desconocido cae al tema del sistema', () async {
    final adapter = FakeHttpAdapter(
      (_) async => FakeHttpAdapter.json({'theme': 'sepia'}),
    );
    final repository = HttpThemePreferenceRepository(
      Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
        ..httpClientAdapter = adapter,
    );

    expect(await repository.getTheme(), ThemePreference.system);
  });
}
