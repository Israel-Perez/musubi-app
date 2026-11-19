// Servidor de codigos para las pruebas en el telefono (02-10, SCRUM-120).
//
// Uso: dart tool/device_code_server.dart <musubi-api.log> <puerto>
//
// En Development la API escribe los correos en su log. El telefono no puede
// leer ese archivo, asi que `scripts/run_device_tests.ps1` levanta este
// servidor en la PC y lo expone con `adb reverse`:
// `GET /code?email=<correo>` responde el ultimo codigo de 6 digitos que la API
// "envio" a ese correo (404 si todavia no hay). Solo escucha en loopback.
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('uso: dart tool/device_code_server.dart <log> <puerto>');
    exit(2);
  }
  final log = File(args[0]);
  final server = await HttpServer.bind(
    InternetAddress.loopbackIPv4,
    int.parse(args[1]),
  );
  stdout.writeln('codigos en http://localhost:${server.port}/code?email=');
  await for (final request in server) {
    final email = request.uri.queryParameters['email']?.toLowerCase();
    final code = email == null || request.uri.path != '/code'
        ? null
        : _lastCode(log, email);
    request.response
      ..statusCode = code == null ? HttpStatus.notFound : HttpStatus.ok
      ..headers.contentType = ContentType.text
      ..write(code ?? '');
    await request.response.close();
  }
}

String? _lastCode(File log, String email) {
  if (!log.existsSync()) return null;
  // En Windows la consola no escribe UTF-8: los acentos no importan aqui.
  final text = utf8.decode(log.readAsBytesSync(), allowMalformed: true);
  final at = text.lastIndexOf('para $email');
  if (at < 0) return null;
  final end = at + 2000 < text.length ? at + 2000 : text.length;
  return RegExp(r'(?<!\d)\d{6}(?!\d)')
      .firstMatch(text.substring(at, end))
      ?.group(0);
}
