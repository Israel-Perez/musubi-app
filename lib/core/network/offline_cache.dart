import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:musubi_app/core/storage/local_store.dart';

/// Lo que se guarda para abrir sin conexion (HU-63, L-16h y L-09).
///
/// Solo los `GET` que lo piden con [OfflineCache.options]: la primera pagina
/// de la vitrina de `Inicio`, la bandeja de `Mensajes`, "Mis pedidos" y "Mis
/// productos".
abstract final class OfflineCache {
  /// La marca en `RequestOptions.extra`.
  static const extraKey = 'offlineCache';

  /// `Options` de un `GET` que se guarda.
  static final options = Options(extra: const {extraKey: true});

  /// La respuesta salio de lo guardado (no de la red).
  static const fromCacheKey = 'fromOfflineCache';

  /// Una copia recien revalidada se entrega sin volver a pedirla.
  static const freshFor = Duration(seconds: 30);

  /// Lo que nunca se escribe en el telefono, aunque venga en la respuesta: el
  /// codigo de entrega del efectivo y la referencia de la transferencia (HU-55)
  /// y cualquier token.
  static const sensitiveKeys = {
    'deliveryCode',
    'reference',
    'accessToken',
    'refreshToken',
    'clabe',
  };

  /// La respuesta sin [sensitiveKeys], en cualquier nivel.
  static Object? sanitize(Object? data) => switch (data) {
    final Map<String, dynamic> map => {
      for (final entry in map.entries)
        if (!sensitiveKeys.contains(entry.key))
          entry.key: sanitize(entry.value),
    },
    final List<dynamic> list => [for (final item in list) sanitize(item)],
    _ => data,
  };
}

/// Una copia guardada se actualizo con la red: la pantalla de [path] la vuelve
/// a leer. [n] hace distinto cada aviso.
@immutable
class OfflineRefresh {
  const new(this.path, this.n);

  final String path;
  final int n;
}

/// Los avisos de copias actualizadas (uno por respuesta revalidada).
class OfflineRefreshes {
  final _controller = StreamController<OfflineRefresh>.broadcast();
  var _n = 0;

  Stream<OfflineRefresh> get stream => _controller.stream;

  void add(String path) => _controller.add(OfflineRefresh(path, ++_n));

  Future<void> close() => _controller.close();
}

final offlineRefreshesProvider = Provider<OfflineRefreshes>((ref) {
  final refreshes = OfflineRefreshes();
  ref.onDispose(refreshes.close);
  return refreshes;
});

/// La ultima copia actualizada; los providers de las 4 pantallas la escuchan y
/// se vuelven a construir si es su ruta.
final StreamProvider<OfflineRefresh> offlineRefreshedProvider =
    StreamProvider<OfflineRefresh>(
      (ref) => ref.watch(offlineRefreshesProvider).stream,
    );

/// Vuelve a construir el provider de [ref] cuando se actualiza la copia de
/// alguna de [paths] (stale-while-revalidate de HU-63).
void refreshWithOfflineCopies(Ref ref, Set<String> paths) {
  ref.listen(offlineRefreshedProvider, (_, next) {
    if (paths.contains(next.value?.path)) ref.invalidateSelf();
  });
}

/// Si la ultima peticion no llego a la API ("Sin conexión · lo que ves puede
/// no estar al día"). Cualquier respuesta lo apaga.
class OfflineNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  // Un setter no encaja: lo llama el interceptor como callback.
  // ignore: use_setters_to_change_properties
  void set({required bool offline}) => state = offline;
}

final offlineProvider = NotifierProvider<OfflineNotifier, bool>(
  OfflineNotifier.new,
);

/// Errores que significan "no hay red" (no los que responde la API).
bool isOfflineError(DioException error) => switch (error.type) {
  DioExceptionType.connectionError ||
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.unknown => true,
  _ => false,
};

/// Stale-while-revalidate en SQLite (HU-63). Va antes que el ETag y la sesion.
///
/// 1. Al abrir una pantalla por primera vez en la sesion, si hay copia, la
///    entrega al instante y la pide a la red en segundo plano; al llegar, la
///    guarda y avisa con [OfflineRefreshes] para que la pantalla la vuelva a
///    leer (en los siguientes [OfflineCache.freshFor] se entrega sin pedirla).
/// 2. Despues, la red primero; si no hay red, la copia y [OfflineNotifier]
///    se enciende.
/// La llave lleva quien tiene la sesion: una cuenta nunca ve la copia de otra.
class OfflineCacheInterceptor extends Interceptor {
  new(
    this._store, {
    required this._identity,
    required this._onOffline,
    required this._onRefreshed,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final LocalStore _store;
  final String Function() _identity;
  final void Function({required bool offline}) _onOffline;
  final void Function(String path) _onRefreshed;
  final DateTime Function() _clock;

  /// Para pedir en segundo plano (el `fetch` del mismo Dio).
  late Future<Response<dynamic>> Function(RequestOptions) fetch;

  static const _keyExtra = 'offlineCacheKey';
  static const _refreshExtra = 'offlineCacheRefresh';

  final _revalidatedAt = <String, DateTime>{};
  final _inFlight = <String>{};

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.method != 'GET' ||
        options.extra[OfflineCache.extraKey] != true) {
      handler.next(options);
      return;
    }
    // Ruta y consulta (sin el host: la API de la app no cambia).
    final uri = options.uri;
    final query = uri.query.isEmpty ? '' : '?${uri.query}';
    final key = '${_identity()}|${uri.path}$query';
    options.extra[_keyExtra] = key;
    if (options.extra[_refreshExtra] == true) {
      handler.next(options);
      return;
    }
    final at = _revalidatedAt[key];
    final fresh = at != null && _clock().difference(at) < OfflineCache.freshFor;
    if (at == null || fresh) {
      final cached = await _store.read(key);
      if (cached != null) {
        handler.resolve(_cached(options, cached));
        if (at == null) unawaited(_revalidate(options, key));
        return;
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) async {
    _onOffline(offline: false);
    final key = response.requestOptions.extra[_keyExtra];
    if (key is String) {
      if (response.statusCode == 200) {
        await _store.write(
          key,
          jsonEncode(OfflineCache.sanitize(response.data)),
        );
      }
      if (response.statusCode == 200 || response.statusCode == 304) {
        _revalidatedAt[key] = _clock();
      }
    }
    handler.next(response);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!isOfflineError(err)) {
      handler.next(err);
      return;
    }
    _onOffline(offline: true);
    final options = err.requestOptions;
    final key = options.extra[_keyExtra];
    if (key is String && options.extra[_refreshExtra] != true) {
      final cached = await _store.read(key);
      if (cached != null) {
        handler.resolve(_cached(options, cached));
        return;
      }
    }
    handler.next(err);
  }

  Future<void> _revalidate(RequestOptions options, String key) async {
    if (!_inFlight.add(key)) return;
    try {
      await fetch(
        options.copyWith(extra: {...options.extra, _refreshExtra: true}),
      );
      _onRefreshed(options.path);
    } on DioException {
      // Sin red se queda la copia; onError ya encendio "Sin conexión".
      return;
    } finally {
      _inFlight.remove(key);
    }
  }

  static Response<dynamic> _cached(RequestOptions options, String body) =>
      Response<dynamic>(
        requestOptions: options,
        data: jsonDecode(body),
        statusCode: 200,
        extra: const {OfflineCache.fromCacheKey: true},
      );
}
