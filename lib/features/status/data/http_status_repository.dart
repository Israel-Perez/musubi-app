import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/network_error_message.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/status/domain/api_status.dart';
import 'package:musubi_app/features/status/domain/status_repository.dart';

/// Implementacion HTTP de [StatusRepository] sobre `GET /api/v1/ping`.
class HttpStatusRepository implements StatusRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<ApiStatus> check() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(ApiPaths.ping);
      final body = response.data;
      final version = body?['version'];
      if (body?['status'] == 'pong' && version is String) {
        return ApiOnline(version: version);
      }
      return const ApiOffline(
        message: 'El servidor respondió algo inesperado.',
      );
    } on DioException catch (error) {
      // Se traduce (no se traga): la UI muestra el motivo y permite reintentar.
      return ApiOffline(message: networkErrorMessage(error));
    }
  }
}
