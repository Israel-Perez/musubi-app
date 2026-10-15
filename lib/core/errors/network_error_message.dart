import 'package:dio/dio.dart';

/// Traduce un error de red a un mensaje claro en espanol para el usuario
/// (RNF-18). No expone detalles tecnicos ni datos del servidor.
String networkErrorMessage(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return 'El servidor tardó demasiado en responder.';
    case DioExceptionType.connectionError:
      return 'No hay conexión con el servidor.';
    case DioExceptionType.badCertificate:
      return 'La conexión con el servidor no es segura.';
    case DioExceptionType.badResponse:
      final code = error.response?.statusCode;
      return code != null && code >= 500
          ? 'El servidor tuvo un problema. Intenta más tarde.'
          : 'El servidor rechazó la solicitud.';
    case DioExceptionType.cancel:
      return 'La solicitud se canceló.';
    case DioExceptionType.unknown:
      return 'No se pudo contactar al servidor.';
  }
}
