import 'package:dio/dio.dart';
import 'package:musubi_app/core/errors/api_failure.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_tokens.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/domain/auth_repository.dart';

/// [AuthRepository] sobre `/api/v1/auth` (filas M-01 de
/// `musubi-api/docs/endpoints.md`). Usa el cliente sin sesion.
class HttpAuthRepository implements AuthRepository {
  new(this._dio);

  final Dio _dio;

  @override
  Future<Campus> resolveCampus(String email) async =>
      _campus(await _post(ApiPaths.authCampus, {'email': email.trim()}));

  @override
  Future<Registration> register({
    required String email,
    required String fullName,
    required String password,
    required bool acceptTerms,
    required bool acceptPrivacy,
  }) async {
    final body = await _post(ApiPaths.authRegister, {
      'email': email.trim(),
      'fullName': fullName.trim(),
      'password': password,
      'acceptTerms': acceptTerms,
      'acceptPrivacy': acceptPrivacy,
    });
    return Registration(
      email: body['email'] as String,
      codeExpiresAt: _date(body['codeExpiresAt']),
      resendAvailableAt: _date(body['resendAvailableAt']),
    );
  }

  @override
  Future<DateTime> resendCode(String email) async => _date(
    (await _post(ApiPaths.authResend, {
      'email': email.trim(),
    }))['resendAvailableAt'],
  );

  @override
  Future<SignedInSession> confirmCode({
    required String email,
    required String code,
  }) async {
    final body = await _post(ApiPaths.authConfirm, {
      'email': email.trim(),
      'code': code.trim(),
    });
    final user = body['user'] as Map<String, dynamic>;
    return SignedInSession(
      tokens: SessionTokens(
        accessToken: body['accessToken'] as String,
        accessExpiresAt: _date(body['accessTokenExpiresAt']),
        refreshToken: body['refreshToken'] as String,
      ),
      user: AuthUser(
        id: user['id'] as String,
        fullName: user['fullName'] as String,
        email: user['email'] as String,
        emailVerified: user['emailVerified'] as bool,
        campus: _campus(user['campus'] as Map<String, dynamic>),
      ),
    );
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, Object> body,
  ) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = response.data;
      if (data == null) {
        throw const ApiFailure(
          code: ApiFailure.serverError,
          message: 'El servidor respondió algo inesperado.',
        );
      }
      return data;
    } on DioException catch (error) {
      // Se traduce (no se traga): la pantalla decide por el code.
      throw ApiFailure.fromDio(error);
    }
  }

  static Campus _campus(Map<String, dynamic> json) => Campus(
    shortName: json['shortName'] as String,
    name: json['name'] as String,
  );

  static DateTime _date(Object? value) => DateTime.parse('$value').toUtc();
}
