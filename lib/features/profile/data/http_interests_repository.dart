import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/profile/domain/interests_repository.dart';

/// Cliente HTTP del contrato HU-66 de musubi-api. Requiere sesión.
class HttpInterestsRepository implements InterestsRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<List<String>> get() => _guard(() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiPaths.myInterests);
    return _parse(response.data);
  });

  @override
  Future<List<String>> save(List<String> categories) => _guard(() async {
    final response = await _dio.put<Map<String, dynamic>>(
      ApiPaths.myInterests,
      data: {'categories': categories},
    );
    return _parse(response.data);
  });

  /// Una forma inesperada se vuelve `ApiFailure`, no un `TypeError`.
  static List<String> _parse(Map<String, dynamic>? data) {
    final categories = data?['categories'];
    if (categories is! List) {
      throw const ApiFailure(
        code: ApiFailure.serverError,
        message: 'El servidor respondió algo inesperado.',
      );
    }
    return [
      for (final slug in categories)
        if (slug is String) slug,
    ];
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      throw ApiFailure.fromDio(error);
    }
  }
}
