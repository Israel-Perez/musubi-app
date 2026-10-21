import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:musubi_app/core/errors/network_error_message.dart';

/// Error de la API o de la red, listo para mostrarse (RNF-18).
///
/// La API responde `application/problem+json` con `code` estable y `title` en
/// espanol (catalogo canonico: musubi-api `docs/errores.md`, spec 02-03). La
/// app decide por [code], nunca por el texto.
@immutable
class ApiFailure implements Exception {
  const new({
    required this.code,
    required this.message,
    this.status,
    this.fieldErrors = const {},
  });

  /// Traduce cualquier [DioException]: problem+json de la API o error de red.
  factory fromDio(DioException error) {
    final response = error.response;
    final data = response?.data;
    if (data is Map && data['code'] is String) {
      final title = data['title'];
      return ApiFailure(
        code: data['code'] as String,
        message: title is String && title.isNotEmpty
            ? title
            : 'No se pudo completar la operación.',
        status: response?.statusCode,
        fieldErrors: _fieldErrors(data['errors']),
      );
    }

    return ApiFailure(
      code: switch (error.type) {
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout ||
        DioExceptionType.transformTimeout => networkTimeout,
        DioExceptionType.connectionError => networkOffline,
        DioExceptionType.badCertificate => networkInsecure,
        DioExceptionType.cancel => networkCancelled,
        DioExceptionType.badResponse =>
          (response?.statusCode ?? 500) >= 500 ? serverError : requestRejected,
        DioExceptionType.unknown => networkUnknown,
      },
      message: networkErrorMessage(error),
      status: response?.statusCode,
    );
  }

  // Codigos propios de la app (la API nunca los envia).
  static const networkTimeout = 'network.timeout';
  static const networkOffline = 'network.offline';
  static const networkInsecure = 'network.insecure';
  static const networkCancelled = 'network.cancelled';
  static const networkUnknown = 'network.unknown';
  static const requestRejected = 'request.rejected';

  // Codigos de la API que la app trata de forma especial.
  static const serverError = 'server.error';
  static const unauthorized = 'auth.unauthorized';
  static const sessionExpired = 'auth.session_expired';
  static const validationFailed = 'validation.failed';

  final String code;
  final String message;
  final int? status;

  /// Errores por campo de un 400 de validacion, con la clave en minusculas
  /// (`email`, `password`) para ubicarlos junto a su campo.
  final Map<String, List<String>> fieldErrors;

  /// Primer error de un campo, o `null`.
  String? fieldError(String field) =>
      fieldErrors[field.toLowerCase()]?.firstOrNull;

  /// Sin red o sin respuesta: la UI ofrece reintentar.
  bool get isNetwork => code.startsWith('network.');

  static Map<String, List<String>> _fieldErrors(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.value is List)
          entry.key.toString().toLowerCase(): [
            for (final message in entry.value as List) message.toString(),
          ],
    };
  }

  @override
  String toString() => 'ApiFailure($code, $status)';
}
