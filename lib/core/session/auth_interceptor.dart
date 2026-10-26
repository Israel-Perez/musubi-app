import 'package:dio/dio.dart';
import 'package:musubi_app/core/session/session_tokens.dart';

/// Renueva la sesion con el refresh token. Devuelve `null` si la API la
/// rechaza (`auth.session_expired`): la sesion termino.
typedef SessionRefresher = Future<SessionTokens?> Function(String refreshToken);

/// Agrega el access token SOLO a peticiones hacia musubi-api y, ante un 401,
/// renueva la sesion una sola vez aunque fallen varias peticiones a la vez
/// (spec 02-01; contrato en musubi-api:02-03).
class AuthInterceptor extends QueuedInterceptor {
  new({
    required this.apiBaseUrl,
    required this.readTokens,
    required this.onRefreshed,
    required this.onSessionEnded,
    required this.refresher,
    required this.retry,
  });

  /// Marca de una peticion ya reintentada (evita bucles).
  static const retriedKey = 'musubi.retried';

  final Uri apiBaseUrl;
  final SessionTokens? Function() readTokens;
  final Future<void> Function(SessionTokens tokens) onRefreshed;
  final Future<void> Function() onSessionEnded;
  final SessionRefresher refresher;

  /// Reenvia la peticion con el token nuevo. DEBE usar un cliente SIN este
  /// interceptor: en un QueuedInterceptor, reintentar con el mismo cliente
  /// deja el error del reintento esperando en la fila que este manejador
  /// bloquea (deadlock).
  final Future<Response<dynamic>> Function(RequestOptions options) retry;

  /// MASVS-NETWORK: el token nunca viaja a otro esquema, host o puerto.
  bool isApiRequest(Uri uri) =>
      uri.scheme == apiBaseUrl.scheme &&
      uri.host == apiBaseUrl.host &&
      uri.port == apiBaseUrl.port;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final tokens = readTokens();
    if (tokens != null && isApiRequest(options.uri)) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    } else {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  // QueuedInterceptor atiende los errores en fila: si varias peticiones
  // reciben 401 a la vez, solo la primera renueva; las demas ven que su token
  // ya cambio y se reintentan con el nuevo.
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final sent = request.headers['Authorization'];
    final tokens = readTokens();
    final canRecover =
        err.response?.statusCode == 401 &&
        tokens != null &&
        sent != null &&
        isApiRequest(request.uri) &&
        request.extra[retriedKey] != true;
    if (!canRecover) {
      handler.next(err);
      return;
    }

    final current = sent == 'Bearer ${tokens.accessToken}'
        ? await _refresh(tokens.refreshToken)
        : tokens;
    if (current == null) {
      handler.next(err);
      return;
    }

    request
      ..headers['Authorization'] = 'Bearer ${current.accessToken}'
      ..extra[retriedKey] = true;
    try {
      handler.resolve(await retry(request));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<SessionTokens?> _refresh(String refreshToken) async {
    final SessionTokens? renewed;
    try {
      renewed = await refresher(refreshToken);
    } on DioException {
      // Sin red al renovar: se conserva la sesion y la peticion falla normal.
      return null;
    }
    if (renewed == null) {
      await onSessionEnded();
      return null;
    }
    await onRefreshed(renewed);
    return renewed;
  }
}
