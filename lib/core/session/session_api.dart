import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/network/api_paths.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

/// Renovar y revocar la sesion en musubi-api (HU-02, contrato de 02-03).
abstract interface class SessionApi {
  /// Tokens nuevos (el refresh rota), o `null` si la sesion termino
  /// (`auth.session_expired`). Sin red lanza `DioException`: la sesion se
  /// conserva y se intenta despues.
  Future<SessionTokens?> refresh(String refreshToken);

  /// Revoca la sesion de este dispositivo. Devuelve `false` si no se pudo
  /// avisar a la API (sin red); el logout local sigue de todos modos.
  Future<bool> revoke(String refreshToken);
}

/// [SessionApi] sobre el cliente sin sesion: la renovacion nunca pasa por el
/// interceptor que la provoca.
class HttpSessionApi implements SessionApi {
  new(this._dio);

  final Dio _dio;

  @override
  Future<SessionTokens?> refresh(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        ApiPaths.authRefresh,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      return data == null ? null : SessionTokens.fromApi(data);
    } on DioException catch (error) {
      // 400/401: token vencido, revocado o reutilizado -> la sesion termino.
      // Cualquier otro error (red, 5xx) se propaga y la sesion se conserva.
      final status = error.response?.statusCode;
      if (status == 400 || status == 401) return null;
      rethrow;
    }
  }

  @override
  Future<bool> revoke(String refreshToken) async {
    try {
      await _dio.post<void>(
        ApiPaths.authLogout,
        data: {'refreshToken': refreshToken},
      );
      return true;
    } on DioException {
      // El token queda vivo en el servidor hasta su vencimiento (60 dias),
      // pero ya no existe en el dispositivo.
      return false;
    }
  }
}

/// API de sesion (en pruebas, un fake).
final sessionApiProvider = Provider<SessionApi>(
  (ref) => HttpSessionApi(ref.watch(publicDioProvider)),
);
