import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/profile/domain/theme_preference.dart';
import 'package:musubi_app/features/profile/domain/theme_preference_repository.dart';

/// Cliente HTTP del contrato HU-54 de musubi-api. Requiere sesión.
class HttpThemePreferenceRepository implements ThemePreferenceRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<ThemePreference> getTheme() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      ApiPaths.myPreferences,
    );
    return ThemePreference.parse(response.data?['theme']);
  });

  @override
  Future<ThemePreference> setTheme(ThemePreference theme) => _guard(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.myPreferences,
      data: {'theme': theme.value},
    );
    return ThemePreference.parse(response.data?['theme']);
  });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
