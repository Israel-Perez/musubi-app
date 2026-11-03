import 'package:dio/dio.dart';

/// Respuesta guardada con su `ETag`.
typedef EtagEntry = ({String etag, Object? data});

/// Copias de las respuestas `GET` con `ETag` (02-06), en memoria y con un tope:
/// al llenarse sale la menos usada. La llave lleva quien tiene la sesion, asi
/// una cuenta nunca recibe la copia de otra.
class EtagCache {
  new({this.capacity = 64});

  final int capacity;
  final _entries = <String, EtagEntry>{};

  int get length => _entries.length;

  EtagEntry? read(String key) {
    final entry = _entries.remove(key);
    if (entry != null) _entries[key] = entry;
    return entry;
  }

  void write(String key, EtagEntry entry) {
    _entries
      ..remove(key)
      ..[key] = entry;
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }

  void clear() => _entries.clear();
}

/// Tercer nivel de la cache (02-06; musubi-api `02-02`): en cada `GET` manda el
/// `If-None-Match` de la copia guardada. Si la API responde `304`, entrega la
/// copia como un `200` y la lista no se vuelve a bajar. Sin `ETag` no guarda
/// nada.
class EtagCacheInterceptor extends Interceptor {
  new(this._cache, {required this._identity});

  final EtagCache _cache;
  final String Function() _identity;

  static const _keyExtra = 'etagCacheKey';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method == 'GET') {
      final key = '${_identity()}|${options.uri}';
      options.extra[_keyExtra] = key;
      final cached = _cache.read(key);
      if (cached != null) {
        options.headers['If-None-Match'] = cached.etag;
        final accepts = options.validateStatus;
        options.validateStatus = (status) => status == 304 || accepts(status);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = response.requestOptions.extra[_keyExtra];
    if (key is! String) {
      handler.next(response);
      return;
    }
    if (response.statusCode == 304) {
      final cached = _cache.read(key);
      if (cached != null) {
        handler.resolve(
          Response<dynamic>(
            requestOptions: response.requestOptions,
            data: cached.data,
            statusCode: 200,
            headers: response.headers,
            extra: {...response.extra, 'fromCache': true},
          ),
        );
        return;
      }
    }
    final etag = response.headers.value('etag');
    if (response.statusCode == 200 && etag != null) {
      _cache.write(key, (etag: etag, data: response.data));
    }
    handler.next(response);
  }
}
