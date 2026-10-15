import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/config/app_config.dart';

/// Timeouts del cliente HTTP. NOTE (02-01): ajustar con mediciones reales
/// contra la API desplegada (principio 6, empirico antes que teorico).
const apiConnectTimeout = Duration(seconds: 5);
const apiReceiveTimeout = Duration(seconds: 10);

/// Crea el cliente HTTP de musubi-api.
///
/// NOTE (HU-02): interceptor que agrega el token (guardado con
/// flutter_secure_storage) y renueva la sesion.
Dio createApiClient(AppConfig config) => Dio(
  BaseOptions(
    baseUrl: config.apiBaseUrl.toString(),
    connectTimeout: apiConnectTimeout,
    receiveTimeout: apiReceiveTimeout,
    headers: const {'Accept': 'application/json'},
  ),
);

final dioProvider = Provider<Dio>((ref) {
  final dio = createApiClient(ref.watch(appConfigProvider));
  ref.onDispose(dio.close);
  return dio;
});
