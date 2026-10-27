import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adaptador HTTP falso para Dio: registra las peticiones y responde con el
/// [handler] sin tocar la red.
class FakeHttpAdapter implements HttpClientAdapter {
  new(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;
  final List<RequestOptions> requests = [];

  /// Respuesta JSON con el [status] HTTP indicado.
  static ResponseBody json(Object body, {int status = 200}) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    // Como la red: se consume el cuerpo (y se cierra el archivo de un
    // multipart).
    await requestStream?.drain<void>();
    return await handler(options);
  }

  @override
  void close({bool force = false}) {}
}
