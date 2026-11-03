import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musubi_app/core/network/etag_cache.dart';

import '../../helpers/fake_http_adapter.dart';

// 02-06: tercer nivel de la cache. La app reenvia el ETag guardado y, con un
// 304 de la API, reutiliza su copia sin volver a bajar la lista.
void main() {
  late FakeHttpAdapter adapter;
  late Dio dio;
  late EtagCache cache;
  var who = 'ana@uttt.edu.mx';

  /// La API: con el If-None-Match vigente responde 304; si no, la lista.
  ResponseBody api(RequestOptions options, {String etag = '"v1"'}) {
    if (options.headers['If-None-Match'] == etag) {
      return ResponseBody.fromString(
        '',
        304,
        headers: {
          'etag': [etag],
        },
      );
    }
    return ResponseBody.fromString(
      '[{"slug":"libros","name":"Libros"}]',
      200,
      headers: {
        'etag': [etag],
        'content-type': ['application/json'],
      },
    );
  }

  setUp(() {
    who = 'ana@uttt.edu.mx';
    cache = EtagCache();
    adapter = FakeHttpAdapter((options) async => api(options));
    dio = Dio(BaseOptions(baseUrl: 'https://api.musubi.example'))
      ..httpClientAdapter = adapter
      ..interceptors.add(EtagCacheInterceptor(cache, identity: () => who));
  });

  test('la segunda lectura manda el ETag y el 304 entrega la copia', () async {
    final first = await dio.get<List<dynamic>>('/api/v1/categories');
    final second = await dio.get<List<dynamic>>('/api/v1/categories');

    expect(adapter.requests.first.headers['If-None-Match'], isNull);
    expect(adapter.requests.last.headers['If-None-Match'], '"v1"');
    expect(second.statusCode, 200);
    expect(second.extra['fromCache'], isTrue);
    expect(second.data, first.data);
  });

  test('si cambio en la API, llega la lista nueva y se guarda', () async {
    await dio.get<List<dynamic>>('/api/v1/categories');
    adapter = FakeHttpAdapter((options) async => api(options, etag: '"v2"'));
    dio.httpClientAdapter = adapter;

    final changed = await dio.get<List<dynamic>>('/api/v1/categories');
    final again = await dio.get<List<dynamic>>('/api/v1/categories');

    expect(changed.extra['fromCache'], isNull);
    expect(again.extra['fromCache'], isTrue);
    expect(adapter.requests.last.headers['If-None-Match'], '"v2"');
  });

  test('otra cuenta nunca recibe la copia de la anterior', () async {
    await dio.get<List<dynamic>>('/api/v1/careers');
    who = 'luis@uttt.edu.mx';

    final other = await dio.get<List<dynamic>>('/api/v1/careers');

    expect(adapter.requests.last.headers['If-None-Match'], isNull);
    expect(other.extra['fromCache'], isNull);
  });

  test(
    'solo GET con ETag: un POST o una respuesta sin ETag no se guardan',
    () async {
      adapter = FakeHttpAdapter(
        (_) async => FakeHttpAdapter.json({'ok': true}),
      );
      dio.httpClientAdapter = adapter;

      await dio.post<Map<String, dynamic>>('/api/v1/products', data: {});
      await dio.get<Map<String, dynamic>>('/api/v1/profiles/me');

      expect(cache.length, 0);
    },
  );

  test('con el tope lleno sale la copia menos usada', () {
    final small = EtagCache(capacity: 2)
      ..write('a', (etag: '"a"', data: 1))
      ..write('b', (etag: '"b"', data: 2))
      ..read('a')
      ..write('c', (etag: '"c"', data: 3));

    expect(small.read('b'), isNull);
    expect(small.read('a')?.data, 1);
    expect(small.length, 2);
  });
}
