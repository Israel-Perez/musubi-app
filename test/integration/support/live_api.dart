import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:musubi_app/core/config/app_config.dart';
import 'package:musubi_app/core/network/api_client.dart';
import 'package:musubi_app/core/session/session_controller.dart';
import 'package:musubi_app/features/auth/domain/auth_models.dart';
import 'package:musubi_app/features/auth/presentation/auth_providers.dart';

import '../../helpers/in_memory_token_store.dart';

/// Pruebas de integracion contra una musubi-api real (02-10, SCRUM-120).
///
/// Corren con los proveedores reales de la app (repositorios HTTP, Dio,
/// `AuthInterceptor` y sesion) contra la API en Development (en memoria):
/// `pwsh scripts/run_integration_tests.ps1` la levanta y pasa estas variables.
/// Sin `MUSUBI_API_URL` se saltan, asi `flutter test` sigue sin depender de
/// la API.
const liveApiUrl = String.fromEnvironment('MUSUBI_API_URL');

/// Log de la API (modo `Email:Provider=Log`): de ahi salen los codigos.
const liveApiLog = String.fromEnvironment('MUSUBI_API_LOG');

/// Carpeta donde se anota cada `VERBO /ruta` llamada, un archivo por proceso
/// (lo revisa `tool/check_integration_coverage.dart`). Cada archivo de prueba
/// corre en su propio proceso y escribir todos en uno solo pierde lineas.
const liveApiCoverage = String.fromEnvironment('MUSUBI_API_COVERAGE');

/// Correo con el rol `admin` (la API arranca con `Admin__Emails__0`).
const liveAdminEmail = 'admin.integracion@uttt.edu.mx';

/// Contrasena de todas las cuentas de prueba (nunca una real).
const livePassword = 'musubi2026';

/// Nombre de las cuentas: la CLABE de pagos pide que coincida.
const liveName = 'Ana Sofía Integración';

/// Motivo para `skip:` cuando no hay API.
final Object? liveSkip = liveApiUrl.isEmpty
    ? 'Requiere musubi-api local (ver test/integration/README.md)'
    : null;

final _random = Random.secure();

/// Correo institucional unico por prueba.
String liveEmail([String prefix = 'it']) =>
    '$prefix.${DateTime.now().microsecondsSinceEpoch}'
    '${_random.nextInt(1 << 20)}@uttt.edu.mx';

/// Anota una llamada para el guard de cobertura (02-10).
void recordCoverage(String method, String path) {
  if (liveApiCoverage.isEmpty) return;
  _coverageFile
    ..createSync(recursive: true)
    ..writeAsStringSync(
      '${method.toUpperCase()} $path\n',
      mode: FileMode.append,
      flush: true,
    );
}

final File _coverageFile = File(
  '$liveApiCoverage/$pid-${_random.nextInt(1 << 30)}.txt',
);

class _CoverageRecorder extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    recordCoverage(options.method, options.uri.path);
    handler.next(options);
  }
}

/// Una persona (o un visitante) usando la app contra la API real.
class LiveSession {
  new _(this.container, this.store);

  /// Visitante: sin cuenta.
  factory visitor() => LiveSession._create();

  factory _create() {
    final store = InMemoryTokenStore();
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          AppConfig.parse(environment: 'dev', apiBaseUrl: liveApiUrl),
        ),
        tokenStoreProvider.overrideWithValue(store),
      ],
    );
    for (final dio in [
      container.read(dioProvider),
      container.read(publicDioProvider),
    ]) {
      dio.interceptors.insert(0, _CoverageRecorder());
    }
    return LiveSession._(container, store);
  }

  final ProviderContainer container;

  /// El almacen seguro de este "telefono".
  final InMemoryTokenStore store;

  late String email;
  late AuthUser user;

  /// Lee un proveedor de la app.
  T read<T>(ProviderListenable<T> provider) => container.read(provider);

  /// Tokens de la sesion actual (falla si es visitante).
  SignedIn get signedIn => read(sessionControllerProvider) as SignedIn;

  void dispose() => container.dispose();
}

