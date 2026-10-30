import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/features/auth/domain/account_repository.dart';

/// [AccountRepository] sobre `/api/v1/account` (fila M-01 de
/// `musubi-api/docs/endpoints.md`). Usa el cliente con sesion.
class HttpAccountRepository implements AccountRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<void> deleteAccount(String password) async {
    try {
      await _dio.post<void>(
        ApiPaths.accountDelete,
        data: {'password': password},
      );
    } on DioException catch (error) {
      // Se traduce (no se traga): la pantalla decide por el code.
      throw ApiFailure.fromDio(error);
    }
  }
}
