import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Los fallos de la app en Firebase Crashlytics (SCRUM-108, 02-01), detras de
/// una interfaz: en debug y en las pruebas no sale nada, y en release solo si
/// hay `google-services.json` (RNF-15). Nunca se manda quien es la persona: ni
/// su id, ni su correo, ni su nombre, ni tokens, ni textos del chat
/// (MASVS-PRIVACY); cada error pasa por [CrashScrubber] antes de salir.
abstract interface class CrashReporter {
  /// Si los errores se estan mandando (release con Firebase).
  bool get active;

  /// Lo enciende si se puede; si no, se queda apagado sin avisar.
  Future<void> start();

  /// Manda un error, ya sin datos personales.
  Future<void> record(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  });
}

/// Apagado: debug, pruebas o un build sin Firebase.
class NoCrashReporter implements CrashReporter {
  const new();

  @override
  bool get active => false;

  @override
  Future<void> start() async {}

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async {}
}

/// Firebase Crashlytics. La coleccion arranca apagada
/// (`firebase_crashlytics_collection_enabled=false` en el manifiesto) y solo
/// se enciende aqui, en release.
class FirebaseCrashReporter implements CrashReporter {
  new({this.release = kReleaseMode});

  /// Si es un build de release (en debug nunca se enciende).
  final bool release;

  bool _ready = false;

  @override
  bool get active => _ready;

  @override
  Future<void> start() async {
    if (_ready || !release) return;
    try {
      await Firebase.initializeApp();
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
      _ready = true;
    } on Object catch (error) {
      // Sin google-services.json: la app sigue sin reportar fallos.
      debugPrint('Crashlytics apagado: ${error.runtimeType}');
    }
  }

  @override
  Future<void> record(
    Object error,
    StackTrace? stack, {
    required bool fatal,
    String? reason,
  }) async {
    if (!_ready) return;
    await FirebaseCrashlytics.instance.recordError(
      CrashScrubber.error(error),
      stack,
      reason: reason == null ? null : CrashScrubber.text(reason),
      fatal: fatal,
      printDetails: false,
    );
  }
}

/// Un error ya limpio: el tipo original y el mensaje sin datos personales.
@immutable
class ScrubbedError implements Exception {
  const new(this.type, this.message);

  final String type;
  final String message;

  @override
  String toString() => '$type: $message';
}

/// Quita del texto de un error lo que puede identificar a alguien.
abstract final class CrashScrubber {
  /// Largo maximo del mensaje.
  static const maxLength = 400;

  static final _email = RegExp(r'[\w.+-]+@[\w-]+(\.[\w-]+)+');
  static final _bearer = RegExp(r'Bearer\s+\S+', caseSensitive: false);
  static final _jwt = RegExp(r'\b[\w-]{10,}\.[\w-]{10,}\.[\w-]{10,}\b');
  static final _query = RegExp(r'\?[^\s#]*');
  static final _longNumber = RegExp(r'\d{7,}');
  static final _quoted = RegExp('"[^"]*"|«[^»]*»');

  /// El texto sin correos, tokens, consultas de URL, numeros largos
  /// (telefonos, cuentas) ni textos entre comillas (lo que escribio alguien).
  static String text(String value) {
    final clean = value
        .replaceAll(_bearer, 'Bearer [token]')
        .replaceAll(_jwt, '[token]')
        .replaceAll(_email, '[correo]')
        .replaceAll(_query, '?[consulta]')
        .replaceAll(_longNumber, '[numero]')
        .replaceAll(_quoted, '"[texto]"');
    return clean.length > maxLength ? clean.substring(0, maxLength) : clean;
  }

  /// El error como [ScrubbedError] (el tipo se conserva para agruparlo).
  static ScrubbedError error(Object error) => error is ScrubbedError
      ? ScrubbedError(error.type, text(error.message))
      : ScrubbedError(error.runtimeType.toString(), text(error.toString()));

  /// La ruta de una peticion sin ids ni consulta: `/api/v1/products/:id`.
  static String path(String value) => value
      .split('?')
      .first
      .split('/')
      .map(
        (part) =>
            RegExp(r'^[0-9a-f]{24}$|^\d+$|^[0-9a-f-]{32,36}$').hasMatch(part)
            ? ':id'
            : part,
      )
      .join('/');
}

/// Los errores de la API que no se esperan (5xx o una falla desconocida) se
/// mandan como no fatales: el metodo, la ruta sin ids y el estado. Nunca el
/// cuerpo, la consulta ni los encabezados. Sin red, un timeout o un 4xx son
/// normales y no se mandan.
class CrashReportingInterceptor extends Interceptor {
  new(this.reporter);

  final CrashReporter reporter;

  /// Si el error vale la pena reportarlo.
  static bool unexpected(DioException error) =>
      error.type == DioExceptionType.unknown ||
      error.type == DioExceptionType.badCertificate ||
      (error.response?.statusCode ?? 0) >= 500;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (reporter.active && unexpected(err)) {
      final status = err.response?.statusCode;
      final data = err.response?.data;
      final code = data is Map && data['code'] is String ? data['code'] : null;
      unawaited(
        reporter.record(
          ScrubbedError(
            'ApiError',
            '${err.requestOptions.method} '
                '${CrashScrubber.path(err.requestOptions.path)} → '
                '${status ?? err.type.name}${code == null ? '' : ' $code'}',
          ),
          err.stackTrace,
          fatal: false,
        ),
      );
    }
    handler.next(err);
  }
}

/// El reportero de la app. `main` lo cambia por [FirebaseCrashReporter]; en
/// las pruebas queda apagado.
final crashReporterProvider = Provider<CrashReporter>(
  (ref) => const NoCrashReporter(),
);