/// Cuenta nueva y verificada, con la sesion iniciada en la app.
Future<LiveSession> liveUser({String? email, String name = liveName}) async {
  final session = LiveSession._create();
  final address = email ?? liveEmail();
  final auth = session.read(authRepositoryProvider);
  await auth.register(
    email: address,
    fullName: name,
    password: livePassword,
    acceptTerms: true,
    acceptPrivacy: true,
  );
  final signedIn = await auth.confirmCode(
    email: address,
    code: await liveCodeFor(address),
  );
  await session
      .read(sessionControllerProvider.notifier)
      .signIn(signedIn.tokens);
  return session
    ..email = address
    ..user = signedIn.user;
}

/// El administrador del campus (lo crea la primera vez; despues inicia
/// sesion).
Future<LiveSession> liveAdmin() async {
  final session = LiveSession._create();
  final auth = session.read(authRepositoryProvider);
  SignedInSession signedIn;
  try {
    await auth.register(
      email: liveAdminEmail,
      fullName: 'Equipo Musubi',
      password: livePassword,
      acceptTerms: true,
      acceptPrivacy: true,
    );
    signedIn = await auth.confirmCode(
      email: liveAdminEmail,
      code: await liveCodeFor(liveAdminEmail),
    );
  } on Exception {
    // Ya existia (otra corrida contra la misma API): solo inicia sesion.
    signedIn = await auth.signIn(email: liveAdminEmail, password: livePassword);
  }
  // El rol se da al iniciar sesion (Admin:Emails): una sesion nueva lo trae.
  signedIn = await auth.signIn(email: liveAdminEmail, password: livePassword);
  await session
      .read(sessionControllerProvider.notifier)
      .signIn(signedIn.tokens);
  return session
    ..email = liveAdminEmail
    ..user = signedIn.user;
}

/// El ultimo codigo de 6 digitos que la API "envio" a [email] (lo escribe en
/// su log en Development).
Future<String> liveCodeFor(String email, {String? after}) async {
  final marker = 'para ${email.toLowerCase()}';
  for (var i = 0; i < 40; i++) {
    final log = File(liveApiLog);
    if (log.existsSync()) {
      // En Windows la consola no escribe UTF-8: los acentos no importan aqui.
      final text = utf8.decode(log.readAsBytesSync(), allowMalformed: true);
      final at = text.lastIndexOf(marker);
      if (at >= 0) {
        final tail = text.substring(at, min(text.length, at + 2000));
        final code = RegExp(r'(?<!\d)\d{6}(?!\d)').firstMatch(tail)?.group(0);
        if (code != null && code != after) return code;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  throw StateError('La API no escribio el codigo de $email en $liveApiLog');
}

/// Una foto PNG valida (400 x 300, un color) en un archivo temporal.
File livePhoto({int red = 0, int green = 128, int blue = 128}) {
  const width = 400;
  const height = 300;
  final raw = BytesBuilder();
  final row = List<int>.filled(width * 3, 0);
  for (var x = 0; x < width; x++) {
    row
      ..[x * 3] = red
      ..[x * 3 + 1] = green
      ..[x * 3 + 2] = blue;
  }
  for (var y = 0; y < height; y++) {
    raw
      ..addByte(0)
      ..add(row);
  }
  List<int> chunk(String type, List<int> data) {
    final typed = [...type.codeUnits, ...data];
    final length = ByteData(4)..setUint32(0, data.length);
    final crc = ByteData(4)..setUint32(0, _crc32(typed));
    return [
      ...length.buffer.asUint8List(),
      ...typed,
      ...crc.buffer.asUint8List(),
    ];
  }

  final header = ByteData(13)
    ..setUint32(0, width)
    ..setUint32(4, height)
    ..setUint8(8, 8)
    ..setUint8(9, 2);
  final png = [
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, //
    ...chunk('IHDR', header.buffer.asUint8List()),
    ...chunk('IDAT', ZLibCodec().encode(raw.takeBytes())),
    ...chunk('IEND', const []),
  ];
  final file = File(
    '${Directory.systemTemp.path}/musubi-it-${_random.nextInt(1 << 30)}.png',
  )..writeAsBytesSync(png);
  return file;
}

int _crc32(List<int> bytes) {
  var crc = 0xFFFFFFFF;
  for (final byte in bytes) {
    crc ^= byte;
    for (var k = 0; k < 8; k++) {
      crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
    }
  }
  return crc ^ 0xFFFFFFFF;
}
